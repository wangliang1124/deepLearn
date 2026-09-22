# React Hooks 面试题

选题来自 [pro-collection/interview-question](https://github.com/pro-collection/interview-question)，每题保留了原始 issue 链接和公司标签。答案是重写的，其中所有可验证的行为都在 React 18.3.1 里实际跑过，结论写在对应小节里。

> ▶ 运行 demo：[react-hooks.html](react-hooks.html) —— 8 个交互演示，链表结构、依赖比较、闭包陷阱等都能自己点出来看

关于版本：React 19 起不再提供 UMD 构建，所以免构建的 CDN demo 用的是 18.3.1。涉及 19 的变化在文中单独标注，依据是 [react.dev](https://react.dev/) 的 react@19.3 文档。

## 目录

- [一、基础与 API](#一基础与-api)
- [二、规则与陷阱](#二规则与陷阱)
- [三、实现原理](#三实现原理)
- [四、工程实践](#四工程实践)

## 一、基础与 API

### 1. Hooks 有哪些？

> 公司：美团 · [issues/302](https://github.com/pro-collection/interview-question/issues/302)

按官方文档的分类（react@19.3）：

| 分类 | Hooks |
| --- | --- |
| State | `useState`、`useReducer` |
| Context | `useContext` |
| Ref | `useRef`、`useImperativeHandle` |
| Effect | `useEffect`、`useLayoutEffect`、`useInsertionEffect`、`useEffectEvent` |
| Performance | `useMemo`、`useCallback`、`useTransition`、`useDeferredValue` |
| 其他 | `useDebugValue`、`useId`、`useSyncExternalStore`、`useActionState` |

另外还有几个不在上表但常被问到的：`useOptimistic`（乐观更新）、`useFormStatus`（来自 `react-dom`，读取表单提交状态），以及 `use`（读取 Promise 或 Context，严格说它不是 Hook，因为它可以在条件语句里调用）。

日常真正高频的只有前 8 个：`useState`、`useEffect`、`useContext`、`useReducer`、`useCallback`、`useMemo`、`useRef`、`useLayoutEffect`。答这题时先给分类框架，再说自己常用哪些、解决什么问题，比背全表有用。

### 2. 类组件的生命周期映射到哪些 Hooks？

> 公司：腾讯 · [issues/627](https://github.com/pro-collection/interview-question/issues/627)

| 类组件 | 函数组件 |
| --- | --- |
| `constructor` | `useState` 的初始值参数 |
| `componentDidMount` | `useEffect(fn, [])` |
| `componentDidUpdate` | `useEffect(fn, [deps])` |
| `componentWillUnmount` | `useEffect` 返回的清理函数 |
| `shouldComponentUpdate` | `React.memo` + `useMemo`/`useCallback` |
| `getSnapshotBeforeUpdate` | `useLayoutEffect` |
| `componentDidCatch` / `getDerivedStateFromError` | **没有对应 Hook**，错误边界仍须用 class 组件 |

最后一行是这题的考点：错误边界至今只能用 class 实现（或用 `react-error-boundary` 这类封装库）。

另外这张表是「近似」而非等价。`componentDidMount` 与 `useEffect(fn, [])` 的差别见第 3 题。

### 3. `useEffect(fn, [])` 和 `componentDidMount` 有什么区别？

> 公司：TOP100 互联网 · [issues/774](https://github.com/pro-collection/interview-question/issues/774)

三个区别：

**执行时机不同。** `componentDidMount` 在 DOM 变更后、浏览器绘制前**同步**执行；`useEffect` 在绘制**之后异步**执行。所以在 `useEffect` 里改布局，用户可能先看到一帧旧画面。真正等价于 `componentDidMount` 时机的是 `useLayoutEffect`。

**闭包语义不同。** class 里 `this.state` 永远读到最新值；`useEffect(fn, [])` 的回调闭包住首次渲染的变量，后续更新读不到。这就是闭包陷阱（第 14 题）。

**严格模式下的行为不同。** React 18 起，开发环境的 `StrictMode` 会故意把 effect 执行「挂载 → 卸载 → 再挂载」一遍，用来暴露没写清理函数的副作用。`componentDidMount` 不会这样。所以看到 effect 跑两次不要慌，那是设计如此，生产环境只跑一次。

### 4. `useLayoutEffect` 和 `useEffect` 有什么区别？

> 公司：腾讯 · [issues/591](https://github.com/pro-collection/interview-question/issues/591)

> ▶ demo 第 5 节可以看到方块移动的差别

区别只在时机：

- `useLayoutEffect` 在 DOM 变更后、浏览器**绘制前同步**执行，会阻塞绘制
- `useEffect` 在**绘制后异步**执行，不阻塞

实测两者与 render 的先后（React 18.3.1）：

```text
render → useLayoutEffect → useEffect
```

**怎么选**：默认用 `useEffect`。只在需要「绘制前读取布局并立刻修正」时才用 `useLayoutEffect`，典型场景是读取元素尺寸后调整位置（tooltip 定位）、或同步滚动位置——用 `useEffect` 做这些会闪一下。

代价是 `useLayoutEffect` 同步阻塞绘制，里面放重逻辑会拖慢首屏。另外它在服务端渲染时不执行，React 会告警。

### 5. `memo` 和 `useMemo` 有什么区别？

> [issues/349](https://github.com/pro-collection/interview-question/issues/349)

> ▶ demo 第 6 节有渲染次数计数器

不是替代关系，作用对象不同：

| | `React.memo` | `useMemo` |
| --- | --- | --- |
| 是什么 | 高阶组件 | Hook |
| 缓存什么 | 组件的**渲染结果** | 一个**值** |
| 判断依据 | 浅比较 props | 依赖数组 |
| 用在哪 | 包裹组件定义 | 组件内部 |

`memo` 解决的是「父组件重渲染，但传给我的 props 没变，我不该跟着重渲染」；`useMemo` 解决的是「这个计算很贵，依赖没变就别重算」。

两者常配合使用：给 `memo` 包裹的子组件传对象或函数时，必须用 `useMemo`/`useCallback` 稳住引用，否则每次渲染都是新引用，浅比较必然失败，`memo` 白加。

```jsx
const Child = memo(function Child({ config, onPick }) { /* ... */ });

function Parent() {
    // 不加 useMemo/useCallback，下面两个每次渲染都是新引用，memo 完全失效
    const config = useMemo(() => ({ theme: "dark" }), []);
    const onPick = useCallback(id => console.log(id), []);
    return <Child config={config} onPick={onPick} />;
}
```

补一句现状：React Compiler 的目标就是自动完成这类记忆化，普及后手写 `useMemo`/`useCallback` 的场合会明显减少。

### 6. `useMemo` / `useCallback` 能接 async 函数吗？

> [issues/1068](https://github.com/pro-collection/interview-question/issues/1068) · [issues/1069](https://github.com/pro-collection/interview-question/issues/1069)

> ▶ demo 第 7 节会打印出返回值类型

**`useCallback` 可以**，`useMemo` 不行——原因是两者缓存的东西不同。

`useCallback` 缓存的是函数本身，你传 async 函数进去，拿到的就是那个 async 函数，什么时候调用由你决定：

```jsx
const submit = useCallback(async () => {
    await fetch("/api/save", { method: "POST" });
}, []);

<button onClick={submit}>保存</button>
```

`useMemo` 缓存的是**工厂函数的返回值**。工厂是 async 的，返回值就是 Promise，不是你要的数据：

```jsx
// 错误：data 是一个 Promise
const data = useMemo(async () => {
    const res = await fetch("/api/list");
    return res.json();
}, []);
```

实测（React 18.3.1）：`useMemo(async () => 42, [])` 的结果 `instanceof Promise` 为 `true`，`typeof` 是 `"object"`。拿去渲染会得到 `[object Promise]`，参与数值计算会得到 `NaN`。

正确做法是用 `useEffect` 发起请求、用 state 承接结果，并处理组件卸载：

```jsx
const [data, setData] = useState(null);

useEffect(() => {
    let alive = true;
    (async () => {
        const res = await fetch("/api/list");
        const json = await res.json();
        if (alive) setData(json); // 卸载后不要再 setState
    })();
    return () => { alive = false; };
}, []);
```

实际项目里这类逻辑交给 React Query / SWR，不用自己写。

### 7. 介绍一下 `useReducer`

> 公司：滴滴 · [issues/747](https://github.com/pro-collection/interview-question/issues/747)

`useReducer` 是 `useState` 的替代方案，把「怎么改状态」的逻辑从组件里抽到一个纯函数里：

```jsx
function reducer(state, action) {
    switch (action.type) {
        case "increment": return { count: state.count + 1 };
        case "reset": return { count: action.payload };
        default: throw new Error("unknown action: " + action.type);
    }
}

function Counter() {
    const [state, dispatch] = useReducer(reducer, { count: 0 });
    return (
        <>
            <span>{state.count}</span>
            <button onClick={() => dispatch({ type: "increment" })}>+1</button>
            <button onClick={() => dispatch({ type: "reset", payload: 0 })}>重置</button>
        </>
    );
}
```

**什么时候用它而不是 `useState`**：

- 状态是有多个字段的对象，且字段之间有联动
- 下一个状态依赖前一个状态的复杂计算
- 同一份状态有多种不同的更新路径（表单的校验/提交/重置）
- 需要把更新逻辑单独测试——`reducer` 是纯函数，脱离组件就能测
- 需要把 `dispatch` 传给深层子组件：`dispatch` 的引用是稳定的，不像自己包的回调那样需要 `useCallback`

源码层面两者是同一套东西：`useState` 就是内置了一个固定 reducer 的 `useReducer`（见第 16 题）。

### 8. `createContext` 和 `useContext` 有什么区别？

> 公司：百度 · [issues/370](https://github.com/pro-collection/interview-question/issues/370)

一个创建，一个消费，不是同一层的东西：

- `createContext(defaultValue)` 在组件外调用，创建一个 context 对象，返回 `{ Provider, Consumer }`
- `useContext(context)` 在组件内调用，读取最近一个 `Provider` 提供的值

```jsx
const ThemeContext = createContext("light"); // 创建，组件外

function App() {
    return (
        <ThemeContext.Provider value="dark">
            <Toolbar />
        </ThemeContext.Provider>
    );
}

function Toolbar() {
    const theme = useContext(ThemeContext); // 消费，组件内
    return <div className={theme} />;
}
```

两个容易被追问的点：

**`defaultValue` 什么时候生效？** 只在组件**往上找不到任何 `Provider`** 时生效。注意不是「`Provider` 的 value 为 undefined 时」——那种情况下读到的就是 `undefined`。

**React 19 的简化**：可以直接用 `<ThemeContext>` 代替 `<ThemeContext.Provider>`。

### 9. 如何合理使用 `useContext`，避免整棵树重渲染？

> 公司：腾讯 · [issues/465](https://github.com/pro-collection/interview-question/issues/465)

问题根源：`Provider` 的 `value` 一变，**所有**调用了 `useContext` 的后代组件都会重渲染，且 `memo` 挡不住——因为 context 的更新不走 props。

四个办法：

**1. 稳住 value 的引用。** 最常见的错误是把对象字面量直接写在 `value` 上，父组件每次渲染都产生新引用，等于每次都通知全体订阅者：

```jsx
function Bad({ children }) {
    const [user, setUser] = useState(null);
    // 每次渲染都是新对象，等于每次都通知全体订阅者
    return <Ctx.Provider value={{ user, setUser }}>{children}</Ctx.Provider>;
}

function Good({ children }) {
    const [user, setUser] = useState(null);
    // setUser 的引用本身是稳定的，所以只需把 user 放进依赖
    const value = useMemo(() => ({ user, setUser }), [user]);
    return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}
```

**2. 按更新频率拆分 context。** 把变化频繁的和几乎不变的分开，比如 `ThemeContext`（几乎不变）和 `MousePositionContext`（高频变化）各自一个，别塞进同一个对象。

**3. 把 state 和 dispatch 拆成两个 context。** 只需要触发更新、不关心当前值的组件，订阅 dispatch 那个就不会被 state 变化带着重渲染。`dispatch` 的引用天然稳定。

```jsx
<StateCtx.Provider value={state}>
    <DispatchCtx.Provider value={dispatch}>{children}</DispatchCtx.Provider>
</StateCtx.Provider>
```

**4. 把消费点下推。** 只让真正用到值的那个小组件调 `useContext`，别在顶层读出来再往下传。

如果这些都不够（比如一个大 store 里字段很多、订阅者各只关心一部分），就该换成 Zustand / Jotai 这类支持**选择性订阅**的方案。context 的设计目标是「传递不常变的依赖」，不是通用状态管理。

### 10. `useRef`、`ref`、`forwardRef` 的区别？

> [issues/178](https://github.com/pro-collection/interview-question/issues/178)

三个不同层面的东西：

- **`useRef`** 是 Hook，创建一个跨渲染保持同一引用的可变容器 `{ current }`
- **`ref`** 是 JSX 上的特殊属性，把 DOM 节点或 class 实例写进你给的容器
- **`forwardRef`** 是高阶组件，解决「函数组件默认不接收 ref」的问题，把外部传入的 ref 转发给内部某个节点

```jsx
// React 18 及以前
const Input = forwardRef(function Input(props, ref) {
    return <input ref={ref} {...props} />;
});

function Form() {
    const inputRef = useRef(null);
    useEffect(() => inputRef.current.focus(), []);
    return <Input ref={inputRef} />;
}
```

**React 19 的变化**（这题现在的考点）：`ref` 可以像普通 prop 一样传给函数组件，不再需要 `forwardRef`。官方文档原话是「In React 19, `forwardRef` is no longer necessary. Pass `ref` as a prop instead」，并已标记 Deprecated、预告未来移除：

```jsx
// React 19
function Input({ ref, ...props }) {
    return <input ref={ref} {...props} />;
}
```

## 二、规则与陷阱

### 11. 为什么 Hooks 必须在顶层调用？能写在 `if` 里吗？

> 公司：腾讯 · [issues/807](https://github.com/pro-collection/interview-question/issues/807) · [issues/257](https://github.com/pro-collection/interview-question/issues/257)

> ▶ demo 第 1 节把链表打出来了，一看就明白

**能写，但会坏。** 语法上没人拦着，`eslint-plugin-react-hooks` 会报错，运行时则要么报 "Rendered fewer hooks than expected"，要么更糟——不报错但状态串位。

根本原因是 **React 靠调用顺序（位置）而不是名字来识别 hook**。同一个组件里的 hooks 以**单向链表**挂在 fiber 的 `memoizedState` 上，每次渲染从头按顺序取。

实测证据（React 18.3.1，demo 第 1 节）：一个按顺序调用 9 个 hook 的组件，其 `fiber.memoizedState` 链表正好 9 个节点，顺序与源码里的调用顺序逐一对应；`useState`/`useReducer` 的节点带 update queue，`useRef`/`useMemo`/`useCallback` 没有。

```jsx
// 错误
function Bad({ cond }) {
    if (cond) {
        const [a, setA] = useState(0); // cond 变化时，后面所有 hook 的位置全部错位
    }
    const [b, setB] = useState(1);
}
```

`cond` 为 true 时 `b` 是链表第 2 个节点，为 false 时变成第 1 个——于是 `b` 会读到原本属于 `a` 的状态。这类 bug 不会崩，只会让状态莫名其妙串台，极难排查。

**正确写法是把条件放进 hook 里，而不是把 hook 放进条件里：**

```jsx
function Good({ cond }) {
    const [a, setA] = useState(0);
    const [b, setB] = useState(1);
    useEffect(() => {
        if (!cond) return; // 条件判断放在回调内部
        doSomething();
    }, [cond]);
}
```

如果某段逻辑确实只在某条件下需要，就把它抽成一个子组件，用条件渲染这个子组件——组件级别的条件是允许的。

顺带一提：`use()` 是个例外，它被设计成可以在条件语句里调用，所以官方不把它算作 Hook。

### 12. `useEffect` 的第二个参数，依赖是怎么比较的？

> [issues/179](https://github.com/pro-collection/interview-question/issues/179)

> ▶ demo 第 2 节用 `NaN` 和 `±0` 反推出了答案

**逐项浅比较，用 `Object.is`。** 长度相同的前提下，逐个下标比对，任意一项不相等就重跑 effect。

这不是从文档抄来的，可以自己测出来：`Object.is` 和 `===` 只在两处结论相反——

| 用例 | `===` | `Object.is` |
| --- | --- | --- |
| `NaN` vs `NaN` | `false`（判定为变化） | `true`（判定为未变） |
| `+0` vs `-0` | `true`（判定为未变） | `false`（判定为变化） |

实测结果（React 18.3.1）：依赖从 `1 → NaN → NaN`，effect 只跑了 2 次（若用 `===` 会跑 3 次）；依赖从 `0 → -0`，effect 跑了 2 次（若用 `===` 只会跑 1 次）。两个用例都指向 `Object.is`。

**实践含义**（这才是面试真正想问的）：

- 依赖里放对象、数组、函数字面量，每次渲染都是新引用，`Object.is` 判定为变化，effect 每次都重跑。要么用 `useMemo`/`useCallback` 稳住，要么只依赖其中用到的原始值（`[user.id]` 而不是 `[user]`）
- **依赖数组长度不能变**，React 会告警。别写 `cond ? [a] : [a, b]`
- 依赖是浅比较，深层字段改了但引用没变，effect 不会重跑

三种依赖写法的区别：

```jsx
useEffect(fn);         // 不传：每次渲染后都跑
useEffect(fn, []);     // 空数组：只在挂载后跑一次
useEffect(fn, [a, b]); // 有依赖：a 或 b 变化时跑
```

### 13. `useState` 存数组时，直接 `push` / `pop` / `splice` 会触发渲染吗？

> 公司：快手 · [issues/464](https://github.com/pro-collection/interview-question/issues/464)

> ▶ demo 第 4 节能看到界面与数据脱节的全过程

**不会。** 原因是 `setState` 收到新值后会用 `Object.is` 和当前值比较，相等就跳过这次更新（bail out）。`push` 是原地修改，数组引用没变，所以 `setArr(arr)` 等于告诉 React「没变」。

实测（React 18.3.1）：初始 `[1,2,3]`，连续 3 次「`arr.push(...)` 然后 `setArr(arr)`」后，组件渲染次数仍然是 **1**，界面上显示的还是 `[1, 2, 3]`；此时用别的方式强制重渲染，数组立刻显示为 `[1, 2, 3, 4, 5, 6]`——说明数据早就改了，只是 React 跳过了更新。

这个「界面与数据脱节」比直接报错更危险：状态是错的，但你看不出来。

**正确写法：永远产生新引用。**

```jsx
setArr(prev => [...prev, item]);                     // 追加
setArr(prev => prev.filter(x => x.id !== id));       // 删除
setArr(prev => prev.map(x => x.id === id ? next : x)); // 更新某项
setArr(prev => [...prev].sort(cmp));                  // 排序（sort 会原地改，先复制）
```

注意 `sort`、`reverse`、`splice` 都是原地方法，必须先复制。ES2023 起有 `toSorted`、`toReversed`、`toSpliced`、`with`，直接返回新数组，更省心。

对象同理，`state.a = 1` 不会触发渲染，要写 `setState(prev => ({ ...prev, a: 1 }))`。嵌套很深时用 Immer（Redux Toolkit 内置的就是它）。

### 14. 什么是闭包陷阱，怎么解决？

> ▶ demo 第 3 节可以看到采样值卡在初始值

函数组件每次渲染都是一次独立的函数调用，里面的变量都是那一次渲染的快照。如果一个回调被保存到了渲染之外（定时器、事件监听、异步回调），它闭包住的就是创建时那一次渲染的变量，之后永远读不到新值。

```jsx
function Counter() {
    const [count, setCount] = useState(0);
    useEffect(() => {
        const id = setInterval(() => {
            console.log(count); // 永远打印 0
            setCount(count + 1); // 永远是 0 + 1
        }, 1000);
        return () => clearInterval(id);
    }, []); // 空依赖，回调只创建一次
}
```

实测（React 18.3.1）：在依赖为 `[]` 的 effect 里用 `setInterval` 采样 `count`，采到的全是 `0`，而组件的真实 state 已经涨到 `3`。

**三种解法，按优先级：**

**1. 函数式更新**（最优）。压根不读外部变量，就没有闭包问题：

```jsx
setCount(c => c + 1);
```

**2. 把值加进依赖数组**。effect 会重建，闭包也跟着更新。代价是定时器会被反复清除重建：

```jsx
useEffect(() => {
    const id = setInterval(() => setCount(count + 1), 1000);
    return () => clearInterval(id);
}, [count]);
```

**3. 用 ref 当逃生通道**。ref 的 `.current` 始终指向最新值：

```jsx
const countRef = useRef(count);
countRef.current = count;
// 回调里读 countRef.current
```

ref 这招能用但不该是首选——它绕开了 React 的数据流，读到的值不参与渲染时机。React 正在推进的 `useEffectEvent` 就是为这类「要读最新值但不想进依赖」的场景设计的。

## 三、实现原理

### 15. Hooks 的实现原理是什么？

> 公司：百度 / PDD · [issues/285](https://github.com/pro-collection/interview-question/issues/285) · [issues/504](https://github.com/pro-collection/interview-question/issues/504)

> ▶ demo 第 1 节直接把链表结构打出来了

**核心：hooks 的状态不存在组件里，而是存在对应的 fiber 节点上，以单向链表组织，按调用顺序索引。**

三个关键点：

**1. 存储位置。** 每个函数组件对应一个 fiber 节点，fiber 的 `memoizedState` 字段指向该组件的**第一个 hook**。每个 hook 节点大致长这样：

```js
const hook = {
    memoizedState: null, // 该 hook 自己的状态
    baseState: null,
    queue: null,         // 更新队列（useState/useReducer 才有）
    baseQueue: null,
    next: null,          // 指向下一个 hook，构成链表
};
```

注意 `memoizedState` 这个名字在两个层面出现，含义不同：fiber 上的 `memoizedState` 指向 hook 链表头；hook 节点上的 `memoizedState` 存的是这个 hook 自己的值。这是「hooks 和 memoizedState 是什么关系」那题的答案。

不同 hook 在 `memoizedState` 里存的东西不一样：

| Hook | 它的 `memoizedState` |
| --- | --- |
| `useState` / `useReducer` | 当前 state，另有 `queue` 存待处理的更新 |
| `useRef` | `{ current }` 对象 |
| `useMemo` | `[计算结果, deps]` |
| `useCallback` | `[回调函数, deps]` |
| `useEffect` | effect 对象 `{ tag, create, destroy, deps, next }` |

**2. 按顺序索引。** 渲染时 React 用一个模块级的指针（`workInProgressHook`）沿链表往下走，第 N 次调用 hook 就取第 N 个节点。这就是为什么顺序不能变（第 11 题）。

**3. 挂载与更新走不同实现。** React 内部维护一个 `ReactCurrentDispatcher`，首次渲染时指向 `HooksDispatcherOnMount`（负责创建链表节点），更新时指向 `HooksDispatcherOnUpdate`（负责沿链表取节点、结算更新队列）。所以同一个 `useState` 调用，首次和后续走的是两套代码。

这个 dispatcher 机制也解释了「为什么不能在组件外调用 Hook」：组件外的 dispatcher 是 null 或抛错版本，会直接报 "Invalid hook call"。

### 16. `useState` 是如何实现的？

> 公司：TOP100 互联网 · [issues/818](https://github.com/pro-collection/interview-question/issues/818) · [issues/290](https://github.com/pro-collection/interview-question/issues/290)

`useState` 本质是**内置了固定 reducer 的 `useReducer`**。React 源码里这个 reducer 叫 `basicStateReducer`：

```js
function basicStateReducer(state, action) {
    // action 是函数就调用它（函数式更新），否则直接当新状态
    return typeof action === "function" ? action(state) : action;
}
```

这解释了 `setCount(5)` 和 `setCount(c => c + 1)` 为什么都能用。

**挂载阶段**做三件事：创建 hook 节点、把初始值写进 `memoizedState`、创建更新队列并返回 `[state, dispatch]`：

```js
function mountState(initialState) {
    const hook = mountWorkInProgressHook(); // 创建节点并挂到链表尾部
    if (typeof initialState === "function") {
        initialState = initialState(); // 惰性初始化：函数形式只在挂载时执行一次
    }
    hook.memoizedState = hook.baseState = initialState;
    const queue = { pending: null, lastRenderedReducer: basicStateReducer, /* ... */ };
    hook.queue = queue;
    const dispatch = dispatchSetState.bind(null, currentlyRenderingFiber, queue);
    return [hook.memoizedState, dispatch];
}
```

`dispatch` 被 `bind` 住了 fiber 和 queue，所以它的引用在组件整个生命周期里是**稳定的**——这也是为什么 `setState` 函数不需要写进依赖数组。

**更新阶段**：沿链表取到当前 hook，把待处理的更新队列依次套用 reducer 算出新 state，和旧 state 比较（`Object.is`），不同则标记 fiber 需要更新：

```js
// 简化示意
function updateState() {
    const hook = updateWorkInProgressHook();
    let newState = hook.baseState;
    let update = hook.queue.pending;
    do {
        newState = basicStateReducer(newState, update.action);
        update = update.next;
    } while (update !== hook.queue.pending);

    if (!Object.is(newState, hook.memoizedState)) {
        markWorkInProgressReceivedUpdate(); // 需要重渲染
    }
    hook.memoizedState = newState;
    return [newState, hook.queue.dispatch];
}
```

最后那个 `Object.is` 比较就是第 13 题的答案——引用没变就不重渲染。

一个极简的心智模型（不是真实实现，但能说明按顺序索引这件事）：

```js
let hooks = [];
let cursor = 0;

function useState(initial) {
    const i = cursor++;
    hooks[i] = hooks[i] === undefined ? initial : hooks[i];
    const setState = v => {
        hooks[i] = typeof v === "function" ? v(hooks[i]) : v;
        render(); // 重新渲染，cursor 归零
    };
    return [hooks[i], setState];
}
```

真实实现用链表而非数组，且挂在 fiber 上而非模块作用域——否则多个组件实例会互相覆盖。

### 17. `useRef` 是如何实现的？

> 公司：TOP100 互联网 · [issues/813](https://github.com/pro-collection/interview-question/issues/813)

简单得有点反直觉：就是把一个 `{ current }` 对象存进 hook 的 `memoizedState`，之后每次渲染原样返回同一个对象。

```js
function mountRef(initialValue) {
    const hook = mountWorkInProgressHook();
    const ref = { current: initialValue };
    hook.memoizedState = ref;
    return ref;
}

function updateRef() {
    const hook = updateWorkInProgressHook();
    return hook.memoizedState; // 原样返回，不做任何比较
}
```

实测印证（demo 第 1 节）：`useRef` 对应的 hook 节点，其 `memoizedState` 就是一个只有 `current` 键的对象，且没有 `queue`——没有更新队列，自然也就没有触发渲染的途径。

由此可得三个结论：

- **引用稳定**：整个生命周期里是同一个对象，可以安全地放进依赖数组（放了也等于没放）
- **改 `.current` 不触发渲染**：没有 queue、不走 dispatch，React 根本不知道你改了
- **读写都是同步的**：不像 state 那样有批处理和异步更新

所以它适合存「需要跨渲染保持、但不需要反映到界面上」的东西：DOM 节点、定时器 id、上一次的值、是否首次渲染的标记。反过来，凡是变化后需要更新界面的，就必须用 state。

### 18. `useEffect` 的工作原理是什么？

> 公司：滴滴 · [issues/748](https://github.com/pro-collection/interview-question/issues/748)

分三步看：

**1. 渲染阶段：登记，不执行。** 调用 `useEffect` 时，React 只是创建一个 effect 对象存进 hook 链表，并把它挂到 fiber 的 effect 链上，同时给 fiber 打上「有副作用要处理」的标记。effect 对象形如：

```js
{ tag, create, destroy, deps, next }
// create  = 你传的回调
// destroy = 上次 create 返回的清理函数
// deps    = 依赖数组
```

**2. commit 阶段：比较依赖，决定要不要跑。** React 把新旧 `deps` 逐项 `Object.is` 比较（第 12 题）。相等就跳过；不相等则先调用上一次的 `destroy`，再调用新的 `create`，并把它的返回值存为下一次的 `destroy`。

**3. 执行时机：绘制之后异步。** `useEffect` 的回调被放进一个在绘制后调度的任务里执行，所以不阻塞渲染。`useLayoutEffect` 则在 commit 阶段同步执行，先于绘制（第 4 题）。

几个由此推出的要点：

- **清理函数在两种时机被调用**：组件卸载时，以及下一次 effect 执行前。后者常被忽略，导致订阅叠加、请求竞态
- **返回值必须是函数或 undefined**。所以不能直接把 async 函数传给 `useEffect`——async 函数返回 Promise，React 会告警：

```jsx
// 错误：async 函数返回 Promise，React 会把它当成清理函数并告警
useEffect(async () => {
    await fetch("/api/list");
}, []);

// 正确：在内部定义并立即调用
useEffect(() => {
    (async () => {
        await fetch("/api/list");
    })();
}, []);
```

- **StrictMode 下开发环境会执行两遍**（挂载 → 卸载 → 再挂载），这是故意的，用来暴露缺失的清理逻辑

## 四、工程实践

### 19. 如何给 React Hooks 写单测？

> 公司：TOP100 互联网 · [issues/775](https://github.com/pro-collection/interview-question/issues/775)

hooks 不能脱离组件调用，所以测试的思路是「把它放进一个宿主里跑」。

**测自定义 Hook**：用 `@testing-library/react` 的 `renderHook`（React 18 起已合并进主包，不再需要单独的 `react-hooks-testing-library`）。

```jsx
import { renderHook, act } from "@testing-library/react";

function useCounter(initial = 0) {
    const [count, setCount] = useState(initial);
    const inc = useCallback(() => setCount(c => c + 1), []);
    return { count, inc };
}

test("inc 会让 count 加一", () => {
    const { result } = renderHook(() => useCounter(5));
    expect(result.current.count).toBe(5);

    act(() => { result.current.inc(); }); // 状态更新必须包在 act 里
    expect(result.current.count).toBe(6);
});
```

两个要点：

- **`result` 本身是稳定引用，`result.current` 指向最新一次渲染的返回值**。所以每次断言都要重新读 `result.current`，不能提前解构出来存着用，否则拿到的是旧快照
- **任何触发状态更新的操作都要包在 `act()` 里**，否则 React 会告警，且断言可能跑在更新之前

**需要 Provider 时**用 `wrapper`：

```jsx
const { result } = renderHook(() => useTheme(), {
    // React 19 起可以简写成 <ThemeContext value="dark">
    wrapper: ({ children }) => <ThemeContext.Provider value="dark">{children}</ThemeContext.Provider>,
});
```

**测异步 Hook**：用 `waitFor` 等待状态落地，别用固定时长的 `setTimeout`。

```jsx
await waitFor(() => expect(result.current.data).not.toBeNull());
```

**更推荐的做法是测行为而不是测 hook。** 大多数情况下渲染真实组件、用 `screen` 查询 DOM、用 `userEvent` 模拟交互，比直接断言 hook 的返回值更接近用户真实路径，也更不容易因重构而失败。`renderHook` 留给那些确实要独立发布的通用 hook。

**要 mock 的东西**：定时器用 `jest.useFakeTimers()`，网络请求用 MSW 拦在网络层（比 mock `fetch` 更真实）。

## 相关

- 仓库内笔记：[React-Redux 原理](react-redux-internals.md) · [状态管理对比](state-management-comparison.md)
- 仓库内 demo：[react-hooks.html](react-hooks.html) · [react-router-internals.html](react-router-internals.html)
- 官方文档：[Built-in React Hooks](https://react.dev/reference/react/hooks) · [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
