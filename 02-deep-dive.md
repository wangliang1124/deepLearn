# 深入学习

按主题整理的参考资料索引。约定：

- **推荐** —— 同一主题下有多篇参考时，标出最值得先读的那篇。判断依据依次是：官方文档/规范 > 有源码或规范依据的深度文 > 概述与转载。
- **（链接已失效）** —— 原文已打不开，保留标题方便自行检索。
- **（已过时）** —— 技术本身已被取代，附现在的做法。

## JS 深入

1. 浅谈 instanceof 和 typeof 的实现原理

    > 浅谈 instanceof 和 typeof 的实现原理 · [📦 存档](answers/js/01-浅谈-instanceof-和-typeof-的实现原理.md) · [原文](https://juejin.cn/post/6844903613584654344)

2. Symbol

    > Symbol · [✍️ 自撰](answers/js/02-Symbol.md) · [原文](http://es6.ruanyifeng.com/#docs/symbol)

3. JavaScript 中的变量在内存中的具体存储形式

    > 前端基础进阶：详细图解 JavaScript 内存空间 · [✍️ 自撰](answers/js/03-前端基础进阶详细图解-JavaScript-内存空间.md) · 原链已失效

4. 理解 XSS 和 CSRF 原理

    > **推荐** 前端安全系列（一）：如何防止 XSS 攻击？ · [📦 存档](answers/js/04-1-前端安全系列一如何防止-XSS-攻击.md) · [原文](https://tech.meituan.com/2018/09/27/fe-security.html)

    > 浅说 XSS 和 CSRF · [📦 存档](answers/js/04-2-浅说-XSS-和-CSRF.md) · [原文](https://juejin.cn/post/6844903638532358151)

    > Web 安全的三个攻防姿势 · [📦 存档](answers/js/04-3-Web-安全的三个攻防姿势.md) · [原文](https://juejin.cn/post/6844903504369172494)

    > 浅谈 CSRF 攻击方式 · [📦 存档](answers/js/04-4-浅谈-CSRF-攻击方式.md) · [原文](https://www.cnblogs.com/hyddd/archive/2009/04/09/1432744.html)

5. 理解 es6 class 构造以及继承的底层实现原理

    > ES6 创建类的基本语法和继承实现原理 · [📦 存档](answers/js/05-ES6-创建类的基本语法和继承实现原理.md) · [原文](https://juejin.cn/post/6844903581443702792)

6. 理解 this

    > this、apply、call、bind · [📦 存档](answers/js/06-this、apply、call、bind.md) · [原文](https://juejin.cn/post/6844903496253177863)

7. 作用域和闭包

    > **推荐** 闭包详解 · [📦 存档](answers/js/07-1-闭包详解.md) · [原文](https://juejin.cn/post/6844903612879994887)

    > 作用域与词法作用域 · [📦 存档](answers/js/07-2-作用域与词法作用域.md) · [原文](https://juejin.cn/post/6844903606311714824)

8. try catch finally 语句执行原理

    > try 里面放 return，finally 还会执行吗？ · [✍️ 自撰](answers/js/08-try-里面放-returnfinally-还会执行吗.md) · 原链已失效

9. EventLoop

    > **推荐** 从 event loop 规范探究 javaScript 异步及浏览器更新渲染时机 · [📦 存档](answers/js/09-1-从-event-loop-规范探究-javaScript-异步及浏览器更新渲染时.md) · [原文](https://github.com/aooy/blog/issues/5)

    > JavaScript 运行机制详解：再谈 Event Loop · [📦 存档](answers/js/09-2-JavaScript-运行机制详解再谈-Event-Loop.md) · [原文](http://www.ruanyifeng.com/blog/2014/10/event-loop.html)

    > JavaScript：彻底理解同步、异步和事件循环(Event Loop) · [📦 存档](answers/js/09-3-JavaScript彻底理解同步、异步和事件循环Event-Loop.md) · [原文](https://segmentfault.com/a/1190000004322358)

    > 深入探究 eventloop 与浏览器渲染的时序问题（原 issue 已删，仓库仍在） · [📦 存档](answers/js/09-4-深入探究-eventloop-与浏览器渲染的时序问题原-issue-已删仓库仍在.md) · [原文](https://github.com/jin5354/404forest)

10. 微任务、宏任务与 EventLoop

    > **推荐** Tasks, microtasks, queues and schedules · [📦 存档](answers/js/10-1-Tasks-microtasks-queues-and-schedules.md) · [原文](https://jakearchibald.com/2015/tasks-microtasks-queues-and-schedules/)

    > 微任务、宏任务与 Event-Loop · [📦 存档](answers/js/10-2-微任务、宏任务与-Event-Loop.md) · [原文](https://juejin.cn/post/6844903657264136200)

11. 如何处理跨域

    > **推荐** 不要再问我跨域的问题了 · [📦 存档](answers/js/11-1-不要再问我跨域的问题了.md) · [原文](https://segmentfault.com/a/1190000015597029)

    > 前端常见跨域解决方案 · [📦 存档](answers/js/11-2-前端常见跨域解决方案.md) · [原文](https://segmentfault.com/a/1190000011145364)

12. Execution Context

    > 深入理解 JavaScript 执行上下文和执行栈 · [📦 存档](answers/js/12-深入理解-JavaScript-执行上下文和执行栈.md) · [原文](https://juejin.cn/post/6844903798784131079)

13. 异步

    > 异步解决方案的发展历程以及优缺点 · [✍️ 自撰](answers/js/13-异步解决方案的发展历程以及优缺点.md) · [原文](https://github.com/frontend9/fe9-interview/issues/24)

14. Promise

    > **推荐** 一文彻底搞懂 promise 的实现原理 · [📦 存档](answers/js/14-1-一文彻底搞懂-promise-的实现原理.md) · [原文](https://juejin.cn/post/7122328833507885063)

    > Promise 了解多少？ · [📦 存档](answers/js/14-2-Promise-了解多少.md) · [原文](https://github.com/pro-collection/interview-question/issues/1)

15. 继承

    > **推荐** JavaScript 深入之继承的多种方式和优缺点 · [📦 存档](answers/js/15-1-JavaScript-深入之继承的多种方式和优缺点.md) · [原文](https://github.com/mqyqingfeng/Blog/issues/16)

    > 深入 JavaScript 继承原理 · [📦 存档](answers/js/15-2-深入-JavaScript-继承原理.md) · [原文](https://juejin.cn/post/6844903569317953543)

16. 内存泄漏

    > 4 种 JavaScript 内存泄漏浅析及如何用谷歌工具查内存泄露 · [📦 存档](answers/js/16-4-种-JavaScript-内存泄漏浅析及如何用谷歌工具查内存泄露.md) · [原文](https://github.com/wengjq/Blog/issues/1)

17. Javascript 创建对象的几种方式

    > JavaScript 深入之创建对象的多种方式以及优缺点 · [📦 存档](answers/js/17-JavaScript-深入之创建对象的多种方式以及优缺点.md) · [原文](https://github.com/mqyqingfeng/Blog/issues/15)

## 浏览器

1. 浏览器工作原理

    > **推荐** 浏览器的工作原理 · [📦 存档](answers/browser/01-1-浏览器的工作原理.md) · [原文](https://web.dev/articles/howbrowserswork)

    > How browsers work · [原文](https://taligarsiel.com/projects/howbrowserswork1.html) · ⚠️ 未存档

    > 浏览器渲染详细过程：重绘、重排和 composite 只是冰山一角 · [📦 存档](answers/browser/01-3-浏览器渲染详细过程重绘、重排和-composite-只是冰山一角.md) · [原文](https://juejin.cn/post/6844903476506394638)

    > 你真的了解回流和重绘吗 · [📦 存档](answers/browser/01-4-你真的了解回流和重绘吗.md) · [原文](https://github.com/chenjigeng/blog/issues/4)

2. 浏览器缓存

    > **推荐** 深入理解浏览器的缓存机制 · [📦 存档](answers/browser/02-1-深入理解浏览器的缓存机制.md) · [原文](https://www.jianshu.com/p/54cc04190252)

    > 浏览器缓存知识小结及应用 · [📦 存档](answers/browser/02-2-浏览器缓存知识小结及应用.md) · [原文](https://www.cnblogs.com/lyzg/p/5125934.html)

3. 视口宽高、位置与滚动高度

    > JavaScript 视口宽高、元素位置、滚动高度、尺寸属性 · [📦 存档](answers/browser/03-JavaScript-视口宽高、元素位置、滚动高度、尺寸属性.md) · [原文](https://www.jianshu.com/p/62f691f4811c)

4. DOM 操作成本到底高在哪儿？

    > DOM 操作成本到底高在哪儿？ · [📦 存档](answers/browser/04-DOM-操作成本到底高在哪儿.md) · [原文](https://segmentfault.com/a/1190000014070240)

5. 从输入 URL 到页面加载发生了什么？

    > 【原】老生常谈-从输入 url 到页面展示到底发生了什么 · [📦 存档](answers/browser/05-原老生常谈-从输入-url-到页面展示到底发生了什么.md) · [原文](http://www.cnblogs.com/xianyulaodi/p/6547807.html)

## HTTP 协议

1. HTTPS

    > **推荐** HTTPS 详解 · [📦 存档](answers/http/01-1-HTTPS-详解.md) · [原文](https://segmentfault.com/a/1190000011675421)

    > HTTPS 工作原理 · [📦 存档](answers/http/01-2-HTTPS-工作原理.md) · [原文](https://www.cnblogs.com/xrq730/p/5041921.html)

    > 图文还原 HTTPS 原理，架构师必读！ · [原文](https://mp.weixin.qq.com/s?__biz=MzI3NjU2ODA5Mg==&mid=2247483985&idx=1&sn=0b6de989219032d64648785946a974a4) · ⚠️ 未存档

    > HTTPS 工作原理（链接已失效）

2. HTTP 协议

    > **推荐** HTTP 协议入门 · [📦 存档](answers/http/02-1-HTTP-协议入门.md) · [原文](http://www.ruanyifeng.com/blog/2016/08/http.html)

    > 深入理解 HTTP 协议 · [📦 存档](answers/http/02-2-深入理解-HTTP-协议.md) · [原文](https://juejin.cn/post/6844903683235250183)

    > HTTP 协议 · [📦 存档](answers/http/02-3-HTTP-协议.md) · [原文](https://juejin.cn/post/6844903865410650126)

3. 公钥和私钥

    > **推荐** 数字签名是什么？ · [📦 存档](answers/http/03-1-数字签名是什么.md) · [原文](http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html)

    > 理解公钥与私钥（链接已失效）

4. http 状态码有哪些？分别代表是什么意思？

    > **推荐** HTTP 响应状态码 · [📦 存档](answers/http/04-1-HTTP-响应状态码.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status)

    > http 状态码是什么，有什么用，在哪里查看，分别代表什么意思？ · [📦 存档](answers/http/04-2-http-状态码是什么有什么用在哪里查看分别代表什么意思.md) · [原文](https://juejin.cn/post/6844903476099547144)

5. HTTP 请求报文和 HTTP 响应报文

    > **推荐** 一篇文章带你详解 HTTP 协议（网络协议篇一） · [📦 存档](answers/http/05-1-一篇文章带你详解-HTTP-协议网络协议篇一.md) · [原文](https://www.jianshu.com/p/6e9e4156ece3)

    > HTTP 请求报文和 HTTP 响应报文 · [📦 存档](answers/http/05-2-HTTP-请求报文和-HTTP-响应报文.md) · [原文](https://www.cnblogs.com/biyeymyhjob/archive/2012/07/28/2612910.html)

6. http1.1 时如何复用 tcp 连接

    Keep-Alive 只是让同一条 TCP 连接串行地跑多个请求，队头阻塞依旧存在。HTTP/2 用二进制分帧和多路复用在一条连接上并行收发，HTTP/3 换到 QUIC 进一步解决了 TCP 层的队头阻塞。

    > HTTP 协议篇(一)：多路复用、数据流（链接已失效）

    > 连接管理 · [📦 存档](answers/http/06-2-连接管理.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Guides/Connection_management_in_HTTP_1.x)

7. HTTP Header 详解

    > HTTP Header 详解 · [📦 存档](answers/http/07-HTTP-Header-详解.md) · [原文](https://kb.cnblogs.com/page/92320/)

8. Token

    > **推荐** 彻底理解 cookie，session，token · [📦 存档](answers/http/08-1-彻底理解-cookiesessiontoken.md) · [原文](https://www.cnblogs.com/moyand/p/9047978.html)

    > 基于 Token 的身份验证 · [📦 存档](answers/http/08-2-基于-Token-的身份验证.md) · [原文](https://ninghao.net/blog/2834)

9. TCP 协议

    > **推荐** 通俗大白话来理解 TCP 协议的三次握手和四次分手 · [📦 存档](answers/http/09-1-通俗大白话来理解-TCP-协议的三次握手和四次分手.md) · [原文](https://github.com/jawil/blog/issues/14)

    > 一篇文章带你熟悉 TCP/IP 协议（网络协议篇二） · [📦 存档](answers/http/09-2-一篇文章带你熟悉-TCPIP-协议网络协议篇二.md) · [原文](https://www.jianshu.com/p/9f3e879a4c9c)

## HTML

1. HTML5 离线缓存原理

    **（已过时）** `manifest`（Application Cache）已从标准中移除，主流浏览器均已废弃。现在做离线缓存用 Service Worker + Cache API。

    > **推荐** Service Worker API · [📦 存档](answers/html/01-1-Service-Worker-API.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/API/Service_Worker_API)

    > HTML5 离线缓存-manifest 简介 · [📦 存档](answers/html/01-2-HTML5-离线缓存-manifest-简介.md) · [原文](http://yanhaijing.com/html/2014/12/28/html5-manifest/)

    > HTML5 离线存储 初探 · [📦 存档](answers/html/01-3-HTML5-离线存储-初探.md) · [原文](http://www.cnblogs.com/chyingp/archive/2012/12/01/explore_html5_cache.html)

    > 有趣的 HTML5：离线存储 · [📦 存档](answers/html/01-4-有趣的-HTML5离线存储.md) · [原文](https://segmentfault.com/a/1190000000732617)

2. iframe 异步加载技术及性能

    > iframe 异步加载技术及性能 · [📦 存档](answers/html/02-iframe-异步加载技术及性能.md) · [原文](http://www.cnblogs.com/beiyuu/archive/2011/07/18/iframe-tech-performance.html)

3. Page Visibility API

    > **推荐** Page Visibility(页面可见性) API 介绍、微拓展 · [📦 存档](answers/html/03-1-Page-Visibility页面可见性-API-介绍、微拓展.md) · [原文](https://www.zhangxinxu.com/wordpress/2012/11/page-visibility-api-introduction-extend/)

    > HTML5 页面可见性接口应用 · [📦 存档](answers/html/03-2-HTML5-页面可见性接口应用.md) · [原文](https://www.helloweba.net/javascript/390.html)

4. Web Worker

    原有两篇参考都已失效，改用官方文档。

    > **推荐** 使用 Web Worker · [📦 存档](answers/html/04-1-使用-Web-Worker.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/API/Web_Workers_API/Using_web_workers)

    > web worker 详解（链接已失效）

    > 深入 HTML5 Web Worker 应用实践：多线程编程（IBM developerWorks 已下线，链接已失效）

5. PostMessage

    > **推荐** Window.postMessage() · [📦 存档](answers/html/05-1-Window.postMessage.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/API/Window/postMessage)

    > html5 API postMessage 跨域详解 · [📦 存档](answers/html/05-2-html5-API-postMessage-跨域详解.md) · [原文](http://blog.xieliqun.com/2016/08/25/postMessage-cross-domain/)

6. requestAnimationFrame

    > 浅析 requestAnimationFrame · [✍️ 自撰](answers/html/06-浅析-requestAnimationFrame.md) · [原文](https://taobaofed.org/blog/2017/03/02/thinking-in-request-animation-frame/)

7. HTML5 File API

    > **推荐** 通过 File API 使用 JavaScript 读取文件 · [📦 存档](answers/html/07-1-通过-File-API-使用-JavaScript-读取文件.md) · [原文](https://web.dev/articles/read-files)

    > 基于 html5 File API 的文件操作 · [📦 存档](answers/html/07-2-基于-html5-File-API-的文件操作.md) · [原文](https://segmentfault.com/a/1190000006600936)

8. HTML meta 标签

    > **推荐** 常见的 meta 标签及详细解说 · [📦 存档](answers/html/08-1-常见的-meta-标签及详细解说.md) · [原文](https://www.jianshu.com/p/ce6edbe8825d)

    > HTML-meta 标签详解 · [📦 存档](answers/html/08-2-HTML-meta-标签详解.md) · [原文](https://www.jianshu.com/p/30bf38c799e4)

## CSS

1. CSS Animation

    > 使用 css 实现一个持续的动画效果 · [📦 存档](answers/css/01-使用-css-实现一个持续的动画效果.md) · [原文](http://www.cnblogs.com/gaoxuerong123/p/8540554.html)

2. CSS3 Box-sizing

    > CSS3 box-sizing 详解 · [📦 存档](answers/css/02-CSS3-box-sizing-详解.md) · [原文](https://www.cnblogs.com/iflygofy/p/6323275.html)

3. CSS 选择器及其优先级

    > CSS 优先级计算规则 · [📦 存档](answers/css/03-CSS-优先级计算规则.md) · [原文](http://www.cnblogs.com/wangmeijian/p/4207433.html)

4. 居中

    现在优先用 Flexbox（`display: flex; align-items: center; justify-content: center`）或 Grid（`display: grid; place-items: center`）。下面几篇讲的是绝对定位、负 margin、`table-cell` 等旧方案，了解原理和兼容场景时看。

    > 盘点 8 种 CSS 实现垂直居中水平居中的绝对定位居中技术 · [📦 存档](answers/css/04-1-盘点-8-种-CSS-实现垂直居中水平居中的绝对定位居中技术.md) · [原文](https://blog.csdn.net/freshlover/article/details/11579669)

    > CSS 实现垂直居中 6 种方法 · [📦 存档](answers/css/04-2-CSS-实现垂直居中-6-种方法.md) · [原文](http://www.cnblogs.com/Yirannnnnn/p/4933332.html)

    > CSS 垂直居中的方法 · [📦 存档](answers/css/04-3-CSS-垂直居中的方法.md) · [原文](http://www.cnblogs.com/yugege/p/5246652.html)

5. 布局

    > **推荐** CSS 布局解决方案（终结版） · [📦 存档](answers/css/05-1-CSS-布局解决方案终结版.md) · [原文](https://segmentfault.com/a/1190000013565024)

    > CSS 布局说——可能是最全的 · [📦 存档](answers/css/05-2-CSS-布局说——可能是最全的.md) · [原文](https://segmentfault.com/a/1190000011358507)

    > CSS 常见布局方式 · [📦 存档](answers/css/05-3-CSS-常见布局方式.md) · [原文](https://juejin.cn/post/6844903491891118087)

    > 一个满屏品字布局怎么设计？ · [📦 存档](answers/css/05-4-一个满屏品字布局怎么设计.md) · [原文](https://blog.csdn.net/sjinsa/article/details/70903940)

6. 轮播图

    > 原生 JS 实现轮播图 · [📦 存档](answers/css/06-原生-JS-实现轮播图.md) · [原文](https://juejin.cn/post/6844903670618800136)

7. 移动端适配

    > **推荐** 移动端适配方案(上下) · [📦 存档](answers/css/07-1-移动端适配方案上下.md) · [原文](https://github.com/riskers/blog/issues/17)

    > 关于移动端适配，你必须要知道的 · [原文](https://mp.weixin.qq.com/s/V3UpVZH8AWfSScIRAsr2dw) · ⚠️ 未存档

8. Containing Block

    > **推荐** Layout and the containing block · [📦 存档](answers/css/08-1-Layout-and-the-containing-block.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/CSS/CSS_display/Containing_block)

    > KB008: 包含块( Containing block ) · [原文](http://w3help.org/zh-cn/kb/008/) · ⚠️ 未存档

9. BFC

    > **推荐** 前端精选文摘：BFC 神奇背后的原理 · [📦 存档](answers/css/09-1-前端精选文摘BFC-神奇背后的原理.md) · [原文](http://www.cnblogs.com/lhb25/p/inside-block-formatting-ontext.html)

    > 理解 CSS 中 BFC（链接已失效）

10. 浏览器是怎样解析 CSS 选择器的

    > CSS 选择器从右向左的匹配规则 · [📦 存档](answers/css/10-CSS-选择器从右向左的匹配规则.md) · [原文](http://www.cnblogs.com/zhaodongyu/p/3341080.html)

11. 元素竖向的百分比设定是相对于容器的高度吗

    > 元素竖向的百分比设定是相对于容器的高度吗 · [📦 存档](answers/css/11-元素竖向的百分比设定是相对于容器的高度吗.md) · [原文](https://segmentfault.com/a/1190000012955996)

12. 全屏滚动

    > **推荐** 用 ES6 写全屏滚动插件 · [📦 存档](answers/css/12-1-用-ES6-写全屏滚动插件.md) · [原文](https://juejin.cn/post/6844903602574770183)

    > H5 全屏滑动 · [📦 存档](answers/css/12-2-H5-全屏滑动.md) · [原文](https://segmentfault.com/a/1190000003691168)

13. 视差滚动

    > **推荐** 小 tip: 纯 CSS 实现视差滚动效果 · [📦 存档](answers/css/13-1-小-tip-纯-CSS-实现视差滚动效果.md) · [原文](https://www.zhangxinxu.com/wordpress/2015/03/css-only-parallax-effect/)

    > 视差滚动(Parallax Scrolling)效果的原理和实现 · [📦 存档](answers/css/13-2-视差滚动Parallax-Scrolling效果的原理和实现.md) · [原文](http://www.cnblogs.com/JoannaQ/archive/2013/02/08/2909111.html)

    > Alloy Team 的《视差滚动的爱情故事》（链接已失效）

14. 理解 line-height

    > **推荐** css 行高 line-height 的一些深入理解及应用 · [📦 存档](answers/css/14-1-css-行高-line-height-的一些深入理解及应用.md) · [原文](https://www.zhangxinxu.com/wordpress/2009/11/css%E8%A1%8C%E9%AB%98line-height%E7%9A%84%E4%B8%80%E4%BA%9B%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3%E5%8F%8A%E5%BA%94%E7%94%A8/)

    > 我对 line-height 及 vertical-align 的一点理解 · [📦 存档](answers/css/14-2-我对-line-height-及-vertical-align-的一点理解.md) · [原文](https://segmentfault.com/a/1190000013031367)

    > 深入理解 CSS 中的行高 · [📦 存档](answers/css/14-3-深入理解-CSS-中的行高.md) · [原文](http://www.cnblogs.com/rainman/archive/2011/08/05/2128068.html)

15. Sticky Footer

    > **推荐** Sticky Footer, Five Ways · [📦 存档](answers/css/15-1-Sticky-Footer-Five-Ways.md) · [原文](https://css-tricks.com/couple-takes-sticky-footer/)

    > Sticky Footer，完美的绝对底部（原站已迁移至 jelly.jd.com 且无法访问，链接已失效）

16. CSS3 Transform Perspective

    > **推荐** perspective · [📦 存档](answers/css/16-1-perspective.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/CSS/perspective)

    > CSS3 实践之摩天轮式图片轮播+3D 正方体+3D 标签云（链接已失效）

17. PNG 图片压缩原理

    > PNG 图片压缩原理（原 issue 已删，仓库仍在） · [📦 存档](answers/css/17-PNG-图片压缩原理原-issue-已删仓库仍在.md) · [原文](https://github.com/airuikun/blog)

## React

下面多数条目成文于 class 组件时代。核心机制（事件、diff、key、受控组件）仍然适用，但 API 层面现在以函数组件 + Hooks 为主，标注了**（已过时）**的条目按现在的写法读。

1. 组件之间如何通信

    > **推荐** React 中组件通信的几种方式 · [📦 存档](answers/react/01-1-React-中组件通信的几种方式.md) · [原文](https://juejin.cn/post/6844903520500449288)

    > React 组件间通讯 · [原文](http://taobaofed.org/blog/2016/11/17/react-components-communication/) · ⚠️ 站点拒绝抓取

2. 如何配置 React-Router

    **（已过时）** 下面前两篇是 React Router v2/v3 的配置方式，与现在的 v6/v7 差别很大（`<Routes>`、`createBrowserRouter`、数据路由）。原理部分仍可参考。

    > **推荐** React Router 官方文档 · [📦 存档](answers/react/02-1-React-Router-官方文档.md) · [原文](https://reactrouter.com/)

    > 单页面应用路由实现原理 · [📦 存档](answers/react/02-2-单页面应用路由实现原理.md) · [原文](https://github.com/youngwind/blog/issues/109)

    > 从路由原理出发，深入阅读理解 react-router 4.0 的源码 · [📦 存档](answers/react/02-3-从路由原理出发深入阅读理解-react-router-4.0-的源码.md) · [原文](https://github.com/forthealllight/blog/issues/26)

    > 路由配置（v2/v3） · [📦 存档](answers/react/02-4-路由配置v2v3.md) · [原文](https://react-guide.github.io/react-router-cn/docs/guides/basics/RouteConfiguration.html)

    > React Router 使用教程（v2/v3） · [📦 存档](answers/react/02-5-React-Router-使用教程v2v3.md) · [原文](http://www.ruanyifeng.com/blog/2016/05/react_router.html)

3. React 事件机制

    React 17 起，事件委托的挂载点从 `document` 改到了 React 树的**根容器**，多版本 React 共存时不再互相干扰。下面两篇成文于 16.x，读到「挂载在 document 上」时注意这个变化。

    > **推荐** React 事件机制 - 源码概览（上） · [📦 存档](answers/react/03-1-React-事件机制---源码概览上.md) · [原文](https://juejin.cn/post/6844903700423507976)

    > React 事件系统分析与最佳实践 · [📦 存档](answers/react/03-2-React-事件系统分析与最佳实践.md) · [原文](https://zhuanlan.zhihu.com/p/27132447)

4. React 怎么做数据的检查和变化

    > React 高效渲染策略 · [📦 存档](answers/react/04-React-高效渲染策略.md) · [原文](https://github.com/fi3ework/blog/issues/15)

5. 虚拟 DOM & diff 原理

    > **推荐** 深度剖析：如何实现一个 Virtual DOM 算法 · [📦 存档](answers/react/05-1-深度剖析如何实现一个-Virtual-DOM-算法.md) · [原文](https://github.com/livoras/blog/issues/13)

    > React 源码剖析系列 － 不可思议的 react diff · [📦 存档](answers/react/05-2-React-源码剖析系列-－-不可思议的-react-diff.md) · [原文](https://zhuanlan.zhihu.com/p/20346379)

6. React 中 keys 的作用是什么？

    > React 技术内幕 key 带来了什么 · [📦 存档](answers/react/06-React-技术内幕-key-带来了什么.md) · [原文](https://juejin.cn/post/6844903493900173320)

7. WebView 和原生是如何通信

    > IOS、Android 与 H5 通信-JsBridge 原理(总结) · [📦 存档](answers/react/07-1-IOS、Android-与-H5-通信-JsBridge-原理总结.md) · [原文](https://juejin.cn/post/6844903586082766862)

    > 好好和 h5 沟通！几种常见的 hybrid 通信方式（链接已失效）

    仓库内另有一篇笔记：[原生 / RN / H5 通信原理](native-rn-h5-bridge.md)

8. RN 遇到的兼容性问题

    > React+RN 开发过程中的一些问题总结 · [📦 存档](answers/react/08-React+RN-开发过程中的一些问题总结.md) · [原文](https://github.com/amandakelake/blog/issues/52)

9. RN 如何实现一个原生的组件

    > **推荐** React Native 封装原生 UI 组件(iOS) · [📦 存档](answers/react/09-1-React-Native-封装原生-UI-组件iOS.md) · [原文](https://www.jianshu.com/p/e16c91acce03)

    > React Native 集成到原生项目 · [📦 存档](answers/react/09-2-React-Native-集成到原生项目.md) · [原文](https://www.jianshu.com/p/3dc9d70a790f)

    > ReactNative 之原生模块开发并发布——iOS 篇 · [📦 存档](answers/react/09-3-ReactNative-之原生模块开发并发布——iOS-篇.md) · [原文](http://www.liuchungui.com/blog/2016/05/02/reactnativezhi-yuan-sheng-mo-kuai-kai-fa-bing-fa-bu-iospian/)

10. RN 的原理，为什么可以同时在安卓和 IOS 端运行

    > React Native for Android 原理分析与实践：实现原理 · [📦 存档](answers/react/10-React-Native-for-Android-原理分析与实践实现原理.md) · [原文](https://juejin.cn/post/6844903553283129352)

11. RN 如何调用原生的一些功能

    > RN 调用原生流程总结 · [📦 存档](answers/react/11-RN-调用原生流程总结.md) · [原文](https://www.jianshu.com/p/b078ab50baf3)

12. RN 和原生通信

    > **推荐** React Native 通信机制详解 · [原文](http://blog.cnbang.net/tech/2698/) · ⚠️ 未存档

    > React Native 与 iOS 和 Android 通信 · [📦 存档](answers/react/12-2-React-Native-与-iOS-和-Android-通信.md) · [原文](https://juejin.cn/post/6844903779653910541)

    > ReactNative 与原生代码的通信(iOS 篇) · [📦 存档](answers/react/12-3-ReactNative-与原生代码的通信iOS-篇.md) · [原文](https://www.jianshu.com/p/99c32dc5cf29)

13. React 中 refs 的作用是什么？

    > React 之 ref 详细用法 · [📦 存档](answers/react/13-React-之-ref-详细用法.md) · [原文](https://segmentfault.com/a/1190000008665915)

14. React 中有三种构建组件的方式

    **（已过时）** 这三种指 `createClass`、class 组件、无状态函数组件。`React.createClass` 早在 React 16 就已移除；现在只有函数组件（配合 Hooks）和 class 组件两种，且官方推荐函数组件。

    > **推荐** 你的第一个组件 · [📦 存档](answers/react/14-1-你的第一个组件.md) · [原文](https://react.dev/learn/your-first-component)

    > React 创建组件的三种方式及其区别 · [📦 存档](answers/react/14-2-React-创建组件的三种方式及其区别.md) · [原文](https://cloud.tencent.com/developer/article/1165838)

15. 调用 setState 之后发生了什么？

    > **推荐** 你真的理解 setState 吗？ · [📦 存档](answers/react/15-1-你真的理解-setState-吗.md) · [原文](https://juejin.cn/post/6844903636749778958)

    > React setState 详解 · [📦 存档](answers/react/15-2-React-setState-详解.md) · [原文](https://github.com/PeterChen1997/FightForOffer/wiki/02-React-setState%E8%AF%A6%E8%A7%A3)

    > setState 源码分析，流程详解（链接已失效）

16. 为什么建议传递给 setState 的参数是一个 callback 而不是一个对象

    > 为什么建议传递给 setState 的参数是一个 callback · [📦 存档](answers/react/16-为什么建议传递给-setState-的参数是一个-callback.md) · [原文](https://juejin.cn/post/6844903470613397517)

17. (在构造函数中)调用 super(props) 的目的是什么

    **（已过时）** 只在 class 组件里需要关心，函数组件没有这个问题。

    > React 构造函数中为什么要写 super(props) · [📦 存档](answers/react/17-React-构造函数中为什么要写-superprops.md) · [原文](https://blog.csdn.net/huangpb123/article/details/85009024)

18. 在 React 当中 Element 和 Component 有何区别？createElement 和 cloneElement 有什么区别？

    > **推荐** 比较与理解 React 的 Components，Elements 和 Instances · [📦 存档](answers/react/18-1-比较与理解-React-的-ComponentsElements-和-Insta.md) · [原文](https://github.com/creeperyang/blog/issues/30)

    > React 中元素与组件的区别 · [📦 存档](answers/react/18-2-React-中元素与组件的区别.md) · [原文](https://segmentfault.com/a/1190000008587988)

19. Controlled Component 与 Uncontrolled Component 之间的区别是什么？

    > React 中受控与非受控组件 · [📦 存档](answers/react/19-React-中受控与非受控组件.md) · [原文](https://segmentfault.com/a/1190000012404114)

## 状态管理

下面的条目停在 Redux + 手写 `connect` 的阶段。现在写 Redux 一律用官方的 Redux Toolkit（内置 Immer、Thunk、DevTools，不用手写 action type 和 reducer 样板）；轻量场景更常见的是 Zustand 这类原子化方案，很多项目已经不需要独立的状态库了。

> **推荐** Redux Toolkit · [📦 存档](answers/state/00-1-Redux-Toolkit.md) · [原文](https://redux-toolkit.js.org/)

> Zustand · [原文](https://zustand.docs.pmnd.rs/) · ⚠️ 未存档

1. Vuex、Flux、Redux、Redux-saga、Dva、MobX

    > Vuex、Flux、Redux、Redux-saga、Dva、MobX · [📦 存档](answers/state/01-Vuex、Flux、Redux、Redux-saga、Dva、MobX.md) · [原文](https://zhuanlan.zhihu.com/p/53599723)

    仓库内另有一篇笔记：[状态管理对比](state-management-comparison.md)

2. React Hooks

    原参考文章已失效，改用官方文档。

    > **推荐** 内置 React Hook · [📦 存档](answers/state/02-1-内置-React-Hook.md) · [原文](https://react.dev/reference/react/hooks)

    > 用状态响应输入 · [📦 存档](answers/state/02-2-用状态响应输入.md) · [原文](https://react.dev/learn/state-a-components-memory)

    仓库内另有一篇笔记：[React Hooks 面试题](react-hooks.md)（19 题，配可运行 demo）

3. Redux

    > **推荐** 完全理解 redux（从零实现一个 redux） · [📦 存档](answers/state/03-1-完全理解-redux从零实现一个-redux.md) · [原文](https://github.com/brickspert/blog/issues/22)

    > Redux 入坑进阶-源码解析 · [📦 存档](answers/state/03-2-Redux-入坑进阶-源码解析.md) · [原文](https://github.com/ecmadao/Coding-Guide/blob/master/Notes/React/Redux/Redux%E5%85%A5%E5%9D%91%E8%BF%9B%E9%98%B6-%E6%BA%90%E7%A0%81%E8%A7%A3%E6%9E%90.md)

4. Redux 如何实现多个组件之间的通信，多个组件使用相同状态如何进行管理

    > **推荐** 彻底弄懂 React-Redux 组件通信 · [📦 存档](answers/state/04-1-彻底弄懂-React-Redux-组件通信.md) · [原文](https://blog.csdn.net/DFF1993/article/details/80410154)

    > 用 Redux 来进行组件间通讯 · [📦 存档](answers/state/04-2-用-Redux-来进行组件间通讯.md) · [原文](https://segmentfault.com/a/1190000008411613)

5. Redux 中间件是什么东西，接受几个参数（两端的柯里化函数）

    > redux 中间件原理及实现 · [📦 存档](answers/state/05-redux-中间件原理及实现.md) · [原文](https://www.jianshu.com/p/8c2a37247020)

6. Redux 中异步的请求怎么处理

    > Redux 异步流最佳实践 · [📦 存档](answers/state/06-Redux-异步流最佳实践.md) · [原文](https://juejin.cn/post/6844903508571848717)

7. React-Redux

    > React-Redux 源码分析 · [📦 存档](answers/state/07-React-Redux-源码分析.md) · [原文](https://juejin.cn/post/6844903498346135565)

    仓库内另有一篇笔记：[React-Redux 原理](react-redux-internals.md)

## 设计模式

1. 观察者模式

    > 观察者模式 vs 发布-订阅模式 · [📦 存档](answers/design-pattern/01-观察者模式-vs-发布-订阅模式.md) · [原文](https://juejin.cn/post/6844903513009422343)

## 前端工程

1. 简单实现项目代码按需加载，例如 import { Button } from 'antd'，打包的时候只打包 button

    > 按需加载的实现（原 issue 已删，仓库仍在） · [📦 存档](answers/engineering/01-按需加载的实现原-issue-已删仓库仍在.md) · [原文](https://github.com/airuikun/Weekly-FE-Interview)

2. Webpack HMR 原理解析

    > Webpack HMR 原理解析 · [📦 存档](answers/engineering/02-Webpack-HMR-原理解析.md) · [原文](https://zhuanlan.zhihu.com/p/30669007)

3. Javascript 模块化

    > **推荐** Javascript 模块化编程（一）：模块的写法 · [原文](http://www.ruanyifeng.com/blog/2012/10/javascript_module.html) · ⚠️ 未存档

    > 探索 JavaScript 中的依赖管理及循环依赖 · [📦 存档](answers/engineering/03-2-探索-JavaScript-中的依赖管理及循环依赖.md) · [原文](https://juejin.cn/post/6844903552012255245)

    > 很全很全的 JavaScript 的模块讲解 · [📦 存档](answers/engineering/03-3-很全很全的-JavaScript-的模块讲解.md) · [原文](https://segmentfault.com/a/1190000012464333)

## 正则表达式

> **推荐** 正则表达式 · [📦 存档](answers/regex/00-1-正则表达式.md) · [原文](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Guide/Regular_expressions)

> JavaScript 正则进阶之路——活学妙用奇淫正则表达式 · [📦 存档](answers/regex/00-2-JavaScript-正则进阶之路——活学妙用奇淫正则表达式.md) · [原文](https://github.com/jawil/blog/issues/20)

> javascript 正则表达式 · [📦 存档](answers/regex/00-3-javascript-正则表达式.md) · [原文](https://www.cnblogs.com/rubylouvre/archive/2010/03/09/1681222.html)

## Git

待完善。

## Reference

1. Weekly-FE-Interview · [📦 存档](answers/reference/01-Weekly-FE-Interview.md) · [原文](https://github.com/airuikun/Weekly-FE-Interview)

2. 前端进阶系列 · [📦 存档](answers/reference/02-前端进阶系列.md) · [原文](https://github.com/yygmind/blog)

3. Daily-Interview-Question · [📦 存档](answers/reference/03-Daily-Interview-Question.md) · [原文](https://github.com/Advanced-Frontend/Daily-Interview-Question)

4. Jony 的博客，记录学习工作的点点滴滴 · [📦 存档](answers/reference/04-Jony-的博客记录学习工作的点点滴滴.md) · [原文](https://github.com/forthealllight/blog)

5. 【面试篇】寒冬求职季之你必须要懂的原生 JS(上) · [📦 存档](answers/reference/05-面试篇寒冬求职季之你必须要懂的原生-JS上.md) · [原文](https://juejin.cn/post/6844903815053852685)
