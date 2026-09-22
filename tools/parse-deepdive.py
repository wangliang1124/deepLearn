#!/usr/bin/env python3
"""解析 02-deep-dive.md，导出所有参考条目的结构化清单。

输出 /tmp/deepdive-items.json，供抓取脚本使用。
每条记录：章节、题号、题目、条目标题、URL、是否推荐、是否已标注失效。
"""
import json
import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "02-deep-dive.md"

# 章节名 -> 目录 slug
SECTION_SLUG = {
    "JS 深入": "js",
    "浏览器": "browser",
    "HTTP 协议": "http",
    "HTML": "html",
    "CSS": "css",
    "React": "react",
    "状态管理": "state",
    "设计模式": "design-pattern",
    "前端工程": "engineering",
    "正则表达式": "regex",
    "Git": "git",
    "Reference": "reference",
}


def slugify(text, maxlen=40):
    """中文标题 -> 文件名友好的 slug（保留中文，去标点）。"""
    s = text.strip()
    s = re.sub(r"[`*_\[\]()（）【】<>:：/\\\"'?？!！,，。;；]", "", s)
    s = re.sub(r"\s+", "-", s)
    s = s.strip("-")
    return s[:maxlen] or "untitled"


def main():
    lines = SRC.read_text(encoding="utf-8").split("\n")
    items = []
    section = None
    qnum = None
    qtitle = None

    for lineno, line in enumerate(lines, 1):
        m = re.match(r"^## (.+?)\s*$", line)
        if m:
            section = m.group(1)
            qnum = qtitle = None
            continue

        m = re.match(r"^(\d+)\. (.+?)\s*$", line)
        if m and section:
            qnum, qtitle = int(m.group(1)), m.group(2)
            # Reference 章是「N. 标题 URL」，链接直接写在编号行里
            if re.search(r"https?://", qtitle):
                body = qtitle
                qtitle = re.sub(r"\s*https?://\S+", "", qtitle).strip()
            else:
                continue
        else:
            # 参考条目行：>  标题 URL（可带 **推荐**）
            m = re.match(r"^\s*> (.+?)\s*$", line)
            if not m or not section:
                continue
            body = m.group(1)
            # 章节级条目（还没出现编号题目），归到 qnum=0
            if qnum is None:
                qnum, qtitle = 0, section
        recommended = "**推荐**" in body
        body_clean = body.replace("**推荐**", "").strip()

        url_m = re.search(r"(https?://\S+)", body_clean)
        url = url_m.group(1).rstrip(")）,，。") if url_m else None
        title = (body_clean[: url_m.start()] if url_m else body_clean).strip()
        title = re.sub(r"[（(]链接已失效[^）)]*[）)]", "", title).strip()
        title = title.rstrip("·-— ").strip()

        dead = "链接已失效" in body

        items.append(
            {
                "lineno": lineno,
                "section": section,
                "section_slug": SECTION_SLUG.get(section, slugify(section)),
                "qnum": qnum,
                "qtitle": qtitle,
                "title": title or (qtitle or "untitled"),
                "url": url,
                "recommended": recommended,
                "dead": dead,
                "raw": line,
            }
        )

    # 分配输出文件名：<section>/<qnum:02d>-<序号>-<slug>.md
    per_q = {}
    for it in items:
        key = (it["section_slug"], it["qnum"])
        per_q.setdefault(key, []).append(it)
    for (sec, q), group in per_q.items():
        for i, it in enumerate(group, 1):
            suffix = f"-{i}" if len(group) > 1 else ""
            it["outfile"] = f"{sec}/{q:02d}{suffix}-{slugify(it['title'])}.md"

    out = Path("/tmp/deepdive-items.json")
    out.write_text(json.dumps(items, ensure_ascii=False, indent=1), encoding="utf-8")

    withurl = [i for i in items if i["url"]]
    print(f"条目总数        : {len(items)}")
    print(f"  有 URL        : {len(withurl)}")
    print(f"  已标注失效    : {sum(1 for i in items if i['dead'])}")
    print(f"  标记推荐      : {sum(1 for i in items if i['recommended'])}")
    print(f"涉及题目        : {len({(i['section'], i['qnum']) for i in items})}")
    print(f"章节            : {len({i['section'] for i in items})}")
    print(f"\n已写入 {out}")

    # 抽样展示
    print("\n抽样：")
    for it in items[:3] + items[-2:]:
        u = it["url"][:52] + "…" if it["url"] and len(it["url"]) > 52 else (it["url"] or "（无）")
        print(f"  [{it['section']}#{it['qnum']}] {it['title'][:28]}")
        print(f"      -> {it['outfile']}")
        print(f"      {u}")


if __name__ == "__main__":
    sys.exit(main())
