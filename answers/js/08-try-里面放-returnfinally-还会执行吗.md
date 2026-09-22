# try catch finally 语句执行原理

> ✍️ **自撰** —— 原引用文章《try 里面放 return，finally 还会执行吗？》链接已失效，本篇由我重写。
> 对应题目：JS 深入 第 8 题 · try catch finally 语句执行原理
> 下面每段结论都在 **Node v22.22.3** 实跑验证过，贴的是实际输出。

---

## 一句话结论

**`finally` 一定执行**（除非进程直接终止），而且它**在 `return` 表达式求值之后、函数真正返回之前**执行。

## 规范层面发生了什么

ECMAScript 用 **Completion Record**（完成记录）描述语句的执行结果，它是一个三元组：

```
{ type: normal | return | throw | break | continue, value, target }
```

`try` 语句的求值规则是：

1. 执行 `try` 块，得到一个 completion **B**
2. 如果有 `catch` 且 B 是 `throw`，执行 catch 块，用它的 completion 覆盖 B
3. 执行 `finally` 块，得到 completion **F**
4. **如果 F 的 type 是 `normal`，最终结果取 B；否则取 F**

第 4 条是理解一切反直觉行为的钥匙：**`finally` 里只要出现 `return` / `throw` / `break` / `continue`，就会把原本要返回的 completion 整个替换掉。**

## 逐个验证

### 1. `try` 里 return，`finally` 照样执行

```js
function f1() {
    try { return 'try'; }
    finally { console.log('finally 执行了'); }
}
```

```
  finally 执行了
f1 返回: try
```

`finally` 执行了，但因为它是 `normal` completion，返回值仍是 `'try'`。

### 2. `finally` 里 return 会覆盖 `try` 的 return

```js
function f2() {
    try { return 'try'; }
    finally { return 'finally'; }
}
```

```
f2 返回: finally
```

### 3. `finally` 也覆盖 `catch` 的 return

```js
function f3() {
    try { throw new Error('x'); }
    catch (e) { return 'catch'; }
    finally { return 'finally'; }
}
```

```
f3 返回: finally
```

### 4. 最容易考的一题：`finally` 改变量，改得动吗？

```js
function f4() {
    let n = 1;
    try { return n; }
    finally { n = 99; }
}

function f5() {
    let o = { v: 1 };
    try { return o; }
    finally { o.v = 99; }
}
```

```
f4 返回: 1        <- 基本类型：return 时已求值
f5 返回: {"v":99} <- 对象：返回的是引用
```

**这是最经典的陷阱。** 两者行为不同，但原理是同一条：

- `return n` 在进入 `finally` **之前**就已经把 `n` 的值 `1` 求值并暂存进 completion 的 `value` 里。之后改 `n` 改的是变量，动不了那份已暂存的副本
- `return o` 暂存的是**对象引用**。`finally` 里改的是引用指向的那个对象的属性，所以调用方看到的是改后的值

一句话：**`finally` 改不了已经暂存的返回值，但改得动那个值指向的对象。**

如果在 `f5` 的 finally 里写 `o = {v: 99}`（重新赋值而非改属性），返回的仍是原对象 `{v:1}`——因为暂存的引用没变。

### 5. `finally` 里 return 会吞掉异常

```js
function f6() {
    try { throw new Error('原始错误'); }
    finally { return '被吞掉'; }
}
```

```
f6 返回: 被吞掉  <- finally 里 return 吞掉了异常
```

⚠️ **这是真实项目里的 bug 来源**：异常被无声吃掉，调用方以为一切正常。所以 **`finally` 里不要写 `return`**，ESLint 有专门的 [`no-unsafe-finally`](https://eslint.org/docs/latest/rules/no-unsafe-finally) 规则来禁止它。

### 6. 循环里 `continue` / `break` 同样触发 finally

```js
for (let i = 0; i < 3; i++) {
    try { if (i === 1) continue; console.log('body', i); }
    finally { console.log('finally', i); }
}
```

```
  body 0
  finally 0
  finally 1     <- continue 跳过了 body，finally 仍然执行
  body 2
  finally 2
```

## 什么时候 `finally` 真的不执行

| 情况 | 说明 |
| --- | --- |
| 进程被杀 | `process.exit()`、`kill -9`、崩溃 |
| 无限循环 / 死锁 | 根本没走到 finally |
| 所在线程被终止 | Worker 被 terminate |
| 从未进入 try | 比如 try 之前就抛异常了 |

注意：**`return`、`throw`、`break`、`continue` 都不能跳过 `finally`**，这正是它存在的意义。

## 实践建议

1. **`finally` 只做清理**——关文件、解锁、清定时器、埋点收尾
2. **不要在 `finally` 里 `return` 或 `throw`**，会掩盖真实的返回值和异常
3. 需要「无论成败都执行」且不干扰返回值时，`finally` 是对的工具
4. 现代写法里 `try/finally` 常被 `using`（TC39 显式资源管理提案）或 RAII 风格封装替代

## 延伸：async 函数里的 finally

`async` 函数同样遵守上面的规则，`await` 不影响 `finally` 的执行：

```js
async function f() {
    try { return await fetchData(); }
    finally { hideLoading(); }   // 无论成功失败都执行
}
```

Promise 的 `.finally()` 语义略有不同——它**不接收参数**，也**不改变** resolve 值或 reject 原因（除非它自己抛错），设计上比语句版的 `finally` 更安全。
