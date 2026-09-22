# Layout and the containing block

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Guides/Display/Containing_block>
> 对应题目：CSS 第 8 题 · Containing Block
> 抓取时间：2026-09-22

---

在学习如何确定元素包含块之前，先了解一下它的重要性。

元素的尺寸及位置，常常会受它的包含块所影响。对于一些属性，例如 [`width`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/width>), [`height`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/height>), [`padding`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/padding>), [`margin`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/margin>)，绝对定位元素的偏移值（比如 [`position`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/position>) 被设置为 `absolute` 或 `fixed`），当我们对其赋予百分比值时，这些值的计算值，就是通过元素的包含块计算得来。

确定一个元素的包含块的过程完全依赖于这个元素的 [`position`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/position>) 属性：

  1. 如果 position 属性为 **`static`** 、**`relative`** **或`sticky`**，包含块可能由它的最近的祖先**块元素** （比如说 inline-block, block 或 list-item 元素）的内容区的边缘组成，也可能会建立格式化上下文 (比如说 a table container, flex container, grid container, 或者是 the block container 自身)。
  2. 如果 position 属性为 **`absolute`** ，包含块就是由它的最近的 position 的值不是 `static` （也就是值为`fixed`, `absolute`, `relative` 或 `sticky`）的祖先元素的内边距区的边缘组成。
  3. 如果 position 属性是 **`fixed`** ，在连续媒体的情况下 (continuous media) 包含块是 [viewport](<https://developer.mozilla.org/zh-CN/docs/Glossary/Viewport>) ,在分页媒体 (paged media) 下的情况下包含块是分页区域 (page area)。
  4. 如果 position 属性是 **`absolute`** 或 **`fixed`** ，包含块也可能是由满足以下条件的最近父级元素的内边距区的边缘组成的： 
     1. [`transform`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/transform>) 或 [`perspective`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/perspective>) 的值不是 `none`
     2. [`will-change`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/will-change>) 的值是 `transform` 或 `perspective`
     3. [`filter`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/filter>) 的值不是 `none` 或 `will-change` 的值是 `filter`（只在 Firefox 下生效）。
     4. [`contain`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/contain>) 的值是 `layout`、`paint`、`strict` 或 `content`（例如：`contain: paint;`）
     5. [`backdrop-filter`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/backdrop-filter>) 的值不是 `none`（例如：`backdrop-filter: blur(10px);`）

**备注：** 根元素（[`<html>`](<https://developer.mozilla.org/zh-CN/docs/Web/HTML/Reference/Elements/html>)）所在的包含块是一个被称为**初始包含块** 的矩形。它具有视口（对于连续媒体）或页面区域（对于分页媒体）的尺寸。

**备注：**`perspective` 和 `filter` 属性对形成包含块的作用存在浏览器之间的不一致性。

如上所述，当某些属性被赋予一个百分比值时，它的计算值取决于这个元素的包含块。以这种方式工作的属性包括**盒模型属性** 和**偏移属性** ：

  1. [`height`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/height>)、[`top`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/top>) 及 [`bottom`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/bottom>) 属性根据包含块的 `height` 计算百分比值。
  2. [`width`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/width>)、[`left`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/left>)、[`right`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/right>)、[`padding`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/padding>) 和 [`margin`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/margin>) 属性根据包含块的 `width` 计算百分比值。

**备注：** 一个**块容器** （比如 inline-block、block 或 list-item 元素）要么只包含参与行级格式化上下文的行级盒子，要么只包含参与块级格式化上下文的块级盒子。只有包含块级或行级盒子的元素才是块容器。

接下来的示例，都使用如下 HTML 代码：

    <body>
      <section>
        <p>This is a paragraph!</p>
      </section>
    </body>

下面的示例，只有 CSS 不同。

这个示例中，P 标签设置为静态定位，所以它的包含块为 `<section>` ，因为距离最近的父节点即是她的包含块。

    <body>
      <section>
        <p>This is a paragraph!</p>
      </section>
    </body>

    body {
      background: beige;
    }

    section {
      display: block;
      width: 400px;
      height: 160px;
      background: lightgray;
    }

    p {
      width: 50%; /* == 400px * .5 = 200px */
      height: 25%; /* == 160px * .25 = 40px */
      margin: 5%; /* == 400px * .05 = 20px */
      padding: 5%; /* == 400px * .05 = 20px */
      background: cyan;
    }

在这个示例中，P 标签的包含块为 `<body>` 元素，因为 `<section>` 不再是一个块容器，所以并没有形成一个格式上下文。

    <body>
      <section>
        <p>This is a paragraph!</p>
      </section>
    </body>

    body {
      background: beige;
    }

    section {
      display: inline;
      background: lightgray;
    }

    p {
      width: 50%; /* == half the body's width */
      height: 200px; /* Note: a percentage would be 0 */
      background: cyan;
    }

这个示例中，P 元素的包含块是 `<section>`，因为 `<section>` 的 `position` 为 `absolute` 。P 元素的百分值会受其包含块的 `padding` 所影响。不过，如果包含块的 [`box-sizing`](<https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference/Properties/box-sizing>) 值设置为 `border-box` ，就没有这个问题。

    <body>
      <section>
        <p>This is a paragraph!</p>
      </section>
    </body>

    body {
      background: beige;
    }

    section {
      position: absolute;
      left: 30px;
      top: 30px;
      width: 400px;
      height: 160px;
      padding: 30px 20px;
      background: lightgray;
    }

    p {
      position: absolute;
      width: 50%; /* == (400px + 20px + 20px) * .5 = 220px */
      height: 25%; /* == (160px + 30px + 30px) * .25 = 55px */
      margin: 5%; /* == (400px + 20px + 20px) * .05 = 22px */
      padding: 5%; /* == (400px + 20px + 20px) * .05 = 22px */
      background: cyan;
    }

这个示例中，P 元素的 `position` 为 `fixed`，所以它的包含块就是初始包含块（在屏幕上，也就是 viewport）。这样的话，P 元素的尺寸大小，将会随着浏览器窗框大小的变化，而变化。

    <body>
      <section>
        <p>This is a paragraph!</p>
      </section>
    </body>

    body {
      background: beige;
    }

    section {
      width: 400px;
      height: 480px;
      margin: 30px;
      padding: 15px;
      background: lightgray;
    }

    p {
      position: fixed;
      width: 50%; /* == (50vw - (width of vertical scrollbar)) */
      height: 50%; /* == (50vh - (height of horizontal scrollbar)) */
      margin: 5%; /* == (5vw - (width of vertical scrollbar)) */
      padding: 5%; /* == (5vw - (width of vertical scrollbar)) */
      background: cyan;
    }

这个示例中，P 元素的 `position` 为 `absolute`，所以它的包含块是 `<section>`，也就是距离它最近的一个 `transform` 值不为 none 的父元素。

    <body>
      <section>
        <p>This is a paragraph!</p>
      </section>
    </body>

    body {
      background: beige;
    }

    section {
      transform: rotate(0deg);
      width: 400px;
      height: 160px;
      background: lightgray;
    }

    p {
      position: absolute;
      left: 80px;
      top: 30px;
      width: 50%; /* == 200px */
      height: 25%; /* == 40px */
      margin: 5%; /* == 20px */
      padding: 5%; /* == 20px */
      background: cyan;
    }
