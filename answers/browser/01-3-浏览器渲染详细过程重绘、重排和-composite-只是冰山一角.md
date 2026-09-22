# 浏览器渲染详细过程：重绘、重排和 composite 只是冰山一角

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://juejin.cn/post/6844903476506394638>
> 对应题目：浏览器 第 1 题 · 浏览器工作原理
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

在之前的一篇文章中：[Vue源码详解之nextTick：MutationObserver只是浮云，microtask才是核心！](<https://link.juejin.cn?target=http%3A%2F%2Fchuckliu.me%2F%23!%2Fposts%2F58bd08a2b5187d2fb51c04f9> "http://chuckliu.me/#!/posts/58bd08a2b5187d2fb51c04f9")，我说过，偶然在一次对[task和microtask的讨论当中](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fcreeperyang%2Fblog%2Fissues%2F21> "https://github.com/creeperyang/blog/issues/21")，研究到了浏览器在处理完task和microtask之后执行的渲染机制，当时看到这个内容，还是挺激动的，因为以前从来不知道我在js里更改的样式，浏览器到底是什么时候、以怎样的方式渲染到界面上的，于是兴奋的写下了上述文章。

最近深入研究了这部分，发现这里有一片更广阔的新大陆，在我们耳熟能详的重排、重绘、composite、合成层提升等概念下还有更深的的东西。这篇文章将会介绍浏览器的详细渲染过程。

## event loop规范和处理过程

这里我在开头说的[nexttick详解](<https://link.juejin.cn?target=http%3A%2F%2Fchuckliu.me%2F%23!%2Fposts%2F58bd08a2b5187d2fb51c04f9> "http://chuckliu.me/#!/posts/58bd08a2b5187d2fb51c04f9")中说过这部分，但是只是自己看嗨了，并没有作为文章重点去详细介绍，当时主要还是说task和microtask。其实这部分是整个渲染过程的关键，涉及**浏览器进行渲染的时机** ，所以认真说一下：

**请先点链接看html5官方规范：** [html5 event loop processing model](<https://link.juejin.cn?target=https%3A%2F%2Fhtml.spec.whatwg.org%2Fmultipage%2Fwebappapis.html%23event-loop-processing-model> "https://html.spec.whatwg.org/multipage/webappapis.html#event-loop-processing-model")

  1. 前1到5步，从多个task队列中里选出一个task队列（浏览器为了区分不同task的优先级，所以时常有多个task队列），从这个task队列中取出最老的那个task，执行他，然后把他从队列中去除。
  2. 第六步perform a microtask checkpoint[执行一个microtask检查点](<https://link.juejin.cn?target=https%3A%2F%2Fhtml.spec.whatwg.org%2Fmultipage%2Fwebappapis.html%23perform-a-microtask-checkpoint> "https://html.spec.whatwg.org/multipage/webappapis.html#perform-a-microtask-checkpoint")，这个步骤其实包含了多个子步骤，只要microtask queue不空，这一步会一直从microtask queue中取出microtask，执行之。如果microtask执行过程中又添加了microtask，那么仍然会执行新添加的microtask。（ 链接里第七步的**return to the microtask queue handling step** 很关键）
  3. 第七步Update the rendering，更新渲染。到了更新界面的部分了！ 
     1. 7.1步到7.4步，判断当前的document是否需要渲染，用官方规范的说法就是浏览器会判断这个document是否会从UI Render中获益，因为只需要保持60Hz的刷新率即可，而每轮event loop都是非常快的，所以没必要每轮loop都Render UI，而是差不多16ms的时候再Render。同时对于一些比较卡顿的已经不能保证60Hz的页面，若再在此时执行界面渲染会雪上加霜，所以浏览器可能会下调认为document能获益的频率为（比如说）30hz。
     2. [run the resize steps](<https://link.juejin.cn?target=https%3A%2F%2Fdrafts.csswg.org%2Fcssom-view%2F%23run-the-resize-steps> "https://drafts.csswg.org/cssom-view/#run-the-resize-steps")，若浏览器resize过，那么这里会在Window上触发’resize’事件。
     3. [run the scroll steps](<https://link.juejin.cn?target=https%3A%2F%2Fdrafts.csswg.org%2Fcssom-view%2F%23run-the-scroll-steps> "https://drafts.csswg.org/cssom-view/#run-the-scroll-steps")。首先，每当我们在某个target上滚动时(target可以是某个可滚动元素也可能就是document)，浏览器就会在target所属的document上的[pending scroll event targets](<https://link.juejin.cn?target=https%3A%2F%2Fdrafts.csswg.org%2Fcssom-view%2F%23pending-scroll-event-targets> "https://drafts.csswg.org/cssom-view/#pending-scroll-event-targets")里存放这个发生滚动的target。现在， [run the scroll steps](<https://link.juejin.cn?target=https%3A%2F%2Fdrafts.csswg.org%2Fcssom-view%2F%23run-the-scroll-steps> "https://drafts.csswg.org/cssom-view/#run-the-scroll-steps")这一步会从[pending scroll event targets](<https://link.juejin.cn?target=https%3A%2F%2Fdrafts.csswg.org%2Fcssom-view%2F%23pending-scroll-event-targets> "https://drafts.csswg.org/cssom-view/#pending-scroll-event-targets")里取出target，然后在target上触发scroll事件。
     4. 计算是否触发media query
     5. 7.8和7.9 执行css animation和触发‘animationstart’等animation相关事件. run the fullscreen rendering steps：如果在之前的task或者microtask中执行过 requestFullscreen()等full screen相关api，此处会执行全屏操作。
     6. [run the animation frame callbacks](<https://link.juejin.cn?target=https%3A%2F%2Fhtml.spec.whatwg.org%2Fmultipage%2Fwebappapis.html%23run-the-animation-frame-callbacks> "https://html.spec.whatwg.org/multipage/webappapis.html#run-the-animation-frame-callbacks")，执行requestAnimationFrame的回调，requestAnimationFrame就是在这里执行的！
     7. 执行[IntersectionObserver](<https://link.juejin.cn?target=http%3A%2F%2Fwww.ruanyifeng.com%2Fblog%2F2016%2F11%2Fintersectionobserver_api.html%3Futm_source%3Dtuicool%26utm_medium%3Dreferral> "http://www.ruanyifeng.com/blog/2016/11/intersectionobserver_api.html?utm_source=tuicool&utm_medium=referral")的回调，也许你在图片懒加载的逻辑里用过这个api。
     8. **更新、渲染用户界面**
  4. 继续返回第一步

好了，整个流程就介绍完了。前两步task和microtask相关处理不再赘述。  
重要的第三步里有3点值得关注的东西:

  1. 不是每轮event loop里都会有Update the rendering，只有浏览器判断这个document需要更新界面的时候才会让更新。这意味着两次UI Render之间最小间隔也是16ms，你setInterval去1ms更新一次其实也依然是16ms更新一次。
  2. resize和scroll事件是在渲染流程里触发的。是不是很惊人？这意味着如果你想在scroll事件上**绑回调去执行动画** ，那么根本不需要用requestAnimationFrame去节流，scroll事件本身就是在每帧真正渲染前执行，自带节流效果！当然，滚动图片懒加载、滚动内容无限加载等业务逻辑而非动画逻辑还是需要throttle的。
  3. 如同mdn、w3c等介绍的：[requestAnimationFrame的回调是在重绘前执行的](<https://link.juejin.cn?target=https%3A%2F%2Fdeveloper.mozilla.org%2Fzh-CN%2Fdocs%2FWeb%2FAPI%2FWindow%2FrequestAnimationFrame> "https://developer.mozilla.org/zh-CN/docs/Web/API/Window/requestAnimationFrame")，7.9步是这一逻辑的保证。
  4. UI的重绘是在event loop的结束时执行的。  
页面的重绘竟然是跟event loop紧密耦合的，而且是被精确定义在event loop中的，始料未及。我之前一直不明白我JS修改了DOM样式之后，这样式到底什么时候呈现。

**页面渲染的时机** 介绍完了，来说说渲染到底是怎样一个过程。另，后文讲述的是浏览器详细过程，是**实现** ，前文讲的是**规范** 。

## 渲染

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/869e322f9239edbfa82548d9688c023a~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

这张很经典的图许多人都看过，其中的概念大家应该都很熟悉，也就是这么几个步骤:  
js修改dom结构或样式 -> 计算style -> layout(重排) -> paint(重绘) -> composite(合成)

但是其中有更复杂的内容，我们从更底层来详细说明这个过程，主要是下面这两幅图：  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/a14a6f315f394b0844f7a1ee894593dd~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
 _上图出自[GPU Accelerated Compositing in Chrome](<https://link.juejin.cn?target=http%3A%2F%2Fdev.chromium.org%2Fdevelopers%2Fdesign-documents%2Fgpu-accelerated-compositing-in-chrome> "http://dev.chromium.org/developers/design-documents/gpu-accelerated-compositing-in-chrome")_  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/5cd4a72de4568b7da544a32870e9aa5b~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
_上图出自[The Anatomy of a Frame](<https://link.juejin.cn?target=https%3A%2F%2Faerotwist.com%2Fblog%2Fthe-anatomy-of-a-frame%2F> "https://aerotwist.com/blog/the-anatomy-of-a-frame/")_

这部分内容基于blink、webkit内核，但是其中涉及到的重排、重绘、composite和合成层提升等环节对于各大浏览器都是一致的。

### 先说一些概念

  1. 位图  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/4ca498904c224066f2782702ff245ff0~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
就是数据结构里常说的位图。你想在绘制出一个图片，你应该怎么做，显然首先是把这个图片表示为一种计算机能理解的数据结构：用一个二维数组，数组的每个元素记录这个图片中的每一个像素的具体颜色。所以浏览器可以用位图来记录他想在某个区域绘制的内容，绘制的过程也就是往数组中具体的下标里填写像素而已。

  2. 纹理  
纹理其实就是GPU中的位图，存储在GPU video RAM中。前面说的位图里的元素存什么你自己定义好就行，是用3字节存256位rgb还是1个bit存黑白你自己定义即可，但是纹理是GPU专用的，GPU和CPU是分离的，需要有固定格式，便于兼容与处理。所以一方面纹理的格式比较固定，如R5G6B5、A4R4G4B4等像素格式， 另外一方面GPU 对纹理的大小有限制，比如长/宽必须是2的幂次方，最大不能超过2048或者4096等。

  3. Rasterize(光栅化)  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/5ecd7f8eed08ab1ade5b648622d5046d~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/05dfaa0bd78fcf58b381ee25f2dde605~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
在纹理里填充像素不是那么简单的自己去遍历位图里的每个元素然后填写这个像素的颜色的。就像前面两幅图。**光栅化的本质是坐标变换、几何离散化，然后再填充** 。  
同时，光栅化从早期的 Full-screen Rasterization基本都进化到了现在的Tile-Based Rasterization， 也就是不是对整个图像做光栅化，而是把图像分块(tile，亦有翻译为瓦片、贴片、瓷片…)后，再对每个tile单独光栅化。光栅化好了将像素填充进纹理，再将纹理上传至GPU。  
原因一方面如上文所说，纹理大小有限制，即使你整屏光栅化也是要填进小块小块的纹理中，不如事先根据纹理大小分块光栅化后再填充进纹理里。另一方面是为了减少内存占用(整屏光栅化意味着需要准备更大的buffer空间)和降低总体延迟（分块栅格化意味着可以多线程并行处理）。  
看到下图中蓝色的那些青色的矩形了吗？他们就是tiles。  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/376986b1dad01192aadd8ee9883d9d38~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

可以想见浏览器的一次绘制过程就是先把想绘制的内容如文字、背景、边框等通过分块Rasterize绘制到很多纹理里，再把纹理上传到gpu的存储空间里，gpu把纹理绘制到屏幕上。

### 绘制的具体过程

我们先把计算样式、重排等步骤抽离，单独讲解浏览器是怎么绘制的。

先来看这幅经典的图：  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/a14a6f315f394b0844f7a1ee894593dd~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
 _图中一些名词的称呼发生了变化，详见taobaofed的文章：[无线性能优化：Composite](<https://link.juejin.cn?target=http%3A%2F%2Ftaobaofed.org%2Fblog%2F2016%2F04%2F25%2Fperformance-composite%2F> "http://taobaofed.org/blog/2016/04/25/performance-composite/")_

### Render Object

首先我们有DOM树，但是DOM树里面的DOM是供给JS/HTML/CSS用的，并不能直接拿过来在页面或者位图里绘制。因此浏览器内部实现了**Render Object** ：

**每个Render Object和DOM节点一一对应。Render Object上实现了将其对应的DOM节点绘制进位图的方法，负责绘制这个DOM节点的可见内容如背景、边框、文字内容等等。同时Render Object也是存放在一个树形结构中的。**

既然实现了绘制每个DOM节点的方法，那是不是可以开辟一段位图空间，然后DFS遍历这个新的Render Object树然后执行每个Render Object的绘制方法就可以将DOM绘制进位图了？就像“盖章”一样，把每个Render Object的内容一个个的盖到纸上（类比于此时的位图）是不是就完成了绘制。

不，浏览器还有个[层叠上下文](<https://link.juejin.cn?target=https%3A%2F%2Fdeveloper.mozilla.org%2Fzh-CN%2Fdocs%2FWeb%2FGuide%2FCSS%2FUnderstanding_z_index%2FThe_stacking_context> "https://developer.mozilla.org/zh-CN/docs/Web/Guide/CSS/Understanding_z_index/The_stacking_context")。就是决定元素间相互覆盖关系(比如z-index)的东西。这使得文档流中位置靠前位置的元素有可能覆盖靠后的元素。上述DFS过程只能无脑让文档流靠后的元素覆盖前面元素。

因此，有了Render Layer。

### Render Layer

当然Render Layer的出现并不是简单因为层叠上下文等，比如opacity小于1、比如存在mask等等需要先绘制好内容再对绘制出来的内容做一些统一处理的css效果。

总之就是有层叠、半透明等等情况的元素（具体哪些情况请参考[无线性能优化：Composite](<https://link.juejin.cn?target=http%3A%2F%2Ftaobaofed.org%2Fblog%2F2016%2F04%2F25%2Fperformance-composite%2F> "http://taobaofed.org/blog/2016/04/25/performance-composite/")）就会从Render Object提升为Render Layer。不提升为Render Layer的Render Object从属于其父级元素中最近的那个Render Layer。当然根元素HTML自己要提升为Render Layer。

因此现在Render Object树就变成了Render Layer树，每个Render Layer又包含了属于自己layer的Render Object。

另外：

> The children of each RenderLayer are kept into two sorted lists both sorted in ascending order, the negZOrderList containing child layers with negative z-indices (and hence layers that go below the current layer) and the posZOrderList contain child layers with positive z-indices (layers that go above the current layer).  
> 每个Render Layer的子Render Layer都是按照升序排列存储在两个有序列表当中的：negZOrderList存储了负z-indicices的子layers，posZOrderList存储了正z-indicies的子layers。  
>  — 出自[GPU加速的compositing](<https://link.juejin.cn?target=http%3A%2F%2Fdev.chromium.org%2Fdevelopers%2Fdesign-documents%2Fgpu-accelerated-compositing-in-chrome> "http://dev.chromium.org/developers/design-documents/gpu-accelerated-compositing-in-chrome")一文

现在浏览器渲染引擎遍历 Layer 树，访问每一个 RenderLayer，然后递归遍历negZOrderList里的layer、自己的RenderObject、再递归遍历posZOrderList里的layer。就可以将一颗 Layer树绘制出来。

**Layer 树决定了网页绘制的层次顺序，而从属于 RenderLayer 的 RenderObject 决定了这个 Layer 的内容，所有的 RenderLayer 和 RenderObject 一起就决定了网页在屏幕上最终呈现出来的内容。**

层叠上下文、半透明、mask等等问题通过Render Layer解决了。那么现在:  
开辟一个位图空间->不断的绘制Render Layer、覆盖掉较低的Layer->拿给GPU显示出来 是不是就完全ok了？

不。还有GraphicsLayers和Graphics Context

### Graphics Layer(又称Compositing Layer)和Graphics Context

上面的过程可以搞定绘制过程。但是浏览器里面经常有动画、video、canvas、3d的css等东西。这意味着页面在有这些元素时，页面显示会经常变动，也就意味着位图会经常变动。每秒60帧的动效里，每次变动都重绘整个位图是很恐怖的性能开销。

因此浏览器为了优化这一过程。引出了Graphics Layers和Graphics Context，前者就是我们常说的**合成层(Compositing Layer)** ：

某些具有CSS3的3D transform的元素、在opacity、transform属性上具有动画的元素、硬件加速的canvas和video等等，这些元素在上一步会提升为Render Layer，而现在他们会提升为合成层Graphics Layer（你如果查看了前文我给的[链接](<https://link.juejin.cn?target=http%3A%2F%2Ftaobaofed.org%2Fblog%2F2016%2F04%2F25%2Fperformance-composite%2F> "http://taobaofed.org/blog/2016/04/25/performance-composite/")，你当时可能会疑惑为什么这些情况也能提升为Render Layer，现在你应该明白了，他们是为提升为Graphics Layer准备的）。每个Render Layer都属于他祖先中最近的那个Graphics Layer。当然根元素HTML自己要提升为Graphics Layer。

Render Layer提升为Graphics Layer的情况：

>   * **3D 或透视变换**(perspective、transform) CSS 属性
>   * 使用加速视频解码的 元素
>   * 拥有 3D (WebGL) 上下文或加速的 2D 上下文的 元素
>   * 混合插件(如 Flash)
>   * **对 opacity、transform、fliter、backdropfilter 应用了 animation 或者 transition（需要是 active 的 animation 或者 transition，当 animation 或者 transition 效果未开始或结束后，提升合成层也会失效）**
>   * **will-change 设置为 opacity、transform、top、left、bottom、right（其中 top、left 等需要设置明确的定位属性，如 relative 等）**
>   * 拥有加速 CSS 过滤器的元素
>   * 元素有一个 z-index 较低且包含一个复合层的兄弟元素(换句话说就是该元素在复合层上面渲染)
>   * ….. 所有情况的详细列表参见淘宝fed文章:[无线性能优化：Composite](<https://link.juejin.cn?target=http%3A%2F%2Ftaobaofed.org%2Fblog%2F2016%2F04%2F25%2Fperformance-composite%2F> "http://taobaofed.org/blog/2016/04/25/performance-composite/")
> 

**3D transform、will-change设置为 opacity、transform等 以及 包含opacity、transform的CSS过渡和动画 这3个经常遇到的提升合成层的情况请重点记住。**

另外除了上述直接导致Render Layer提升为Graphics Layer，还有下面这种因为B被提升，导致A也被**隐式提升** 的情况，详见此文: [GPU Animation: Doing It Right ](<https://link.juejin.cn?target=https%3A%2F%2Fwww.smashingmagazine.com%2F2016%2F12%2Fgpu-animation-doing-it-right%2F> "https://www.smashingmagazine.com/2016/12/gpu-animation-doing-it-right/")

每个合成层Graphics Layer 都拥有一个 Graphics Context，Graphics Context 会为该Layer开辟一段位图，也就意味着每个Graphics Layer都拥有一个位图。Graphics Layer负责将自己的Render Layer及其子代所包含的Render Object绘制到位图里。然后将位图作为纹理交给GPU。所以现在GPU收到了HTML元素的Graphics Layer的纹理，也可能还收到某些因为有3d transform之类属性而提升为Graphics Layer的元素的纹理。

现在GPU需要对多层纹理进行合成(composite)，同时GPU在纹理合成时对于每一层纹理都可以指定不同的合成参数，从而实现对纹理进行transform、mask、opacity等等操作之后再合成，而且GPU对于这个过程是底层硬件加速的，性能很好。最终，纹理合成为一幅内容最终draw到屏幕上。

所以在元素存在transform、opacity等属性的css animation或者css transition时，动画处理会很高效，这些属性在动画中不需要重绘，只需要重新合成即可。

上述分层后合并的过程可以用一张图来描述:  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/a63aaf15b2e42eefd7875ef288eb0a72~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

## 绘制的具体实现

### 系统结构

#### 进程

blink和webkit引擎内部都是使用了两个进程来搞定JS执行、页面渲染之类的核心任务。

  * Renderer进程  
主要的那个进程，每个tab一个。负责执行JS和页面渲染。包含3个线程：Compositor Thread、Tile Worker、Main thread，后文会介绍这三个线程。
  * GPU进程  
整个浏览器共用一个。主要是负责把Renderer进程中绘制好的tile位图作为纹理上传至GPU，并调用GPU的相关方法把纹理draw到屏幕上（一般的介绍浏览器渲染引擎的文章里都用paint这个词表述把内容光栅化和绘制到位图里，而用draw这个词表示GPU最终把纹理显示到屏幕上），所以这个CPU里的进程更应该称为“负责跟GPU打交道的进程”，不要像我之前一样因为不懂GPU以为是GPU里的一个进程, mdzz。GPU进程里只有一个线程：GPU Thread。

#### Renderer进程的三个线程

  * Compositor Thread  
这个线程既负责接收浏览器传来的垂直同步信号(Vsync，水平同步表示画出一行屏幕线，垂直同步就表示从屏幕顶部到底部的绘制已经完成，指示着前一帧的结束，和新一帧的开始)， 也负责接收OS传来的用户交互，比如滚动、输入、点击、鼠标移动等等。  
如果可能，Compositor Thread会直接负责处理这些输入，然后转换为对layer的位移和处理，并将新的帧直接commit到GPU Thread，从而直接输出新的页面。否则，比如你在滚动、输入事件等等上注册了回调，又或者当前页面中有动画等情况，那么这个时候Compositor Thread便会唤醒Main Thread，让后者去执行JS、完成重绘、重排等过程，产出新的纹理，然后Compositor Thread再进行相关纹理的commit至GPU Thread，完成输出。
  * Main Thread  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/ea8fd5a20cf2a611b662c7e829d403de~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
这里大家就很熟悉了，chrome devtools的Timeline里Main那一栏显示的内容就是Main Thread完成的相关任务：某段JS的执行、Recalculate Style、Update Layer Tree、Paint、Composite Layers等等。 
  * Compositor Tile Worker(s)  
可能有一个或多个线程，比如PC端的chrome是2个或4个，安卓和safari为1个或2个不等。是由Compositor Thread创建的，专门用来处理tile的Rasterization（前文说过的光栅化）。

可以看到Compositor Thread是一个很核心的东西，后面的俩线程都是由他主要进行控制的。  
同时，用户输入是直接进入Compositor Thread的，一方面在那些不需要执行JS或者没有CSS动画、不重绘等的场景时，可以直接对用户输入进行处理和响应，而Main Thread是有很复杂的任务流程的。这使得浏览器可以快速响应用户的滚动、打字等等输入，完全不用进主线程。这里也有一个非常重要的点，后文会说。  
再者，即使你注册了UI交互的回调，进了主线程，或者主线程很卡，但是因为Compositor Thread在他外面拦着，所以Compositor Thread依然可以直接负责将下一帧输出到页面上，因此即使你的主线程可能执行着高耗任务，超过16ms，但是你在滚动页面时浏览器还是能做出响应的（同步AJAX等特殊任务除外），所以比如你有一个比较卡的动画（动画的预先计算过程或者重绘过程超过16ms每帧），但是你滚动页面是非常流畅的，也就是动画卡而滚动不卡([随便给你个demo自己试试看](<https://link.juejin.cn?target=http%3A%2F%2Fcodepen.io%2FSitePoint%2Fpen%2FWQVxQQ%2F> "http://codepen.io/SitePoint/pen/WQVxQQ/"))。

### 具体流程

一般我们在devtools的Timeline里大概会看到如下过程:  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/7bf4ceeea1ed7e637e44eabce47132a8~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
也就是JS执行后触发重绘重排等操作。这里着重分析背后的运行过程，即下面这副图：  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/9411794cdd8fcb055db322d71dcd8f17~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
图里后半部分有两处commit，分别是主线程通知Main Thread可以执行光栅化了，以及光栅化完成、纹理生成完毕，Compositor Thread通知GPU Thread可以将纹理按照指定的参数draw到屏幕上。

#### 整体流程：

  1. Vsync  
接收到Vsync信号，这一帧开始
  2. Input event handlers  
之前Compositor Thread接收到的用户UI交互输入在这一刻会被传入给主线程，触发相关event的回调。

> All input event handlers (touchmove, scroll, click) should fire first, once per frame, but that’s not necessarily the case; a scheduler makes best-effort attempts, the success of which varies between Operating Systems. 

这意味着，尽管Compositor Thread能在16ms内接收到OS传来的多次输入，但是触发相应事件、传入到主线程被JS感知却是每帧一次，甚至可能低于每帧一次。也就是说touchmove、mousemove等事件最快也就每帧执行一次，所以自带了相对于动画的节流效果！如果你的主线程有动画之类的卡了一点，事件触发频率非常可能低于16ms。我在最开始关于渲染时机的内容中说了scroll和resize因为和渲染处于同一轮次，所以最快也就每帧执行一次，**现在来看，不仅仅是scroll和resize！连touchmove、mousemove等事件，由于Compositor Thread的机制原因，也依然如此** ！  
[详见这个jsfiddle](<https://link.juejin.cn?target=https%3A%2F%2Fjsfiddle.net%2Fstqk5dpz%2F> "https://jsfiddle.net/stqk5dpz/")，大家可以试试，你可以发现mousemove回调和requestAnimationFrame回调的调用频率是完全一致的，mousemove的执行次数跟raf执行次数一模一样，**永远** 没有任何一次出现mousemove执行两次而rAF还没有执行一次的情况发生。另外两次执行间隔在14到20毫秒之间，主要是因为帧的间隔不会精确到16.666毫秒哈，基本是14ms~20ms之间大致波动的，大家可以打开timeline观察。 _另外有个挺奇怪的现象是每次鼠标从devtool移回页面区域里的时候，会非常快的触发两次mousemove（间隔有时小于5ms），虽然依然每次mousemove后依然紧跟raf，这意味着非常快速的触发了两帧。_

  3. requestAnimationFrame  
图中的红线的意思是你可能会在JS里[Force Layout](<https://link.juejin.cn?target=http%3A%2F%2Fgent.ilcore.com%2F2011%2F03%2Fhow-not-to-trigger-layout-in-webkit.html> "http://gent.ilcore.com/2011/03/how-not-to-trigger-layout-in-webkit.html")，也就是我们说的访问了scrollWidth、clientHeight、ComputedStyle等触发了强制重排，导致Recalc Styles和Layout前移到代码执行过程当中。
  4. parse HTML  
如果有DOM变动，那么会有解析DOM的这一过程。
  5. Recalc Styles  
如果你在JS执行过程中修改了样式或者改动了DOM，那么便会执行这一步，重新计算指定元素及其子元素的样式。
  6. Layout  
我们常说的重排reflow。如果有涉及元素位置信息的DOM改动或者样式改动，那么浏览器会重新计算所有元素的位置、尺寸信息。而单纯修改color、background等等则不会触发重排。详见[css-triggers](<https://link.juejin.cn?target=https%3A%2F%2Fcsstriggers.com%2F> "https://csstriggers.com/")。
  7. update layer tree  
这一步实际是更新Render Layer的层叠排序关系，也就是我们之前说的为了搞定层叠上下文搞出的那个东西，因为之前更新了相关样式信息和重排，所以层叠情况也可能变动。
  8. Paint  
其实Paint有两步，第一步是记录要执行哪些绘画调用，第二步才是执行这些绘画调用。第一步只是把所需要进行的操作记录序列化进一个叫做SkPicture的数据结构里:

> The SkPicture is a serializable data structure that can capture and then later replay commands, similar to a [display list](<https://link.juejin.cn?target=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FDisplay_list> "https://en.wikipedia.org/wiki/Display_list").

这个SkPicture其实就一个列表，记录了你的commands。接下来的第二步里会将SkPicture中的操作replay出来，这里才是将这些操作真正执行：光栅化和填充进位图。主线程中和我们在Timeline中看到的这个Paint其实是Paint的第一步操作。第二步是后续的Rasterize步骤（见后文）。

  9. Composite  
主线程里的这一步会计算出每个Graphics Layers的合成时所需要的data，包括位移（Translation）、缩放（Scale）、旋转（Rotation）、Alpha 混合等操作的参数，并把这些内容传给Compositor Thread，然后就是图中我们看到的第一个commit：Main Thread告诉Compositor Thread，我搞定了，你接手吧。然后主线程此时会去执行requestIdleCallback。这一步并没有真正对Graphics Layers完成位图的composite。
  10. Raster Scheduled and Rasterize  
第8步生成的SkPicture records在这个阶段被执行。

> SkPicture records on the compositor thread get turned into bitmaps on the GPU in one of two ways: either painted by Skia’s software rasterizer into a bitmap and uploaded to the GPU as a texture, or painted by Skia’s OpenGL backend (Ganesh) directly into textures on the GPU.

可以看出Rasterization其实有两种形式：

     * 一种是基于CPU、使用Skia库的Software Rasterization，首先绘制进位图里，然后再作为纹理上传至GPU。这一方式中，Compositor Thread会spawn出一个或多个Compositor Tile Worker Thread，然后多线程并行执行SkPicture records中的绘画操作，以之前介绍的Graphics Layer为单位，绘制Graphics Layer里的Render Object。同时这一过程是将Layer拆分为多个小tile进行光栅化后写入进tile对应的位图中的。
     * 另一种则是基于GPU的Hardware Rasterization，也是基于Compositor Tile Worker Thread，也是分tile进行，但是这个过程不是像Software Rasterization那样在CPU里绘制到位图里，然后再上传到GPU中作为纹理。而是借助Skia’s OpenGL backend (Ganesh) 直接在GPU中的纹理中进行绘画和光栅化，填充像素。也就是我们常说的GPU Raster。

现在基本最新版的几大浏览器都是硬件Rasterization了，但是对于一些移动端基本还是Software Rasterization较多。打开你的chrome浏览器输入chrome://gpu/ 可以看看你的chrome的GPU加速情况。下图是我的：  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/86c27d041cff26d4905f9487120580d1~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
使用Hardware Rasterization的好处在于：以往Software Rasterization的方式，受限于CPU和GPU之前的上传带宽，把位图从RAM里上传到GPU的VRAM里的过程是有不可忽视的性能开销的。若Rasterization的区域较大，那么使用Software Rasterization很可能在这里出现卡顿。下面这个例子是Chrome32和Chrome41的对比，后者的版本实现了Hardware Rasterization。  

不过，对于图片、canvas等情况，我没有查到到底是怎么处理的，但是我觉得绝对是有一个从CPU上传到GPU的过程的，所以应该有一些情况不是纯Hardware Rasterization的，两者应该是结合使用的。另外就是硬件还是软件Rasterization主要还是由设备决定的，在这个地方并没有我们手动优化的空间，但是这里涉及到一些后面的内容，所以简单介绍了一下。

  11. commit  
如果是Software Rasterization，所有tile的光栅化完成后Compositor Thread会commit通知GPU Thread，于是所有的tile的位图都会作为纹理都会被GPU Thread上传到GPU里。如果是使用GPU 的Hardware Rasterization，那么此时纹理都已经在GPU中。接下来，GPU Thread会调用平台对应的3D API(windows下是[D3D](<https://link.juejin.cn?target=http%3A%2F%2Fbaike.baidu.com%2Flink%3Furl%3DiukraGeY0dHYga0DQD-SbwQ9az37FcXwzhd0j_cFsGTEiKjOa8Q74T9i-I11webzQ1HtjjVDq_zYugxMDsuRUa> "http://baike.baidu.com/link?url=iukraGeY0dHYga0DQD-SbwQ9az37FcXwzhd0j_cFsGTEiKjOa8Q74T9i-I11webzQ1HtjjVDq_zYugxMDsuRUa")，其他平台都是GL)，把所有纹理绘制到最终的一个位图里，从而完成纹理的合并。  
同时，非常关键的一点：在纹理的合并时，借助于3D API的相关合成参数，可以在合并前对纹理transformations（也就是之前提到的位移、旋转、缩放、alpha通道改变等等操作），先变形再合并。合并完成之后就可以将内容呈现到屏幕上了。

并不是每次渲染都会执行上述11步的所有步骤，比如Layout、Paint、Rasterize、commit可能一次都没有，但是Layout又可能会不止一次。另外还有利用合成层提升来获得GPU加速的动画等相关技术的原理。接下里就是对上述步骤更加详细的分析。

### 重排 Layout、强制重排 Force Layout

重排和强制重排是老生常谈的东西了，大家也应该非常熟悉了，但在这里可以结合浏览器机制顺带讲一遍。

首先，如果你改了一个影响元素布局信息的CSS样式，比如width、height、left、top等（transform除外），那么**浏览器会将当前的Layout标记为dirty** ，这会使得浏览器在**下一帧** 执行上述11个步骤的时候执行Layout。因为元素的位置信息变了，将可能会导致整个网页其他元素的位置情况都发生改变，所以需要执行Layout全局重新计算每个元素的位置。

需要注意到，浏览器是在下一帧、下一次渲染的时候才重排。并不是JS执行完这一行改变样式的语句之后立即重排，所以你可以在JS语句里写100行改CSS的语句，但是只会在下一帧的时候重排一次。

**如果你在当前Layout被标记为dirty的情况下，访问了offsetTop、scrollHeight等属性，那么，浏览器会立即重新Layout，计算出此时元素正确的位置信息，以保证你在JS里获取到的offsetTop、scrollHeight等是正确的。**

_会触发重排的属性和方法:_  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/75447d28e3d890c3b8643e125bb43ab8~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

这一过程被称为强制重排 Force Layout，这一过程强制浏览器将本来在上述渲染流程中才执行的Layout过程**前提** 至JS执行过程中。前提不是问题，问题在于每次你在Layout为dirty时访问会触发重排的属性，都会Force Layout，这极大的延缓了JS的执行效率。

    //Layout未dirty 访问domA.offsetWidth不会Force Layout
    domA.style.width = (domA.offsetWidth + 1) + 'px' 
    //Layout已经dirty， Force Layout
    domB.style.width = (domB.offsetWidth + 1) + 'px' 
    //Layout已经dirty， Force Layout
    domC.style.width = (domC.offsetWidth + 1) + 'px'

这三行代码的后两行都导致了Force Layout，Layout一次的时间视DOM数量级从几十微秒到十几毫秒不等，相比于一行JS 1微秒不到的执行时间，这个开销是难以接受的。所以也就有了读写分离、纯用变量存储等避免Force Layout的方法。否则你就会在你Timeline里看到这种10多次Recalculate Style 和 Layout的画面了。

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/c871115a1aa68c40c3bf07f78caf48d4~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

另外，**每次重排或者强制重排后，当前Layout就不再dirty** 。所以你再访问offsetWidth之类的属性，并不会再触发重排。

    // Layout未dirty 访问多少次都不会触发重排
    console.log(domA.offsetWidth) 
    console.log(domB.offsetWidth) 

    //Layout未dirty 访问domA.offsetWidth不会Force Layout
    domA.style.width = (domA.offsetWidth + 1) + 'px' 
    //Layout已经dirty， Force Layout
    console.log(domC.offsetWidth) 

    //Layout不再dirty，不会触发重排
    console.log(domA.offsetWidth) 
    //Layout不再dirty，不会触发重排
    console.log(domB.offsetWidth)

### 重绘 Paint

重绘也是相似的，一旦你更改了某个元素的会触发重绘的样式，那么浏览器就会在下一帧的渲染步骤中进行重绘。也即一些介绍重绘机制中说的invalidating(作废)，JS更改样式导致某一片区域的样式作废，从而在一下帧中重绘invalidating的区域。

但是，有一个非常关键的行为，就是：**重绘是以合成层为单位的** 。也即 **invalidating的既不是整个文档，也不是单个元素，而是这个元素所在的合成层** 。当然，这也是将渲染过程拆分为Paint和Compositing的初衷之一：

> Since painting of the layers is decoupled from compositing, invalidating one of these layers only results in repainting the contents of that layer alone and recompositing.

这里给出两个demo: [demo1](<https://link.juejin.cn?target=http%3A%2F%2Fchuckliu.me%2Fdemo%2Fbrowser-rendering-process%2Fpainting-with-compositing-layer.html> "http://chuckliu.me/demo/browser-rendering-process/painting-with-compositing-layer.html") 和 [demo2](<https://link.juejin.cn?target=http%3A%2F%2Fchuckliu.me%2Fdemo%2Fbrowser-rendering-process%2Fpainting-without-compositing-layer.html> "http://chuckliu.me/demo/browser-rendering-process/painting-without-compositing-layer.html")

两个demo几乎完全一样，除了第二demo的.ab-right的样式里多了一行，`will-change:transform;`。 _我们在前文介绍合成层的时候强调过`will-change: transform`会让元素强制提升为合成层。_

    .ab-right {
            will-change: transform; //多了这行
            position: absolute;
            right: 0;
    }

于是在第二个demo中出现了两个合成层：HTML根元素的合成层和.ab-right所在的合成层。

然后我们在js中修改了#target元素的样式，于是#target元素在的合成层(即HTML根元素的合成层)被重绘。在demo1中，.ab-right元素没有被提升为合成层，于是.ab-right也被重绘了。而在demo2中，.ab-right元素并没有重绘。先看demo1:

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/1c9cd1a43487260536945bd1b735f655~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
明显的看到.ab-right被重绘了。

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/2b1157cfa498500a8b4470c27e8ac04f~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
显然，demo2只重绘了HTML根元素的合成层的内容。

对了，你还可以顺便点到Raster一栏去看看Rasterization的具体过程。前面已经介绍过了，这里真正完成Paint里的操作，将内容绘制进位图或纹理中，且是分tile进行的。  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/08fcc3cf388f89c12670e868d9912d2f~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

### 重排和重绘和Compositing

先说点题外的，怎么查看合成层:

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/642a28356d1292fc2aafdb3051f134b6~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

修改一些CSS属性如width、float、border、position、font-size、text-align、overflow-y等等会触发重排、重绘和合成，修改另一些属性如color、background-color、visibility、text-decoration等等则不会触发重排，只会重绘和合成，具体属性列表请自行google。

接下来很多文章里就会说，**修改opacity、transform这两个属性仅仅会触发合成，不会触发重绘和合成。** 所以一定要用这两个属性来实现动画，没有重绘重排，效率很高。

**然而事实并不是这样。**

**只有一个元素在被提升为合成层之后，上述情况才成立。**

回到我们之前说的渲染过程的第11步:

> 同时，非常关键的一点：在纹理的合并时，借助于3D API的相关合成参数，可以在合并前对纹理transformations（也就是之前提到的位移、旋转、缩放、alpha通道改变等等操作），先变形再合并。合并完成之后就可以将内容呈现到屏幕上了。

在合成多个合成层时，确实可以借助3D API的相关参数，从而直接实现合成层的transform、opacity效果。所以如果你将一个元素提升为合成层，然后用JS修改其transform或opacity 或者在 transform或opacity 上施加CSS过渡或动画，确实会避免CPU的Paint过程，因为transform和opacity可以直接基于GPU的合成参数来完成。

但是，这是在合成层整体有transform或opacity才会这么做。对于没有提升为合成层的元素，仅仅是他自己具有transform和opacity，他是作为合成层的内容。而生成合成层的内容和写进位图或纹理是在Paint和Rasterize阶段完成的，因此这个元素的transform和opacity的实现也是在Paint和Rasterize中完成的。所以还是会重排，也就没有启用我们常说的GPU加速的动画。

比如[这个demo](<https://link.juejin.cn?target=http%3A%2F%2Fchuckliu.me%2Fdemo%2Fbrowser-rendering-process%2Fchange-transform.html> "http://chuckliu.me/demo/browser-rendering-process/change-transform.html")，一个提升为合成层的div#father和一个未提升合成层的div#child，3秒钟后JS更改child和father的transform属性。 接下来渲染的时候流程是怎样的？

  1. Recalc Styles(重新计算样式) 
  2. Paint 绘制变动的合成层 即 div#father 
     1. Paint 绘制父元素的背景和textNode(即”父元素 提升为合成层”)
     2. Paint 绘制child元素 即div#child 
        1. Paint 先translate，完成移动
        2. Paint 再在移动后的区域里绘制子元素的背景和textNode(即”子元素 未提升为合成层”)
  3. Rasterize 
  4. Composite 合并合成层，在合成时借助于3D API的相关合成参数完成合成层的位移、旋转等变换，所以div#father的translate在这里实现

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/436392c406c5b25aac8f553d5349a8f6~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

所以我们看到了，对于未提升合成层的元素，他的transform、opacity等是在主线程里Paint和配合Rasterize来实现的（其他的需要重绘的属性更是如此），依然会触发重绘，直接用JS改动这俩属性并不会获得性能提升。而如果元素已提升为合成层，那么他的transform、opacity等样式的实现就是直接由GPU Thread控制在GPU中Compositing来完成的，主线程的Composite步骤只是计算出合成的参数，耗时极小，速度极快，所以因此就有了尽量使用transform和opacity来完成动画的经验之谈。

借用[这篇文章中的例子](<https://link.juejin.cn?target=http%3A%2F%2Fblogs.adobe.com%2Fwebplatform%2F2014%2F03%2F18%2Fcss-animations-and-transitions-performance%2F> "http://blogs.adobe.com/webplatform/2014/03/18/css-animations-and-transitions-performance/"):

    div {
        height: 100px;
        transition: height 1s linear;
    }

    div:hover {
        height: 200px;
    }

这段transition的实现过程是这样的:  
![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/8eb3c69eb877ca499fe3c270dce3bfe5~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

而如果代码变成了这样

    div {
        transform: scale(0.5);
        transition: transform 1s linear;
    }

    div:hover {
        transform: scale(1.0);
    }

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/d614b2d0ecbe2eebb803ffc2642163a4~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)  
也就是Main Thread不用重排，不用重绘，Draw也不是他完成的，他的Composite步骤只是计算出具体的Compositing参数而已（示例中其实右边应该是Compositor和GPU Thread，但是作者为了简化概念、便于阐述，直接就没有提GPU Thread，大家不要在此处扣细节）。

另外，第二个例子中div为什么提升为合成层，其实就是前文介绍合成层的时候说的：

> 对 opacity、transform、fliter、backdropfilter 应用了 animation 或者 transition（需要是 active 的 animation 或者 transition，当 animation 或者 transition 效果未开始或结束后，提升合成层也会失效）

括号中的内容也很关键，元素在opacity等属性具有动画时，并不是直接就提升为合成层，而是动画或者transition开始时才提升为合成层，并且结束后提升合成层也失效。  
同时，元素在提升为合成层或者提升合成层失效时，会触发重绘。这也是上图一开始在动画开始前有`Layout the element first time` 和`Paint the element into the bitmap`两步的原因：transition开始前，div并未被提升为合成层，transition开始，div立马提升合成层，立马导致其本来所在的合成层重绘（因为要剔除掉提升为合成层的div），并且div因为提升为合成层，也立马重绘，两个重绘好的合成层Rasterize后上传至GPU中。

[demo在此](<https://link.juejin.cn?target=http%3A%2F%2Fchuckliu.me%2Fdemo%2Fbrowser-rendering-process%2Fpaint-before-and-after-transition.html> "http://chuckliu.me/demo/browser-rendering-process/paint-before-and-after-transition.html")，所以在动画开始前看到：

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/e6b92229962c306c0a22c8b712dced2b~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

在动画结束后的那一帧则是这样:

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/6704b5f08c1b9a7ecc0048c4aa0c8304~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

这个上述demo中，只有2个dom，所以Paint开销几乎可以忽略，但是如果是dom数量多一些，那么就很可能是下面这样了。

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/5/2/806aba32a3981265b8ddcdefecadba31~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

实时上这个情况不止是在动画和过渡时，只要一个元素被提升为合成层，在提升前和合成层失效时都会有这个过程，所以一方面是重绘带来了绘制开销，另外则是纹理上传过程因为CPU到GPU的带宽带来的上传开销（虽然现在已经有Hardware Raster不用上传，但是仍然有不能用Hardware Raster的情况，而且Hardware Raster绘制进纹理的绘制过程本身也是有开销的）。 因此处理不好就可能导致动画开始前和开始后出现一帧卡顿/延迟。

最后，重要的一点，也是一般谈到性能优化的文章中都会介绍的一点，即：

> **合成层提升并非银弹。**

合成层提升一方面可能会引入纹理生成、上传和重绘的开销，而且合成层提升后会占用GPU VRAM，VRAM可并不会很大。对于移动端，上述两个问题尤甚。而且在介绍合成层时，我还介绍了合成层存在隐式提升的情况。因此请合理使用。

本文主要介绍原理，所以怎么去实现16ms的动画、怎么去提升渲染性能、怎么去优化合成层数量和避免层爆炸等等、以及到底哪些情况会提升合成层、触发重绘等详细内容还是见文末附录吧。

## 总结

正文算是比较详细的介绍浏览器的渲染过程，可能需要你事先理解重绘、重排和合成，结合了一些demo，深入了一些我之前理解错的点。

这里再次强调一下一些颠覆了我认知的内容：

  * 按照HTML5标准，scroll事件是每帧触发一次的，自带requestAnimationFrame节流效果
  * 按照Blink和Webkit引擎实现，touchmove、mousemove等UI input由Compositor线程接收，但传入到主线程是每帧一次，也自带requestAnimationFrame节流效果
  * 重绘是以合成层为单位的
  * 合成层提升前后的Paint步骤

_三周前就第一次发布的文章终于在五一节的假期里搞定。呼…._

## 参考资料

### chromium官方资料

### 渲染机制

### 实操&&性能优化
