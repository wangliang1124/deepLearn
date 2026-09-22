# Redux 中间件是什么东西，接受几个参数（两端的柯里化函数）

> ✍️ **自撰** —— 原引用的简书文章无法抓取（简书对自动化访问返回验证页），本篇由我重写。
> 对应题目：状态管理 第 5 题
> 下面的实现和输出都在 **Node v22.22.3** 实跑验证过。

---

## 先回答「接受几个参数」

**三层，每层一个参数**：

```js
const middleware = store => next => action => { /* ... */ };
//                 ↑ 第1层    ↑ 第2层  ↑ 第3层
```

| 层 | 参数 | 什么时候被调用 | 拿到什么 |
| --- | --- | --- | --- |
| 1 | `store` | `applyMiddleware` 初始化时，**只调一次** | `{ getState, dispatch }`（阉割版 store） |
| 2 | `next` | 组装 dispatch 链时，**只调一次** | 链条中**下一个**中间件的 dispatch |
| 3 | `action` | **每次 dispatch 都调** | 本次派发的 action |

实测确认层数：

```
typeof logger            = function
typeof logger(api)       = function
typeof logger(api)(next) = function
```

三次调用都还返回函数，第四次（传 action）才真正执行。

## 为什么非得柯里化

因为**三个参数的可用时机不同**：

- `store` 在 store 创建时就有了
- `next` 要等所有中间件都拿到 store、开始串链时才能确定
- `action` 每次 dispatch 才有

如果写成 `middleware(store, next, action)`，那每次 dispatch 都要重新传 store 和 next——没法把「初始化」和「每次调用」分开。柯里化让前两层的结果被**闭包缓存**下来，运行期只剩最后一层在跑。

## 它到底怎么串起来的

`applyMiddleware` 的核心就十来行：

```js
function applyMiddleware(...middlewares) {
  return (createStore) => (reducer, preloadedState) => {
    const store = createStore(reducer, preloadedState);

    let dispatch = () => { throw new Error('构造期间不能 dispatch'); };
    const middlewareAPI = {
      getState: store.getState,
      dispatch: (...args) => dispatch(...args),   // ← 注意是包一层，不是直接传 dispatch
    };

    const chain = middlewares.map(mw => mw(middlewareAPI));  // 第 1 层：注入 store
    dispatch = compose(...chain)(store.dispatch);            // 第 2 层：串联 next

    return { ...store, dispatch };
  };
}
```

`compose` 把函数数组折叠成洋葱：

```js
const compose = (...fns) =>
  fns.length === 0 ? (x => x)
  : fns.length === 1 ? fns[0]
  : fns.reduce((a, b) => (...args) => a(b(...args)));
```

`compose(f, g, h)(x)` 等价于 `f(g(h(x)))`。所以 `applyMiddleware(thunk, logger)` 组装出来的是：

```
dispatch = thunk(api)( logger(api)( store.dispatch ) )
```

**执行顺序像洋葱**：

```
dispatch(action)
   │
   ├─ thunk  ──┐ 前置逻辑
   │           ├─ logger ──┐ 前置逻辑
   │           │           ├─ store.dispatch → reducer → 新 state
   │           │           └─ 后置逻辑
   │           └─ 后置逻辑
   └─ 返回
```

## 两个容易答错的细节

**① `middlewareAPI.dispatch` 为什么要包一层箭头函数？**

```js
dispatch: (...args) => dispatch(...args)     // ✅
dispatch: dispatch                           // ❌ 拿到的是那个会抛错的初始值
```

因为 `chain = middlewares.map(...)` 执行时，`dispatch` 还是那个抛错的占位函数。包一层让它在**真正被调用时**才去读外层变量，那时已经被赋成了组装好的完整链条。

这也是**中间件里 `store.dispatch(action)` 会从头重新走一遍整条链**的原因（而 `next(action)` 只往后走一步）。

**② `next` 和 `store.dispatch` 的区别**

| | `next(action)` | `store.dispatch(action)` |
| --- | --- | --- |
| 走向 | 交给**下一个**中间件 | 从**链条开头**重新来一遍 |
| 用途 | 正常放行 | 派发一个**新**的 action |
| 风险 | 无 | 用错会**无限递归** |

## 完整可运行示例

```js
const logger = store => next => action => {
  console.log('logger  前  state =', store.getState());
  const result = next(action);
  console.log('logger  后  state =', store.getState());
  return result;
};

const thunk = store => next => action =>
  typeof action === 'function'
    ? action(store.dispatch, store.getState)   // 函数型 action，自己决定何时 dispatch
    : next(action);

const reducer = (s = 0, a) =>
  a.type === 'INC' ? s + 1 : a.type === 'ADD' ? s + a.n : s;

const store = createStore(reducer, 0, applyMiddleware(thunk, logger));

store.dispatch({ type: 'INC' });
store.dispatch((dispatch, getState) => {
  console.log('thunk 里拿到 state =', getState());
  dispatch({ type: 'ADD', n: 10 });
});
```

实际输出：

```
1) 普通 action:
    logger  前  state = 0
    logger  后  state = 1
2) thunk 异步 action:
    thunk 里拿到 state = 1
    logger  前  state = 1
    logger  后  state = 11
3) 最终 state = 11
```

第 2 段值得看：thunk 拦下函数型 action 后**没有调 `next`**，而是执行了那个函数；函数内部再 `dispatch({type:'ADD'})`，于是**又从链条开头走了一遍**，所以 logger 打印发生在 thunk 之后。

## 中间件能做什么

| 用途 | 代表 |
| --- | --- |
| 异步流程 | `redux-thunk`、`redux-saga`、`redux-observable` |
| 日志 / 调试 | `redux-logger`、Redux DevTools |
| 持久化 | `redux-persist` |
| 错误上报 | 自己写，`try/catch` 包住 `next(action)` |
| 权限校验 | 拦截特定 action type |

## ⚠️ 这套写法已经不是现在的推荐做法

上面讲的是 Redux 的经典实现，面试仍常考，但**新项目不该再手写这些**：

- **Redux Toolkit** 的 `configureStore` 默认就装好了 thunk、序列化检查、不可变性检查和 DevTools，不用自己 `applyMiddleware`
- `createSlice` 自动生成 action creator 和 reducer，样板代码基本消失
- 轻量场景更常见的是 **Zustand**，连 store / action / reducer 这套概念都不需要

参见 [02-deep-dive.md 状态管理章](../../02-deep-dive.md) 开头的说明。
