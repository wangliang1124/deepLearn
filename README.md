# deepLearn

前端原理笔记与手写代码 demo。48 个单文件示例，无构建、无依赖，绝大多数双击就能在浏览器里跑。

## 怎么跑

```bash
git clone git@github.com:anotherleon/deepLearn.git
cd deepLearn
open index.html          # 从导航页进入所有 demo
```

[index.html](index.html) 是分类导航页。少数 demo 需要额外条件：

| 标记 | 含义 |
| --- | --- |
| 需 server | 用到 ES module，需 `python3 -m http.server 8080` 后访问 |
| 需双端口 | 跨域三件套，需同时起 8080 与 8081 两个端口模拟不同源 |
| 需后端 | 依赖本地或远端接口，仓库内不含服务端代码 |
| 部分失效 | 引用的资源已不可用，仅供读源码 |

跨域 demo 的完整跑法：

```bash
python3 -m http.server 8080 &
python3 -m http.server 8081 &
open http://127.0.0.1:8081/cross-origin-a.html
```

## 笔记

| 文档 | 内容 |
| --- | --- |
| [01 手写代码](01-handwritten-code.md) | 20+ 道手写实现题的完整题解 |
| [02 深入学习](02-deep-dive.md) | JS / 浏览器 / HTTP / HTML / CSS / React / 工程化 问答 |
| [状态管理对比](state-management-comparison.md) | Flux → Redux → Vuex → MobX 横向对比 |
| [React-Redux 原理](react-redux-internals.md) | Provider 与 connect 源码剖析 |
| [原生 / RN / H5 通信](native-rn-h5-bridge.md) | iOS 与 Android 双向桥接方案 |
| [搞懂 Safe Area](safe-area.md) | 刘海屏安全区与横竖屏适配 |

## Demo

### 手写实现

| Demo | 说明 |
| --- | --- |
| [handwritten-new](handwritten-new.html) | 实现 new 操作符 |
| [handwritten-bind](handwritten-bind.html) | 实现 Function.prototype.bind |
| [handwritten-call-apply](handwritten-call-apply.html) | 实现 call 与 apply |
| [handwritten-object-create](handwritten-object-create.html) | 实现 Object.create |
| [handwritten-currying](handwritten-currying.html) | 函数柯里化 |
| [handwritten-promise](handwritten-promise.html) | 符合 Promise/A+ 的完整实现 |
| [handwritten-async](handwritten-async.html) | 用 Generator 模拟 async/await |
| [handwritten-deep-clone](handwritten-deep-clone.html) | 深拷贝，处理循环引用 |
| [handwritten-index-of](handwritten-index-of.html) | 实现 Array.prototype.indexOf |
| [handwritten-instanceof](handwritten-instanceof.html) | 沿原型链实现 instanceof |
| [handwritten-json-stringify-parse](handwritten-json-stringify-parse.html) | 实现 JSON.stringify 与 JSON.parse |
| [handwritten-throttle](handwritten-throttle.html) | 节流，含时间戳与定时器两版 |
| [handwritten-debounce](handwritten-debounce.html) | 防抖，含立即执行选项 |
| [ajax-wrapper](ajax-wrapper.html) | 基于 Promise 封装 XHR · 需后端 |
| [event-utils](event-utils.html) | 跨浏览器事件绑定与解绑 |
| [event-emitter-test](event-emitter-test.html) | 发布订阅，配套 [event-emitter.js](event-emitter.js) · 需 server |

### 浏览器与网络

| Demo | 说明 |
| --- | --- |
| [browser-rendering](browser-rendering.html) | 对比 4 种批量插入 2000 个节点的方式 |
| [jsonp](jsonp.html) | JSONP 跨域原理与实现 · 需后端 |
| [cross-origin-a](cross-origin-a.html) | 跨域入口：location.hash 与 window.name · 需双端口 |
| [cross-origin-b](cross-origin-b.html) | 跨域中间层，被 a 以 iframe 引入 · 需双端口 |
| [cross-origin-c](cross-origin-c.html) | 跨域同域代理页，回传数据给 a · 需双端口 |
| [cookie-as-localstorage](cookie-as-localstorage.html) | 用 cookie 模拟 localStorage API |
| [hash-router](hash-router.html) | hash 模式前端路由原理 |
| [async-iframe](async-iframe.html) | 动态创建 iframe，不阻塞 load 事件 |
| [memory-leak-closure](memory-leak-closure.html) | 闭包引用导致的经典泄漏案例 |
| [memory-leak-detection](memory-leak-detection.html) | 点按钮观察内存增长，配合 DevTools |

### 框架与语言原理

| Demo | 说明 |
| --- | --- |
| [es6-inheritance](es6-inheritance.html) | class extends 编译后的原型结构 |
| [proxy](proxy.html) | Proxy 的 get / set / apply / construct 拦截 |
| [observable-array](observable-array.html) | 可监听数组，拦截 push / pop 变更 |
| [vue-two-way-binding](vue-two-way-binding.html) | defineProperty 实现 MVVM 双向绑定 |
| [react-router-internals](react-router-internals.html) | 用 pushState 实现最简 React Router |
| [redux-implementation](redux-implementation.html) | 从零实现 createStore、combineReducers 与中间件 |

### 算法与编程题

| Demo | 说明 |
| --- | --- |
| [sort-algorithms.js](sort-algorithms.js) | 十大经典排序算法 |
| [data-structures.js](data-structures.js) | 栈、队列、链表、哈希表、二叉搜索树、图 |
| [async-execution-order.js](async-execution-order.js) | 宏任务与微任务的执行顺序 |
| [shuffle](shuffle.html) | Fisher-Yates 洗牌算法 |
| [permutation](permutation.html) | 全排列 |
| [deep-traverse-and-modify](deep-traverse-and-modify.html) | 深度遍历并就地修改嵌套结构 |
| [parse-url-params](parse-url-params.html) | 解析 URL query 参数 |
| [thousands-separator-template-engine](thousands-separator-template-engine.html) | 千位分隔符与极简模版引擎 |
| [exercises-1](exercises-1.html) | 综合编程题（一） |
| [exercises-2](exercises-2.html) | 综合编程题（二） |

### DOM 与交互

| Demo | 说明 |
| --- | --- |
| [drag](drag.html) | 原生拖拽，含边界处理 |
| [popover](popover.html) | 文本溢出时的气泡提示 |
| [lazy-load](lazy-load.html) | 图片懒加载 · 部分失效（占位图 `default.jpg` 缺失） |
| [lazy-man](lazy-man.html) | LazyMan 链式调用与任务队列 |
| [get-xpath](get-xpath.html) | 计算元素的 XPath |
| [serialize-form](serialize-form.html) | 表单序列化为查询串 |
