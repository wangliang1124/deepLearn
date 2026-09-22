# requestAnimationFrame

> ✍️ **自撰** —— 原引用文章所在的 `taobaofed.org`（淘宝前端团队博客）**域名已过期并被他人抢注**，现在返回的是盗版影视站内容，与原文毫无关系。本篇由我重写。
> 对应题目：HTML 第 6 题 · requestAnimationFrame
> 下面的数据是在 **Chrome 153 / 119Hz 显示器** 上实跑测出来的。
> ⚠️ 原链 `https://taobaofed.org/blog/2017/03/02/thinking-in-request-animation-frame/` **不要再访问**。

---

## 它解决什么问题

用 `setTimeout`/`setInterval` 做动画有三个治不好的毛病：

1. **频率和屏幕刷新对不上** —— 你定 16ms，屏幕按自己的节奏刷，两者错位就会**丢帧或重复帧**
2. **时机不对** —— 定时器回调可能落在一帧的任意位置，改完样式可能当帧就被提交，也可能等下一帧
3. **后台照跑** —— 标签页切走了动画还在算，白烧 CPU 和电

`requestAnimationFrame` 把回调交给浏览器，**由浏览器决定在每次重绘前调用**，上面三个问题一次解决。

## 实测：和 setTimeout 的差距

```js
// 连续 8 次 rAF 的间隔
requestAnimationFrame(function step(t) { gap = t - last; ... });
// 对比：setTimeout(fn, 16)
```

```
rAF 间隔       : 8.5, 8.5, 8.3, 8.4, 8.3, 8.3, 8.3   (ms)
setTimeout(16) : 17.3, 18.0, 18.0, 18.1, 18.1, 18.1, 17.3, 18.2
```

两件事值得注意：

**① rAF 自动跟上了 119Hz 的屏幕。** 间隔 8.3ms ≈ 1000/120。很多资料默认「一帧 16.7ms」，那是 60Hz 的假设——**在 ProMotion、高刷屏、外接显示器上都不成立**。rAF 的价值恰恰是你不用关心这个数字。

**② `setTimeout(16)` 永远不是 16ms。** 实测稳定在 18ms 左右，误差 12%。原因是定时器只保证「至少等这么久」，真正执行还要排队等宏任务。累积起来就是可见的抖动。

**所以：动画不要用 setTimeout 定帧率。**

## 同一帧内的多个回调，时间戳是同一个

```js
requestAnimationFrame(t => got.push(t));
requestAnimationFrame(t => got.push(t));
requestAnimationFrame(t => got.push(t));
```

```
sameFrameStamps: [15086.7, 15086.7, 15086.7]
allEqual: true
```

三个回调拿到**完全相同**的时间戳。这说明：

- 它们被**批量放进同一帧**执行，而不是各自排队
- 时间戳是「**这一帧开始的时刻**」，不是回调实际执行的时刻

这个设计很重要：同一帧里的多个动画用同一个时间基准计算位移，**天然同步**，不会因为回调执行有先后而产生错位。

## 时间戳和 `performance.now()` 同源

```
raf: 15095.1   performance.now(): 15095.2
```

rAF 回调的参数是一个 `DOMHighResTimeStamp`，和 `performance.now()` 共享时间原点（页面加载时刻），单位毫秒、亚毫秒精度。所以可以直接混用来算耗时。

## 它在一帧里的什么位置

```
                 ┌─────────────── 一帧 ───────────────┐
  上一帧 VSync   │                                    │  VSync
  ───────────────┼────────────────────────────────────┼──────────
                 │ 处理输入事件                        │
                 │ 执行 JS（宏任务 + 微任务）           │
                 │ ★ requestAnimationFrame 回调        │
                 │ 样式计算 Style                      │
                 │ 布局 Layout                         │
                 │ 绘制 Paint                          │
                 │ 合成 Composite                      │
                 │ requestIdleCallback（如果还有空）    │
                 └────────────────────────────────────┘
```

**rAF 在样式计算之前、JS 执行之后。** 这就是它适合改动画属性的原因——改完马上进入样式/布局/绘制，**同一帧内生效**，不会多等一帧。

对比 `requestIdleCallback`：它在帧尾的空闲时间跑，**可能几帧都轮不到一次**，适合非紧急任务（预加载、上报），绝不能用来做动画。

## 关键特性

| 特性 | 说明 |
| --- | --- |
| 自动匹配刷新率 | 60Hz 就 ~16.7ms，120Hz 就 ~8.3ms，不用自己算 |
| **后台自动暂停** | 标签页不可见时**停止回调**，省电。`setInterval` 不会 |
| 批量执行 | 同一帧的回调合并，共享同一个时间戳 |
| 返回 id | 用 `cancelAnimationFrame(id)` 取消 |
| 只执行一次 | 要连续动画必须在回调里**再次调用** |

⚠️ 「后台暂停」是双刃剑：**它不适合做计时**。切走标签页再回来，动画的累计时间会对不上，所以位移要基于**时间戳差值**算，不能靠「调用次数 × 每帧位移」。

## 正确的动画写法

```js
let rafId = null;

function animate(startTime, duration, from, to, onUpdate) {
  function step(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    // 基于时间算进度，而不是基于帧数 —— 掉帧时动画时长仍然正确
    onUpdate(from + (to - from) * easeOutCubic(progress));
    if (progress < 1) rafId = requestAnimationFrame(step);
  }
  rafId = requestAnimationFrame(step);
}

const easeOutCubic = p => 1 - Math.pow(1 - p, 3);

// 组件销毁时一定要取消
function cleanup() { if (rafId) cancelAnimationFrame(rafId); }
```

**核心是「基于时间而非帧数」**：掉帧时进度会跳跃，但总时长仍然准确；否则在低端机上动画会明显变慢。

## 三个实用场景

**① 高频事件节流** —— `scroll`、`resize`、`mousemove` 每秒能触发上百次，但一帧只需要处理一次：

```js
let ticking = false;
window.addEventListener('scroll', () => {
  if (ticking) return;
  ticking = true;
  requestAnimationFrame(() => { updateUI(); ticking = false; });
});
```

**② 大批量 DOM 操作分帧** —— 一次插 10000 个节点会卡死主线程，切成每帧几百个：

```js
function chunked(items, perFrame, handle) {
  let i = 0;
  (function run() {
    const end = Math.min(i + perFrame, items.length);
    for (; i < end; i++) handle(items[i]);
    if (i < items.length) requestAnimationFrame(run);
  })();
}
```

**③ 强制触发过渡动画** —— 元素刚插入就改 class，浏览器会合并两次样式计算导致没有过渡。隔一帧再改：

```js
el.classList.add('start');
requestAnimationFrame(() => requestAnimationFrame(() => el.classList.add('end')));
```

（要两层，因为第一层仍在同一帧的样式计算之前。）

## 常见误区

| 误区 | 实情 |
| --- | --- |
| 「rAF 就是 16.7ms 一次」 | 取决于屏幕刷新率，实测 119Hz 屏是 8.3ms |
| 「rAF 比 setTimeout 快」 | 不是快慢问题，是**时机对不对**的问题 |
| 「调一次就会一直执行」 | 只执行一次，必须在回调里再调 |
| 「可以用来做精确计时」 | ❌ 后台会暂停，计时请用 `performance.now()` 或 Web Worker |
| 「CSS 动画和 rAF 一样」 | CSS `transform`/`opacity` 动画跑在**合成线程**，主线程卡住也不掉帧；rAF 在主线程，会被阻塞 |

最后一条是最重要的取舍：**能用 CSS `transform`/`opacity` 实现的动画就别用 rAF**——前者由 GPU 合成，性能上限高得多。rAF 适合需要 JS 逐帧计算的场景（物理模拟、Canvas 绘制、跟手交互）。
