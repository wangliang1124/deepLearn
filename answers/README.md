# answers —— 02-deep-dive 的答案存档

[02-deep-dive.md](../02-deep-dive.md) 里 93 道题引用的外部文章，抓到本地共 **149 篇**（约 2269 KB），离线可读、可全文 grep。

| 标记 | 含义 |
| --- | --- |
| 📦 存档 | 抓取自原文，仅作个人离线阅读，**版权归原作者**，未做任何修改 |
| ✍️ 自撰 | 原链已失效或无法访问，由我重新撰写（共 6 篇） |

> 抓取脚本见 [../tools/](../tools/)：`parse-deepdive.py` 解析清单，`fetch-answers.py` 走 HTTP，`render-answers.py` 走 Chrome 渲染 SPA/反爬站点。

---

## JS 深入

**1. 浅谈 instanceof 和 typeof 的实现原理**

- 📦 [浅谈 instanceof 和 typeof 的实现原理](js/01-浅谈-instanceof-和-typeof-的实现原理.md)

**2. Symbol**

- ✍️ [Symbol](js/02-Symbol.md)

**3. JavaScript 中的变量在内存中的具体存储形式**

- ✍️ [前端基础进阶：详细图解 JavaScript 内存空间](js/03-前端基础进阶详细图解-JavaScript-内存空间.md)

**4. 理解 XSS 和 CSRF 原理**

- 📦 ⭐ [前端安全系列（一）：如何防止 XSS 攻击？](js/04-1-前端安全系列一如何防止-XSS-攻击.md)
- 📦 [浅说 XSS 和 CSRF](js/04-2-浅说-XSS-和-CSRF.md)
- 📦 [Web 安全的三个攻防姿势](js/04-3-Web-安全的三个攻防姿势.md)
- 📦 [浅谈 CSRF 攻击方式](js/04-4-浅谈-CSRF-攻击方式.md)

**5. 理解 es6 class 构造以及继承的底层实现原理**

- 📦 [ES6 创建类的基本语法和继承实现原理](js/05-ES6-创建类的基本语法和继承实现原理.md)

**6. 理解 this**

- 📦 [this、apply、call、bind](js/06-this、apply、call、bind.md)

**7. 作用域和闭包**

- 📦 ⭐ [闭包详解](js/07-1-闭包详解.md)
- 📦 [作用域与词法作用域](js/07-2-作用域与词法作用域.md)

**8. try catch finally 语句执行原理**

- ✍️ [try 里面放 return，finally 还会执行吗？](js/08-try-里面放-returnfinally-还会执行吗.md)

**9. EventLoop**

- 📦 ⭐ [从 event loop 规范探究 javaScript 异步及浏览器更新渲染时机](js/09-1-从-event-loop-规范探究-javaScript-异步及浏览器更新渲染时.md)
- 📦 [JavaScript 运行机制详解：再谈 Event Loop](js/09-2-JavaScript-运行机制详解再谈-Event-Loop.md)
- 📦 [JavaScript：彻底理解同步、异步和事件循环(Event Loop)](js/09-3-JavaScript彻底理解同步、异步和事件循环Event-Loop.md)
- 📦 [深入探究 eventloop 与浏览器渲染的时序问题（原 issue 已删，仓库仍在）](js/09-4-深入探究-eventloop-与浏览器渲染的时序问题原-issue-已删仓库仍在.md)

**10. 微任务、宏任务与 EventLoop**

- 📦 ⭐ [Tasks, microtasks, queues and schedules](js/10-1-Tasks-microtasks-queues-and-schedules.md)
- 📦 [微任务、宏任务与 Event-Loop](js/10-2-微任务、宏任务与-Event-Loop.md)

**11. 如何处理跨域**

- 📦 ⭐ [不要再问我跨域的问题了](js/11-1-不要再问我跨域的问题了.md)
- 📦 [前端常见跨域解决方案](js/11-2-前端常见跨域解决方案.md)

**12. Execution Context**

- 📦 [深入理解 JavaScript 执行上下文和执行栈](js/12-深入理解-JavaScript-执行上下文和执行栈.md)

**13. 异步**

- ✍️ [异步解决方案的发展历程以及优缺点](js/13-异步解决方案的发展历程以及优缺点.md)

**14. Promise**

- 📦 ⭐ [一文彻底搞懂 promise 的实现原理](js/14-1-一文彻底搞懂-promise-的实现原理.md)
- 📦 [Promise 了解多少？](js/14-2-Promise-了解多少.md)

**15. 继承**

- 📦 ⭐ [JavaScript 深入之继承的多种方式和优缺点](js/15-1-JavaScript-深入之继承的多种方式和优缺点.md)
- 📦 [深入 JavaScript 继承原理](js/15-2-深入-JavaScript-继承原理.md)

**16. 内存泄漏**

- 📦 [4 种 JavaScript 内存泄漏浅析及如何用谷歌工具查内存泄露](js/16-4-种-JavaScript-内存泄漏浅析及如何用谷歌工具查内存泄露.md)

**17. Javascript 创建对象的几种方式**

- 📦 [JavaScript 深入之创建对象的多种方式以及优缺点](js/17-JavaScript-深入之创建对象的多种方式以及优缺点.md)


## 浏览器

**1. 浏览器工作原理**

- 📦 ⭐ [浏览器的工作原理](browser/01-1-浏览器的工作原理.md)
- ⚠️ How browsers work —— 未存档，[看原文](https://taligarsiel.com/projects/howbrowserswork1.html)
- 📦 [浏览器渲染详细过程：重绘、重排和 composite 只是冰山一角](browser/01-3-浏览器渲染详细过程重绘、重排和-composite-只是冰山一角.md)
- 📦 [你真的了解回流和重绘吗](browser/01-4-你真的了解回流和重绘吗.md)

**2. 浏览器缓存**

- 📦 ⭐ [深入理解浏览器的缓存机制](browser/02-1-深入理解浏览器的缓存机制.md)
- 📦 [浏览器缓存知识小结及应用](browser/02-2-浏览器缓存知识小结及应用.md)

**3. 视口宽高、位置与滚动高度**

- 📦 [JavaScript 视口宽高、元素位置、滚动高度、尺寸属性](browser/03-JavaScript-视口宽高、元素位置、滚动高度、尺寸属性.md)

**4. DOM 操作成本到底高在哪儿？**

- 📦 [DOM 操作成本到底高在哪儿？](browser/04-DOM-操作成本到底高在哪儿.md)

**5. 从输入 URL 到页面加载发生了什么？**

- 📦 [【原】老生常谈-从输入 url 到页面展示到底发生了什么](browser/05-原老生常谈-从输入-url-到页面展示到底发生了什么.md)


## HTTP 协议

**1. HTTPS**

- 📦 ⭐ [HTTPS 详解](http/01-1-HTTPS-详解.md)
- 📦 [HTTPS 工作原理](http/01-2-HTTPS-工作原理.md)
- ⚠️ 图文还原 HTTPS 原理，架构师必读！ —— 未存档，[看原文](https://mp.weixin.qq.com/s?__biz=MzI3NjU2ODA5Mg==&mid=2247483985&idx=1&sn=0b6de989219032d64648785946a974a4)

**2. HTTP 协议**

- 📦 ⭐ [HTTP 协议入门](http/02-1-HTTP-协议入门.md)
- 📦 [深入理解 HTTP 协议](http/02-2-深入理解-HTTP-协议.md)
- 📦 [HTTP 协议](http/02-3-HTTP-协议.md)

**3. 公钥和私钥**

- 📦 ⭐ [数字签名是什么？](http/03-1-数字签名是什么.md)

**4. http 状态码有哪些？分别代表是什么意思？**

- 📦 ⭐ [HTTP 响应状态码](http/04-1-HTTP-响应状态码.md)
- 📦 [http 状态码是什么，有什么用，在哪里查看，分别代表什么意思？](http/04-2-http-状态码是什么有什么用在哪里查看分别代表什么意思.md)

**5. HTTP 请求报文和 HTTP 响应报文**

- 📦 ⭐ [一篇文章带你详解 HTTP 协议（网络协议篇一）](http/05-1-一篇文章带你详解-HTTP-协议网络协议篇一.md)
- 📦 [HTTP 请求报文和 HTTP 响应报文](http/05-2-HTTP-请求报文和-HTTP-响应报文.md)

**6. http1.1 时如何复用 tcp 连接**

- 📦 [连接管理](http/06-2-连接管理.md)

**7. HTTP Header 详解**

- 📦 [HTTP Header 详解](http/07-HTTP-Header-详解.md)

**8. Token**

- 📦 ⭐ [彻底理解 cookie，session，token](http/08-1-彻底理解-cookiesessiontoken.md)
- 📦 [基于 Token 的身份验证](http/08-2-基于-Token-的身份验证.md)

**9. TCP 协议**

- 📦 ⭐ [通俗大白话来理解 TCP 协议的三次握手和四次分手](http/09-1-通俗大白话来理解-TCP-协议的三次握手和四次分手.md)
- 📦 [一篇文章带你熟悉 TCP/IP 协议（网络协议篇二）](http/09-2-一篇文章带你熟悉-TCPIP-协议网络协议篇二.md)


## HTML

**1. HTML5 离线缓存原理**

- 📦 ⭐ [Service Worker API](html/01-1-Service-Worker-API.md)
- 📦 [HTML5 离线缓存-manifest 简介](html/01-2-HTML5-离线缓存-manifest-简介.md)
- 📦 [HTML5 离线存储 初探](html/01-3-HTML5-离线存储-初探.md)
- 📦 [有趣的 HTML5：离线存储](html/01-4-有趣的-HTML5离线存储.md)

**2. iframe 异步加载技术及性能**

- 📦 [iframe 异步加载技术及性能](html/02-iframe-异步加载技术及性能.md)

**3. Page Visibility API**

- 📦 ⭐ [Page Visibility(页面可见性) API 介绍、微拓展](html/03-1-Page-Visibility页面可见性-API-介绍、微拓展.md)
- 📦 [HTML5 页面可见性接口应用](html/03-2-HTML5-页面可见性接口应用.md)

**4. Web Worker**

- 📦 ⭐ [使用 Web Worker](html/04-1-使用-Web-Worker.md)

**5. PostMessage**

- 📦 ⭐ [Window.postMessage()](html/05-1-Window.postMessage.md)
- 📦 [html5 API postMessage 跨域详解](html/05-2-html5-API-postMessage-跨域详解.md)

**6. requestAnimationFrame**

- ✍️ [浅析 requestAnimationFrame](html/06-浅析-requestAnimationFrame.md)

**7. HTML5 File API**

- 📦 ⭐ [通过 File API 使用 JavaScript 读取文件](html/07-1-通过-File-API-使用-JavaScript-读取文件.md)
- 📦 [基于 html5 File API 的文件操作](html/07-2-基于-html5-File-API-的文件操作.md)

**8. HTML meta 标签**

- 📦 ⭐ [常见的 meta 标签及详细解说](html/08-1-常见的-meta-标签及详细解说.md)
- 📦 [HTML-meta 标签详解](html/08-2-HTML-meta-标签详解.md)


## CSS

**1. CSS Animation**

- 📦 [使用 css 实现一个持续的动画效果](css/01-使用-css-实现一个持续的动画效果.md)

**2. CSS3 Box-sizing**

- 📦 [CSS3 box-sizing 详解](css/02-CSS3-box-sizing-详解.md)

**3. CSS 选择器及其优先级**

- 📦 [CSS 优先级计算规则](css/03-CSS-优先级计算规则.md)

**4. 居中**

- 📦 [盘点 8 种 CSS 实现垂直居中水平居中的绝对定位居中技术](css/04-1-盘点-8-种-CSS-实现垂直居中水平居中的绝对定位居中技术.md)
- 📦 [CSS 实现垂直居中 6 种方法](css/04-2-CSS-实现垂直居中-6-种方法.md)
- 📦 [CSS 垂直居中的方法](css/04-3-CSS-垂直居中的方法.md)

**5. 布局**

- 📦 ⭐ [CSS 布局解决方案（终结版）](css/05-1-CSS-布局解决方案终结版.md)
- 📦 [CSS 布局说——可能是最全的](css/05-2-CSS-布局说——可能是最全的.md)
- 📦 [CSS 常见布局方式](css/05-3-CSS-常见布局方式.md)
- 📦 [一个满屏品字布局怎么设计？](css/05-4-一个满屏品字布局怎么设计.md)

**6. 轮播图**

- 📦 [原生 JS 实现轮播图](css/06-原生-JS-实现轮播图.md)

**7. 移动端适配**

- 📦 ⭐ [移动端适配方案(上下)](css/07-1-移动端适配方案上下.md)
- ⚠️ 关于移动端适配，你必须要知道的 —— 未存档，[看原文](https://mp.weixin.qq.com/s/V3UpVZH8AWfSScIRAsr2dw)

**8. Containing Block**

- 📦 ⭐ [Layout and the containing block](css/08-1-Layout-and-the-containing-block.md)
- ⚠️ KB008: 包含块( Containing block ) —— 未存档，[看原文](http://w3help.org/zh-cn/kb/008/)

**9. BFC**

- 📦 ⭐ [前端精选文摘：BFC 神奇背后的原理](css/09-1-前端精选文摘BFC-神奇背后的原理.md)

**10. 浏览器是怎样解析 CSS 选择器的**

- 📦 [CSS 选择器从右向左的匹配规则](css/10-CSS-选择器从右向左的匹配规则.md)

**11. 元素竖向的百分比设定是相对于容器的高度吗**

- 📦 [元素竖向的百分比设定是相对于容器的高度吗](css/11-元素竖向的百分比设定是相对于容器的高度吗.md)

**12. 全屏滚动**

- 📦 ⭐ [用 ES6 写全屏滚动插件](css/12-1-用-ES6-写全屏滚动插件.md)
- 📦 [H5 全屏滑动](css/12-2-H5-全屏滑动.md)

**13. 视差滚动**

- 📦 ⭐ [小 tip: 纯 CSS 实现视差滚动效果](css/13-1-小-tip-纯-CSS-实现视差滚动效果.md)
- 📦 [视差滚动(Parallax Scrolling)效果的原理和实现](css/13-2-视差滚动Parallax-Scrolling效果的原理和实现.md)

**14. 理解 line-height**

- 📦 ⭐ [css 行高 line-height 的一些深入理解及应用](css/14-1-css-行高-line-height-的一些深入理解及应用.md)
- 📦 [我对 line-height 及 vertical-align 的一点理解](css/14-2-我对-line-height-及-vertical-align-的一点理解.md)
- 📦 [深入理解 CSS 中的行高](css/14-3-深入理解-CSS-中的行高.md)

**15. Sticky Footer**

- 📦 ⭐ [Sticky Footer, Five Ways](css/15-1-Sticky-Footer-Five-Ways.md)

**16. CSS3 Transform Perspective**

- 📦 ⭐ [perspective](css/16-1-perspective.md)

**17. PNG 图片压缩原理**

- 📦 [PNG 图片压缩原理（原 issue 已删，仓库仍在）](css/17-PNG-图片压缩原理原-issue-已删仓库仍在.md)


## React

**1. 组件之间如何通信**

- 📦 ⭐ [React 中组件通信的几种方式](react/01-1-React-中组件通信的几种方式.md)
- ⚠️ React 组件间通讯 —— 未存档，[看原文](http://taobaofed.org/blog/2016/11/17/react-components-communication/)

**2. 如何配置 React-Router**

- 📦 ⭐ [React Router 官方文档](react/02-1-React-Router-官方文档.md)
- 📦 [单页面应用路由实现原理](react/02-2-单页面应用路由实现原理.md)
- 📦 [从路由原理出发，深入阅读理解 react-router 4.0 的源码](react/02-3-从路由原理出发深入阅读理解-react-router-4.0-的源码.md)
- 📦 [路由配置（v2/v3）](react/02-4-路由配置v2v3.md)
- 📦 [React Router 使用教程（v2/v3）](react/02-5-React-Router-使用教程v2v3.md)

**3. React 事件机制**

- 📦 ⭐ [React 事件机制 - 源码概览（上）](react/03-1-React-事件机制---源码概览上.md)
- 📦 [React 事件系统分析与最佳实践](react/03-2-React-事件系统分析与最佳实践.md)

**4. React 怎么做数据的检查和变化**

- 📦 [React 高效渲染策略](react/04-React-高效渲染策略.md)

**5. 虚拟 DOM & diff 原理**

- 📦 ⭐ [深度剖析：如何实现一个 Virtual DOM 算法](react/05-1-深度剖析如何实现一个-Virtual-DOM-算法.md)
- 📦 [React 源码剖析系列 － 不可思议的 react diff](react/05-2-React-源码剖析系列-－-不可思议的-react-diff.md)

**6. React 中 keys 的作用是什么？**

- 📦 [React 技术内幕 key 带来了什么](react/06-React-技术内幕-key-带来了什么.md)

**7. WebView 和原生是如何通信**

- 📦 [IOS、Android 与 H5 通信-JsBridge 原理(总结)](react/07-1-IOS、Android-与-H5-通信-JsBridge-原理总结.md)

**8. RN 遇到的兼容性问题**

- 📦 [React+RN 开发过程中的一些问题总结](react/08-React+RN-开发过程中的一些问题总结.md)

**9. RN 如何实现一个原生的组件**

- 📦 ⭐ [React Native 封装原生 UI 组件(iOS)](react/09-1-React-Native-封装原生-UI-组件iOS.md)
- 📦 [React Native 集成到原生项目](react/09-2-React-Native-集成到原生项目.md)
- 📦 [ReactNative 之原生模块开发并发布——iOS 篇](react/09-3-ReactNative-之原生模块开发并发布——iOS-篇.md)

**10. RN 的原理，为什么可以同时在安卓和 IOS 端运行**

- 📦 [React Native for Android 原理分析与实践：实现原理](react/10-React-Native-for-Android-原理分析与实践实现原理.md)

**11. RN 如何调用原生的一些功能**

- 📦 [RN 调用原生流程总结](react/11-RN-调用原生流程总结.md)

**12. RN 和原生通信**

- ⚠️ React Native 通信机制详解 —— 未存档，[看原文](http://blog.cnbang.net/tech/2698/)
- 📦 [React Native 与 iOS 和 Android 通信](react/12-2-React-Native-与-iOS-和-Android-通信.md)
- 📦 [ReactNative 与原生代码的通信(iOS 篇)](react/12-3-ReactNative-与原生代码的通信iOS-篇.md)

**13. React 中 refs 的作用是什么？**

- 📦 [React 之 ref 详细用法](react/13-React-之-ref-详细用法.md)

**14. React 中有三种构建组件的方式**

- 📦 ⭐ [你的第一个组件](react/14-1-你的第一个组件.md)
- 📦 [React 创建组件的三种方式及其区别](react/14-2-React-创建组件的三种方式及其区别.md)

**15. 调用 setState 之后发生了什么？**

- 📦 ⭐ [你真的理解 setState 吗？](react/15-1-你真的理解-setState-吗.md)
- 📦 [React setState 详解](react/15-2-React-setState-详解.md)

**16. 为什么建议传递给 setState 的参数是一个 callback 而不是一个对象**

- 📦 [为什么建议传递给 setState 的参数是一个 callback](react/16-为什么建议传递给-setState-的参数是一个-callback.md)

**17. (在构造函数中)调用 super(props) 的目的是什么**

- 📦 [React 构造函数中为什么要写 super(props)](react/17-React-构造函数中为什么要写-superprops.md)

**18. 在 React 当中 Element 和 Component 有何区别？createElement 和 cloneElement 有什么区别？**

- 📦 ⭐ [比较与理解 React 的 Components，Elements 和 Instances](react/18-1-比较与理解-React-的-ComponentsElements-和-Insta.md)
- 📦 [React 中元素与组件的区别](react/18-2-React-中元素与组件的区别.md)

**19. Controlled Component 与 Uncontrolled Component 之间的区别是什么？**

- 📦 [React 中受控与非受控组件](react/19-React-中受控与非受控组件.md)


## 状态管理

**状态管理**

- 📦 ⭐ [Redux Toolkit](state/00-1-Redux-Toolkit.md)
- ⚠️ Zustand —— 未存档，[看原文](https://zustand.docs.pmnd.rs/)

**1. Vuex、Flux、Redux、Redux-saga、Dva、MobX**

- 📦 [Vuex、Flux、Redux、Redux-saga、Dva、MobX](state/01-Vuex、Flux、Redux、Redux-saga、Dva、MobX.md)

**2. React Hooks**

- 📦 ⭐ [内置 React Hook](state/02-1-内置-React-Hook.md)
- 📦 [用状态响应输入](state/02-2-用状态响应输入.md)

**3. Redux**

- 📦 ⭐ [完全理解 redux（从零实现一个 redux）](state/03-1-完全理解-redux从零实现一个-redux.md)
- 📦 [Redux 入坑进阶-源码解析](state/03-2-Redux-入坑进阶-源码解析.md)

**4. Redux 如何实现多个组件之间的通信，多个组件使用相同状态如何进行管理**

- 📦 ⭐ [彻底弄懂 React-Redux 组件通信](state/04-1-彻底弄懂-React-Redux-组件通信.md)
- 📦 [用 Redux 来进行组件间通讯](state/04-2-用-Redux-来进行组件间通讯.md)

**5. Redux 中间件是什么东西，接受几个参数（两端的柯里化函数）**

- 📦 [redux 中间件原理及实现](state/05-redux-中间件原理及实现.md)
- ✍️ [Redux 中间件是什么东西，接受几个参数（两端的柯里化函数）](state/05-Redux-中间件是什么东西接受几个参数.md)

**6. Redux 中异步的请求怎么处理**

- 📦 [Redux 异步流最佳实践](state/06-Redux-异步流最佳实践.md)

**7. React-Redux**

- 📦 [React-Redux 源码分析](state/07-React-Redux-源码分析.md)


## 设计模式

**1. 观察者模式**

- 📦 [观察者模式 vs 发布-订阅模式](design-pattern/01-观察者模式-vs-发布-订阅模式.md)


## 前端工程

**1. 简单实现项目代码按需加载，例如 import { Button } from 'antd'，打包的时候只打包 button**

- 📦 [按需加载的实现（原 issue 已删，仓库仍在）](engineering/01-按需加载的实现原-issue-已删仓库仍在.md)

**2. Webpack HMR 原理解析**

- 📦 [Webpack HMR 原理解析](engineering/02-Webpack-HMR-原理解析.md)

**3. Javascript 模块化**

- ⚠️ Javascript 模块化编程（一）：模块的写法 —— 未存档，[看原文](http://www.ruanyifeng.com/blog/2012/10/javascript_module.html)
- 📦 [探索 JavaScript 中的依赖管理及循环依赖](engineering/03-2-探索-JavaScript-中的依赖管理及循环依赖.md)
- 📦 [很全很全的 JavaScript 的模块讲解](engineering/03-3-很全很全的-JavaScript-的模块讲解.md)


## 正则表达式

**正则表达式**

- 📦 ⭐ [正则表达式](regex/00-1-正则表达式.md)
- 📦 [JavaScript 正则进阶之路——活学妙用奇淫正则表达式](regex/00-2-JavaScript-正则进阶之路——活学妙用奇淫正则表达式.md)
- 📦 [javascript 正则表达式](regex/00-3-javascript-正则表达式.md)


## Reference

**1. Weekly-FE-Interview**

- 📦 [Weekly-FE-Interview](reference/01-Weekly-FE-Interview.md)

**2. 前端进阶系列**

- 📦 [前端进阶系列](reference/02-前端进阶系列.md)

**3. Daily-Interview-Question**

- 📦 [Daily-Interview-Question](reference/03-Daily-Interview-Question.md)

**4. Jony 的博客，记录学习工作的点点滴滴**

- 📦 [Jony 的博客，记录学习工作的点点滴滴](reference/04-Jony-的博客记录学习工作的点点滴滴.md)

**5. 【面试篇】寒冬求职季之你必须要懂的原生 JS(上)**

- 📦 [【面试篇】寒冬求职季之你必须要懂的原生 JS(上)](reference/05-面试篇寒冬求职季之你必须要懂的原生-JS上.md)
