#!/usr/bin/env python3
"""用 Chrome DevTools Protocol 渲染 SPA / 反爬站点，抓正文存成 Markdown。

处理 fetch-answers.py 跳过的域名（掘金、简书、知乎、CSDN），
以及 curl 抓失败需要真实渲染的条目。

    /tmp/fetchenv/bin/python tools/render-answers.py --domain juejin.cn
    /tmp/fetchenv/bin/python tools/render-answers.py --retry-failed
"""
import argparse
import json
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

import websocket

sys.path.insert(0, str(Path(__file__).resolve().parent))
from importlib import import_module

fa = import_module("fetch-answers".replace("-", "_")) if False else None

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "answers"
ITEMS = Path("/tmp/deepdive-items.json")
STATE = Path("/tmp/fetch-state.json")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT = 9333
PROFILE = "/tmp/cdp-profile"

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

# 各站正文选择器（按顺序尝试）
SELECTORS = {
    "juejin.cn": [".markdown-body", "#article-root", "article"],
    "www.jianshu.com": ["article", ".show-content", "._2rhmJa"],
    "zhuanlan.zhihu.com": [".Post-RichText", ".RichText", "article"],
    "blog.csdn.net": ["#content_views", ".blog-content-box", "article"],
    "es6.ruanyifeng.com": [".book-body .page-inner section", ".markdown-section", "section"],
    "zustand.docs.pmnd.rs": ["article", "main"],
    "w3help.org": ["#content", ".content", "article", "body"],
    "jakearchibald.com": ["article", "main", ".post"],
    "www.zhangxinxu.com": [".entry-content", "article"],
    "mp.weixin.qq.com": ["#js_content"],
    "segmentfault.com": ["article", ".article__content"],
    "www.ruanyifeng.com": ["#main-content", ".entry-content", "article"],
    "www.helloweba.net": [".article-content", "article", "#content"],
    "_default": ["article", "main", ".content", "#content", "body"],
}


class Chrome:
    def __init__(self):
        self.proc = None

    def __enter__(self):
        subprocess.run(["pkill", "-f", f"remote-debugging-port={PORT}"],
                       capture_output=True)
        time.sleep(1)
        self.proc = subprocess.Popen(
            [CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
             "--disable-dev-shm-usage", "--mute-audio",
             "--blink-settings=imagesEnabled=false",
             f"--remote-debugging-port={PORT}", f"--user-data-dir={PROFILE}",
             f"--user-agent={UA}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(40):
            time.sleep(0.5)
            try:
                urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json/version", timeout=2)
                return self
            except Exception:
                continue
        raise RuntimeError("Chrome 未能启动")

    def __exit__(self, *a):
        if self.proc:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=10)
            except Exception:
                self.proc.kill()

    def render(self, url, selectors, settle=2.5, timeout=45):
        """打开 url，等正文出现，返回 (html, title, final_url)。"""
        # Chrome 111+ 要求 /json/new 用 PUT
        req = urllib.request.Request(
            f"http://127.0.0.1:{PORT}/json/new?{urllib.request.quote(url)}",
            method="PUT")
        r = urllib.request.urlopen(req, timeout=15)
        tgt = json.loads(r.read())
        tid, ws_url = tgt["id"], tgt["webSocketDebuggerUrl"]
        try:
            # Chrome 拒绝带 Origin 头的 CDP WebSocket（防 DNS rebinding）
            ws = websocket.create_connection(
                ws_url, timeout=timeout, suppress_origin=True)
            ws.settimeout(timeout)
            mid = [0]

            def call(method, params=None):
                mid[0] += 1
                ws.send(json.dumps({"id": mid[0], "method": method,
                                    "params": params or {}}))
                while True:
                    msg = json.loads(ws.recv())
                    if msg.get("id") == mid[0]:
                        return msg

            sel_js = json.dumps(selectors)
            expr = f"""(() => {{
                for (const s of {sel_js}) {{
                    const el = document.querySelector(s);
                    if (el && el.innerText && el.innerText.trim().length > 200)
                        return JSON.stringify({{ok:true, sel:s,
                            html: el.innerHTML,
                            title: (document.querySelector('h1')||{{}}).innerText
                                   || document.title}});
                }}
                return JSON.stringify({{ok:false}});
            }})()"""

            deadline = time.time() + timeout
            while time.time() < deadline:
                time.sleep(settle)
                res = call("Runtime.evaluate",
                           {"expression": expr, "returnByValue": True,
                            "awaitPromise": False})
                val = res.get("result", {}).get("result", {}).get("value")
                if val:
                    data = json.loads(val)
                    if data.get("ok"):
                        u = call("Runtime.evaluate",
                                 {"expression": "location.href",
                                  "returnByValue": True})
                        final = u.get("result", {}).get("result", {}).get("value", url)
                        ws.close()
                        return data["html"], (data.get("title") or "").strip(), final
            ws.close()
            return None, None, url
        finally:
            try:
                urllib.request.urlopen(
                    f"http://127.0.0.1:{PORT}/json/close/{tid}", timeout=10).read()
            except Exception:
                pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--domain", action="append", help="只处理这些域名")
    ap.add_argument("--retry-failed", action="store_true",
                    help="重试 fetch-answers 里失败的条目")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--min-cjk", type=int, default=120)
    args = ap.parse_args()

    # 复用 fetch-answers 的转换与落盘逻辑
    spec = import_module("importlib.util")
    import importlib.util
    s = importlib.util.spec_from_file_location(
        "fa", Path(__file__).resolve().parent / "fetch-answers.py")
    fa_mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(fa_mod)

    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    state = json.loads(STATE.read_text(encoding="utf-8")) if STATE.exists() else {}

    if args.retry_failed:
        todo = [i for i in items if i["url"]
                and i["url"] in state and not state[i["url"]].get("ok")]
    else:
        doms = set(args.domain or fa_mod.BROWSER_DOMAINS)
        todo = [i for i in items if i["url"] and fa_mod.domain(i["url"]) in doms
                and not state.get(i["url"], {}).get("ok")]

    # 三种要跳过的：域名被抢注、已有自撰答案、文件已经在了
    # （最后一条防的是并发跑两个抓取进程时 state 互相覆盖导致的「幽灵失败」）
    todo = [i for i in todo
            if fa_mod.domain(i["url"]) not in fa_mod.HIJACKED_DOMAINS
            and not (OUT / i["outfile"]).exists()]
    if args.limit:
        todo = todo[: args.limit]

    print(f"待渲染 {len(todo)} 条\n")
    if not todo:
        return 0

    ok = fail = 0
    with Chrome() as ch:
        for n, item in enumerate(todo, 1):
            url = item["url"]
            d = fa_mod.domain(url)
            tag = f"[{n}/{len(todo)}] {d:<22}"
            try:
                html, title, final = ch.render(
                    url, SELECTORS.get(d, SELECTORS["_default"]))
                if not html:
                    raise ValueError("渲染超时或未找到正文")
                wrapped = f"<div>{html}</div>"
                md, cjk = fa_mod.extract(wrapped, final or url)
                if not md or (cjk < args.min_cjk and len(md) < 800):
                    raise ValueError(f"正文过少 (中文 {cjk} 字)")
                fa_mod.write_doc(item, md, final, note="（经浏览器渲染后提取）")
                state[url] = {"ok": True, "cjk": cjk, "chars": len(md),
                              "file": item["outfile"], "via": "cdp"}
                ok += 1
                print(f"{tag} ✅ {cjk:>5} 中文字  {item['title'][:32]}")
            except Exception as e:
                state[url] = {"ok": False, "err": f"{type(e).__name__}: {e}",
                              "via": "cdp"}
                fail += 1
                print(f"{tag} ❌ {str(e)[:48]}  {item['title'][:24]}")
            STATE.write_text(json.dumps(state, ensure_ascii=False, indent=1),
                             encoding="utf-8")

    print(f"\n本轮：成功 {ok}，失败 {fail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
