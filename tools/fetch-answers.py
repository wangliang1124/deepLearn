#!/usr/bin/env python3
"""抓取 02-deep-dive.md 引用的外部文章，转成 Markdown 存到 answers/。

用法（需先跑 parse-deepdive.py 生成 /tmp/deepdive-items.json）：
    /tmp/fetchenv/bin/python tools/fetch-answers.py            # 抓 curl 可取的
    /tmp/fetchenv/bin/python tools/fetch-answers.py --only juejin.cn
    /tmp/fetchenv/bin/python tools/fetch-answers.py --report   # 只看进度，不抓

需要浏览器渲染的站点（掘金/简书/知乎/CSDN）不在这里处理，
由 render-answers.py 配合 Chrome 完成。
"""
import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import html2text
import lxml.html
from lxml.html.clean import Cleaner

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "answers"
ITEMS = Path("/tmp/deepdive-items.json")
STATE = Path("/tmp/fetch-state.json")

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

# 需要真实浏览器渲染的域名，本脚本跳过
# 注：简书一度对自动化访问返回 /sfservice 验证页，后来恢复，故改回走 HTTP
BROWSER_DOMAINS = {"juejin.cn", "zhuanlan.zhihu.com", "blog.csdn.net"}

# 域名已过期并被他人抢注，现在返回的是完全无关的内容（盗版影视、赌博等）。
# 这类站点会「抓取成功」但内容是垃圾，必须显式拉黑，否则会污染存档。
HIJACKED_DOMAINS = {
    "taobaofed.org",   # 原淘宝前端团队博客，现为盗版影视站
}

# 每个域名的正文选择器，命中就用，否则回退 readability
CONTENT_XPATH = {
    "www.cnblogs.com": '//*[@id="cnblogs_post_body"]',
    "kb.cnblogs.com": '//*[@id="cnblogs_post_body"] | //div[contains(@class,"article")]',
    "segmentfault.com": '//article | //*[contains(@class,"article__content")]',
    "www.jianshu.com": '//article | //*[contains(@class,"show-content")]',
    "developer.mozilla.org": '//article[contains(@class,"main-page-content")]',
    "github.com": '//article[contains(@class,"markdown-body")] '
                  '| //td[contains(@class,"comment-body")]',
    "react.dev": "//article",
    "reactrouter.com": "//article | //main",
    "web.dev": "//article | //main",
    "tech.meituan.com": '//*[contains(@class,"post-content")] | //article',
    "www.zhangxinxu.com": '//*[contains(@class,"entry-content")] | //article',
    "mp.weixin.qq.com": '//*[@id="js_content"]',
    "css-tricks.com": '//*[contains(@class,"article-content")] | //article',
    "cloud.tencent.com": '//*[contains(@class,"markdown-text")] | //article',
    "redux-toolkit.js.org": "//article | //main",
    "zustand.docs.pmnd.rs": "//article | //main",
    "react-guide.github.io": '//*[contains(@class,"markdown-section")] | //article',
}

CLEANER = Cleaner(
    scripts=True, javascript=True, comments=True, style=True,
    inline_style=True, links=False, meta=True, page_structure=False,
    embedded=True, frames=True, forms=True, annoying_tags=True,
    remove_tags=["header", "footer", "nav", "aside"],
    kill_tags=["svg", "button", "iframe", "noscript"],
)


def domain(url):
    return re.sub(r"^https?://", "", url).split("/")[0]


def fetch(url, timeout=30):
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
    })
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
        enc = r.headers.get_content_charset() or "utf-8"
        final_url = r.geturl()
    try:
        return raw.decode(enc, errors="replace"), final_url
    except LookupError:
        return raw.decode("utf-8", errors="replace"), final_url


def extract(html, url):
    """返回 (markdown, 正文中文字符数)。"""
    d = domain(url)
    doc = None
    xp = CONTENT_XPATH.get(d)
    if xp:
        try:
            tree = lxml.html.fromstring(html)
            tree.make_links_absolute(url, resolve_base_href=True)
            found = tree.xpath(xp)
            if found:
                doc = found[0]
        except Exception:
            doc = None

    if doc is None:
        # 回退：readability 提取主体
        try:
            from readability import Document
            summary = Document(html).summary(html_partial=True)
            doc = lxml.html.fromstring(summary)
            try:
                doc.make_links_absolute(url, resolve_base_href=True)
            except Exception:
                pass
        except Exception:
            return None, 0

    try:
        doc = CLEANER.clean_html(doc)
    except Exception:
        pass

    frag = lxml.html.tostring(doc, encoding="unicode")

    h = html2text.HTML2Text()
    h.body_width = 0
    h.ignore_images = False
    h.ignore_links = False
    h.protect_links = True
    h.single_line_break = False
    md = h.handle(frag).strip()
    md = tidy(md)
    cjk = len(re.findall(r"[一-鿿]", md))
    return md, cjk


def tidy(md):
    """清掉转换产生的噪声：空标题、代码块前后的空缩进行、过多空行。"""
    # 空标题（原站锚点图标转出来的 "## "）
    md = re.sub(r"^#{1,6}\s*$", "", md, flags=re.M)
    # 仅含空白的缩进行（html2text 在 <pre> 前后留下的）
    md = re.sub(r"^[ \t]+$", "", md, flags=re.M)
    # 图片/链接里被 protect_links 包出来的尖括号保持原样，但去掉空链接
    md = re.sub(r"\[\]\(<?\s*>?\)", "", md)
    # 连续空行压到最多两个
    md = re.sub(r"\n{3,}", "\n\n", md)
    return md.strip()


def is_self_written(path):
    """自撰答案不能被抓取结果覆盖。"""
    return path.exists() and "✍️" in path.read_text(encoding="utf-8")[:400]


def write_doc(item, md, final_url, note=""):
    path = OUT / item["outfile"]
    if is_self_written(path):
        raise PermissionError("已有自撰答案，跳过以免覆盖")
    path.parent.mkdir(parents=True, exist_ok=True)
    src = final_url or item["url"]
    header = [
        f"# {item['title']}",
        "",
        "> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。",
        f"> 原文：<{src}>",
        f"> 对应题目：{item['section']} 第 {item['qnum']} 题 · {item['qtitle']}",
        f"> 抓取时间：{time.strftime('%Y-%m-%d')}",
    ]
    if note:
        header.append(f"> {note}")
    header += ["", "---", "", md, ""]
    path.write_text("\n".join(header), encoding="utf-8")
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="只抓该域名")
    ap.add_argument("--report", action="store_true", help="只统计进度")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--min-cjk", type=int, default=120,
                    help="正文中文字符数低于此值视为抓取失败")
    args = ap.parse_args()

    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    state = json.loads(STATE.read_text(encoding="utf-8")) if STATE.exists() else {}

    targets = [i for i in items if i["url"]
               and domain(i["url"]) not in BROWSER_DOMAINS
               and domain(i["url"]) not in HIJACKED_DOMAINS]
    if args.only:
        targets = [i for i in targets if domain(i["url"]) == args.only]

    if args.report:
        done = sum(1 for i in targets if state.get(i["url"], {}).get("ok"))
        print(f"curl 目标 {len(targets)} 个，已完成 {done}，待处理 {len(targets)-done}")
        fails = [(i["title"][:40], state[i["url"]].get("err", "")[:60])
                 for i in targets if i["url"] in state and not state[i["url"]].get("ok")]
        if fails:
            print(f"\n失败 {len(fails)} 个：")
            for t, e in fails:
                print(f"  - {t}  [{e}]")
        return 0

    todo = [i for i in targets if not state.get(i["url"], {}).get("ok")]
    if args.limit:
        todo = todo[: args.limit]
    print(f"待抓 {len(todo)} / 目标 {len(targets)}\n")

    ok = fail = 0
    for n, item in enumerate(todo, 1):
        url = item["url"]
        tag = f"[{n}/{len(todo)}] {domain(url):<24}"
        try:
            html, final_url = fetch(url)
            md, cjk = extract(html, url)
            if not md or (cjk < args.min_cjk and len(md) < 800):
                raise ValueError(f"正文过少 (中文 {cjk} 字, {len(md or '')} 字符)")
            p = write_doc(item, md, final_url)
            state[url] = {"ok": True, "cjk": cjk, "chars": len(md), "file": item["outfile"]}
            ok += 1
            print(f"{tag} ✅ {cjk:>5} 中文字  {item['title'][:34]}")
        except Exception as e:
            state[url] = {"ok": False, "err": f"{type(e).__name__}: {e}"}
            fail += 1
            print(f"{tag} ❌ {type(e).__name__}: {str(e)[:52]}  {item['title'][:26]}")
        STATE.write_text(json.dumps(state, ensure_ascii=False, indent=1), encoding="utf-8")
        time.sleep(0.6)

    print(f"\n本轮：成功 {ok}，失败 {fail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
