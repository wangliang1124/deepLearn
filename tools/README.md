# tools

把 [02-deep-dive.md](../02-deep-dive.md) 里引用的外部文章抓到 [answers/](../answers/) 的脚本。

日常读笔记用不到这些，只有想**重新抓一遍**（原文更新了、补抓失败的、换一批链接）时才需要。

## 依赖

脚本用到几个第三方库，装在临时 venv 里就行，不用污染全局环境：

```bash
python3 -m venv /tmp/fetchenv
/tmp/fetchenv/bin/pip install html2text lxml_html_clean readability-lxml websocket-client
```

`render-answers.py` 还需要本机装了 Chrome（默认路径 `/Applications/Google Chrome.app`）。

## 三个脚本，按顺序跑

```bash
# 1. 解析 02-deep-dive.md，导出条目清单到 /tmp/deepdive-items.json
python3 tools/parse-deepdive.py

# 2. 走 HTTP 抓（cnblogs / segmentfault / MDN / github 等静态站）
/tmp/fetchenv/bin/python tools/fetch-answers.py

# 3. 走 Chrome CDP 渲染（掘金 / 简书 / 知乎 / CSDN 这些 SPA 或反爬站）
/tmp/fetchenv/bin/python tools/render-answers.py

# 4. 生成 answers/README.md 索引，并把本地链接写回 02-deep-dive.md
python3 tools/build-index.py
```

进度记在 `/tmp/fetch-state.json`，**中断后重跑会跳过已成功的**，只补失败和未处理的。

## 常用参数

```bash
tools/fetch-answers.py  --report              # 只看进度和失败清单，不抓
tools/fetch-answers.py  --only segmentfault.com
tools/fetch-answers.py  --limit 5             # 先试几个

tools/render-answers.py --domain juejin.cn
tools/render-answers.py --retry-failed        # 用浏览器重试 HTTP 抓失败的

tools/build-index.py    --dry-run             # 只看会改哪些行
```

## 三个坑，踩过了记在这

**1. 掘金的客户端路由不能用来翻页。** `window.$nuxt.$router.push()` 会改 URL 但**不重新加载文章内容**——实测跳转后 `location.pathname` 变了，`.markdown-body` 还是上一篇（长度一模一样）。必须每篇都开新 target 走完整加载。

**2. Chrome 的 CDP 接口有两道防护。** `/json/new` 在 Chrome 111+ 要求 **PUT** 方法（GET 返回 405）；WebSocket 握手时如果带 `Origin` 头会被拒（403，防 DNS rebinding），要用 `suppress_origin=True`。

**3. `--dump-dom` 在新版 Chrome 上会挂起。** 试过 Chrome 153 的 `--headless --dump-dom`，即使指定独立 `--user-data-dir` 也是超时退出、输出 0 字节。所以最后走的是 `--remote-debugging-port` + CDP，而不是命令行 dump。

## 抓不到的情况

脚本按域名配了正文选择器（见两个脚本里的 `CONTENT_XPATH` / `SELECTORS`），命不中就回退 readability 自动提取。仍然失败的，在 `02-deep-dive.md` 里会标成 `⚠️ 未存档` 并保留原链。

有几类是抓不了的，别浪费时间：

- 原站已下线（IBM developerWorks、AlloyTeam 部分旧文）
- 需要登录才能看全文
- 内容在图片里

这些在 `answers/` 里由**自撰答案**（✍️ 标记）补上。
