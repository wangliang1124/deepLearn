#!/usr/bin/env python3
"""两件事：
1. 生成 answers/README.md 索引
2. 改写 02-deep-dive.md，给已存档的条目加上本地链接（原链保留）

    python3 tools/build-index.py            # 生成索引 + 改写正文
    python3 tools/build-index.py --dry-run  # 只看会改什么
"""
import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEEP = ROOT / "02-deep-dive.md"
OUT = ROOT / "answers"
ITEMS = Path("/tmp/deepdive-items.json")
STATE = Path("/tmp/fetch-state.json")

SECTION_ORDER = ["JS 深入", "浏览器", "HTTP 协议", "HTML", "CSS", "React",
                 "状态管理", "设计模式", "前端工程", "正则表达式", "Git", "Reference"]


def load():
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    state = json.loads(STATE.read_text(encoding="utf-8")) if STATE.exists() else {}
    for it in items:
        st = state.get(it["url"] or "", {})
        p = OUT / it["outfile"]
        # 以文件是否真的存在为准。state 只用来取错误原因——
        # 多个抓取进程并发写 state 时可能互相覆盖，文件系统才是事实来源。
        it["archived"] = p.exists()
        it["cjk"] = st.get("cjk", 0)
        it["err"] = st.get("err", "")
        it["selfwritten"] = (p.exists()
                             and "✍️" in p.read_text(encoding="utf-8")[:400])

    items.extend(find_extras(items))
    return items


SLUG2SEC = {v: k for k, v in {
    "JS 深入": "js", "浏览器": "browser", "HTTP 协议": "http", "HTML": "html",
    "CSS": "css", "React": "react", "状态管理": "state",
    "设计模式": "design-pattern", "前端工程": "engineering",
    "正则表达式": "regex", "Git": "git", "Reference": "reference",
}.items()}


def find_extras(items):
    """捡起 answers/ 里存在、但不在解析清单中的文件（手写补充的答案）。"""
    planned = {i["outfile"] for i in items}
    q_titles = {(i["section"], i["qnum"]): i["qtitle"] for i in items}
    extras = []
    for p in sorted(OUT.rglob("*.md")):
        rel = str(p.relative_to(OUT))
        if rel == "README.md" or rel in planned:
            continue
        sec_slug = rel.split("/")[0]
        section = SLUG2SEC.get(sec_slug, sec_slug)
        m = re.match(r"(\d+)", Path(rel).name)
        qnum = int(m.group(1)) if m else 0
        head = p.read_text(encoding="utf-8")[:400]
        tm = re.match(r"#\s+(.+)", head)
        extras.append({
            "lineno": -1, "section": section, "section_slug": sec_slug,
            "qnum": qnum, "qtitle": q_titles.get((section, qnum), section),
            "title": (tm.group(1).strip() if tm else Path(rel).stem),
            "url": None, "recommended": False, "dead": False,
            "outfile": rel, "archived": True, "cjk": 0, "err": "",
            "selfwritten": "✍️" in head, "extra": True,
        })
    return extras


def rewrite_deepdive(items, dry=False):
    lines = DEEP.read_text(encoding="utf-8").split("\n")
    by_line = {it["lineno"]: it for it in items}
    changed = 0

    for n, it in by_line.items():
        if n < 1:                       # extras 没有对应行号，只进索引不改正文
            continue
        line = lines[n - 1]
        if "answers/" in line:          # 已改过
            continue
        indent = re.match(r"^(\s*)", line).group(1)
        rel = f"answers/{it['outfile']}"

        # Reference 章是「N. 标题 URL」的有序列表，要保留编号而不是改成引用块
        numbered = re.match(r"^\s*(\d+)\.\s", line)
        prefix = f"{indent}{numbered.group(1)}. " if numbered else (
            f"{indent}> " + ("**推荐** " if it["recommended"] else ""))

        if it["archived"]:
            tag = "✍️ 自撰" if it.get("selfwritten") else "📦 存档"
            tail = f"[原文]({it['url']})" if it["url"] else "原链已失效"
            new = f"{prefix}{it['title']} · [{tag}]({rel}) · {tail}"
        else:
            if not it["url"]:
                continue               # 失效且没补答案，保持原样
            reason = "站点超时" if "Timeout" in it["err"] else (
                "站点拒绝抓取" if "403" in it["err"] else "未存档")
            new = f"{prefix}{it['title']} · [原文]({it['url']}) · ⚠️ {reason}"

        if new != line:
            lines[n - 1] = new
            changed += 1

    if not dry:
        DEEP.write_text("\n".join(lines), encoding="utf-8")
    return changed


def build_index(items):
    groups = defaultdict(lambda: defaultdict(list))
    for it in items:
        groups[it["section"]][(it["qnum"], it["qtitle"])].append(it)

    arch = [i for i in items if i["archived"]]
    self_n = sum(1 for i in items if i.get("selfwritten"))
    total_bytes = sum((OUT / i["outfile"]).stat().st_size for i in arch
                      if (OUT / i["outfile"]).exists())

    L = [
        "# answers —— 02-deep-dive 的答案存档",
        "",
        f"[02-deep-dive.md](../02-deep-dive.md) 里 {len({(i['section'], i['qnum']) for i in items})} 道题引用的外部文章，"
        f"抓到本地共 **{len(arch)} 篇**（约 {total_bytes // 1024} KB），离线可读、可全文 grep。",
        "",
        "| 标记 | 含义 |",
        "| --- | --- |",
        "| 📦 存档 | 抓取自原文，仅作个人离线阅读，**版权归原作者**，未做任何修改 |",
        f"| ✍️ 自撰 | 原链已失效或无法访问，由我重新撰写（共 {self_n} 篇） |",
        "",
        "> 抓取脚本见 [../tools/](../tools/)：`parse-deepdive.py` 解析清单，"
        "`fetch-answers.py` 走 HTTP，`render-answers.py` 走 Chrome 渲染 SPA/反爬站点。",
        "",
        "---",
        "",
    ]

    for sec in SECTION_ORDER:
        if sec not in groups:
            continue
        qs = groups[sec]
        n_arch = sum(1 for g in qs.values() for i in g if i["archived"])
        if n_arch == 0:
            continue
        L.append(f"## {sec}")
        L.append("")
        for (qnum, qtitle) in sorted(qs.keys()):
            group = qs[(qnum, qtitle)]
            got = [i for i in group if i["archived"]]
            if not got:
                continue
            head = qtitle if qnum == 0 else f"{qnum}. {qtitle}"
            L.append(f"**{head}**")
            L.append("")
            for i in group:
                tag = "✍️" if i.get("selfwritten") else "📦"
                if i["archived"]:
                    star = "⭐ " if i["recommended"] else ""
                    L.append(f"- {tag} {star}[{i['title']}]({i['outfile']})")
                elif i["url"]:
                    L.append(f"- ⚠️ {i['title']} —— 未存档，[看原文]({i['url']})")
            L.append("")
        L.append("")

    (OUT / "README.md").write_text("\n".join(L).rstrip() + "\n", encoding="utf-8")
    return len(arch), self_n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    items = load()
    OUT.mkdir(exist_ok=True)
    n_arch, n_self = build_index(items)
    changed = rewrite_deepdive(items, dry=args.dry_run)

    print(f"索引已生成 : answers/README.md")
    print(f"  存档     : {n_arch} 篇（其中自撰 {n_self}）")
    print(f"  未存档   : {sum(1 for i in items if not i['archived'] and i['url'])}")
    print(f"02-deep-dive.md {'将改写' if args.dry_run else '已改写'} {changed} 行")


if __name__ == "__main__":
    main()
