# Symbol

> ✍️ **自撰** —— 原链 `es6.ruanyifeng.com/#docs/symbol` 是 Gitbook 单页应用，正文由前端路由渲染，抓取工具取不到内容，本篇由我重写。
> 对应题目：JS 深入 第 2 题 · Symbol
> 下面每段结论都在 **Node v22.22.3** 实跑验证过，贴的是实际输出。
> 想看原文：<https://es6.ruanyifeng.com/#docs/symbol>

---

## 它解决什么问题

ES5 里对象的属性名只能是字符串，于是两个模块往同一个对象上挂属性时**可能撞名**，后者悄悄覆盖前者。`Symbol` 是 ES6 引入的第七种原始类型，特点只有一个：**每个 Symbol 值都独一无二**。

```js
const s1 = Symbol('desc'), s2 = Symbol('desc');
```

```
1) Symbol("desc") === Symbol("desc") → false | description: desc
```

参数只是**描述**（方便调试），不参与相等判断。所以 `new Symbol()` 是非法的——它是原始类型，不是对象。

## 全局注册表：`Symbol.for` / `Symbol.keyFor`

`Symbol()` 每次都造新的。想要「同一个 key 拿到同一个 Symbol」，用 `Symbol.for`：

```
2) Symbol.for("k") === Symbol.for("k") → true
   Symbol.keyFor(Symbol.for("k")) = k
   Symbol.keyFor(Symbol("k"))     = undefined
```

区别在于登记与否：

| | `Symbol()` | `Symbol.for()` |
| --- | --- | --- |
| 每次调用 | 返回**新**值 | 先查全局注册表，有就复用 |
| 登记在全局表 | ❌ | ✅ |
| `Symbol.keyFor` 能查到 | ❌ `undefined` | ✅ 返回 key |
| 跨 iframe / worker | 不共享 | **共享**（注册表是跨 realm 的） |

## 作为属性名：半隐藏

这是 Symbol 最常见的用途。它**不会出现在常规遍历里**：

```js
const k = Symbol('hidden');
const o = { normal: 1, [k]: 2 };
```

```
3) Object.keys            = [ 'normal' ]
   JSON.stringify         = {"normal":1}
   for...in               = [ 'normal' ]
   getOwnPropertySymbols  = 1 个
   Reflect.ownKeys        = [ 'normal', 'Symbol(hidden)' ]
```

⚠️ **注意是「半隐藏」不是「真私有」**。`Object.getOwnPropertySymbols()` 和 `Reflect.ownKeys()` 照样能拿到。真要私有用 `#field`（class 私有字段）或闭包。

Symbol 属性的实际价值是**避免命名冲突**：给第三方对象打标记、库内部存元数据，都不会污染用户的字符串键空间，也不会被 `JSON.stringify` 意外序列化出去。

## 不能隐式转字符串

```
4) 模板字符串隐式转换 → TypeError
   String(s1) 显式转换 → Symbol(desc)
```

`${symbol}` 和 `symbol + ''` 都抛 `TypeError`。这是**故意设计**的：强迫你显式表达意图，避免把一个本该唯一的标识悄悄变成字符串。要转就用 `String(s)` 或 `s.toString()`，取描述用 `s.description`。

## Well-known Symbols：改写语言内置行为

这是 Symbol 更有分量的一面——它把过去写死在引擎里的行为**开放成了可重写的协议**。

| Symbol | 控制什么 |
| --- | --- |
| `Symbol.iterator` | 对象能否被 `for...of` / 扩展运算符遍历 |
| `Symbol.asyncIterator` | `for await...of` |
| `Symbol.hasInstance` | `instanceof` 的判定逻辑 |
| `Symbol.toPrimitive` | 对象转原始值（`+obj`、`${obj}`、`obj == x`） |
| `Symbol.toStringTag` | `Object.prototype.toString.call(obj)` 的结果 |
| `Symbol.species` | 派生对象（如 `map`/`filter` 返回值）用哪个构造函数 |

实测三个：

```js
class Coll { static [Symbol.hasInstance](x) { return Array.isArray(x); } }
const it = { *[Symbol.iterator]() { yield 1; yield 2; } };
const t  = { [Symbol.toPrimitive](hint) { return hint === 'number' ? 42 : 'forty-two'; } };
```

```
5) [] instanceof Coll → true   (被 Symbol.hasInstance 改写)
   [...it] = [ 1, 2 ]          (Symbol.iterator 让对象可迭代)
   +t = 42 | `${t}` = forty-two
```

第一行尤其能说明问题：`[]` 和 `Coll` 毫无关系，但 `instanceof` 返回了 `true`——**因为判定逻辑被接管了**。

`Symbol.toPrimitive` 的 `hint` 有三种：`'number'`、`'string'`、`'default'`，分别对应算术运算、字符串拼接、`==` 比较。

## 实际用在哪

1. **消除魔法字符串常量**

   ```js
   const RED = Symbol('red'), GREEN = Symbol('green');
   ```
   比 `'red'` 安全——不会和别处的同名字符串误匹配。

2. **给对象挂元数据不污染键空间**
   React 就用 `Symbol.for('react.element')` 标记元素类型（用 `for` 是为了跨 bundle 也能匹配上，避免多份 React 副本互不认识）。

3. **实现迭代协议**
   自定义数据结构加上 `[Symbol.iterator]` 就能用 `for...of` 和 `...` 展开。

4. **库内部状态**
   用 Symbol 键存内部状态，用户 `Object.keys` 看不到，也不会被序列化。

## 几个易错点

| 坑 | 说明 |
| --- | --- |
| `new Symbol()` | ❌ 抛 `TypeError`，它是原始类型 |
| `${sym}` | ❌ 抛 `TypeError`，必须 `String(sym)` |
| 以为是真私有 | `getOwnPropertySymbols` 能拿到，只是不出现在常规遍历 |
| `JSON.stringify` 丢失 | Symbol 键**和** Symbol 值都会被静默丢弃 |
| `Object.assign` | ✅ **会**复制 Symbol 属性（和 `Object.keys` 的行为不一致，容易记混） |
