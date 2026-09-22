# 小 tip: 纯 CSS 实现视差滚动效果

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.zhangxinxu.com/wordpress/2015/03/css-only-parallax-effect/>
> 对应题目：CSS 第 13 题 · 视差滚动
> 抓取时间：2026-09-22

---

by [zhangxinxu](<http://www.zhangxinxu.com/>) from [http://www.zhangxinxu.com](<http://www.zhangxinxu.com/>)  
本文地址：<http://www.zhangxinxu.com/wordpress/?p=4720>

### 一、效果Demo先行~

视差滚动效果大家可能都听过，基本上都是JS实现的，有对应插件 – [Parallax.js](<https://github.com/search?utf8=%E2%9C%93&q=Parallax.js>).

实际上，如果你对兼容性要求不是很高，比方说忽略IE浏览器，则我们使用简单的几行CSS代码就可以实现视差滚动效果了。

对于效果展示，先看效果是最能引起兴趣，激发学习热情的，如下(IE9+)：  

您可以狠狠地点击这里：[纯CSS实现的视差滚动效果Demo](<http://www.zhangxinxu.com/study/201503/css-parallax-effect-demo.html>)

进入Demo滚动滚动条，最好鼠标慢慢拖动，效果更明显——表情花朵等小图标在手机图片上方飞动的视差感觉。目前，Chrome以及FireFox等浏览器（不包括IE11在内的浏览器）都是有效果。

### 二、CSS实现的原理

原理说透了很简单，下面几个关键CSS声明起的作用（红色高亮部分）：

    .container {
        /* 滚动容器 */
        perspective: 1px; 
        padding: 0; height: calc(100vh - 300px); overflow: auto;
    }
    .box {
        /* 视差元素的父级需要3D视角 */
        height: 1280px;
        transform-style: preserve-3d;
        position: relative;
    }
    .background {
        /* 滚动比较慢的背景元素 */
        position: absolute; left: 50%;
        transform: translate3D(-50%, -120px, -1px) scale(2);
    }

大家可以注意上面红色高亮代码出现了一个`1px`(来自`perspective`), 一个`-1px`(来自`transform`)以及`scale(2)`中的`2`. 这几个数字之间有什么关系呢？

我们先看下面这个3D视角示意图(来自[这里](<https://css-tricks.com/tour-performant-responsive-css-site/>))：  
![视角示意图](https://image.zhangxinxu.com/image/blog/201503/css3d-edited.png)

当我们在屏幕前面`1`个单位的地方，看屏幕后面`1`个单位的元素，肉眼所见的画面大小只有实际的`1/2`，即所谓的近大远小。此时`scale(2)`让内容放大到原来2倍，正好在平面上看上去好像是原来大小。

虽然肉眼所见体积似乎是`1:1`，但是，滚动时候的位移变化还是`1:2`, 应该很好理解。举个极端的例子，我们坐在电瓶车上看天上的月亮，虽然车子在40码的速度奔啊奔，但是，好像月亮的位置没有移动，一直就在头顶。网页中的3D就是模拟真实世界的3D效果，因此，也会有这种视差体验。

或者这么讲吧，CSS3 3D天然视差效果，滚动，只是视差体现的一个触发条件。

于是，亲爱的同学。如果你想实现3层视差滚动怎么办？很简单，来个`transform: translateZ(-2px)`试试~

### 三、结语

据我测试，直接`body`或`html`滚动似乎难以实现视差滚动效果，不过天色已晚，我没深究，有兴趣的小伙伴可以研究分享下。

OK, 就像绚烂惊奇的魔术，解密之后，会发现不过尔尔。不知你成功解密了CSS视差滚动的秘密了没？

![发牌魔术](https://image.zhangxinxu.com/image/blog/201906/poke-s.gif)

感谢阅读，欢迎交流！

本文为原创文章，会经常更新知识点以及修正一些错误，因此转载请保留原出处，方便溯源，避免陈旧错误知识的误导，同时有更好的阅读体验。  
本文地址：<http://www.zhangxinxu.com/wordpress/?p=4720>

（本篇完）

相关文章

  * [纯CSS实现微信列表左滑显示按钮的交互效果](<https://www.zhangxinxu.com/wordpress/2020/12/css-touch-scroll-show-button/>) (0.755)
  * [杀了个回马枪，还是说说position:sticky吧](<https://www.zhangxinxu.com/wordpress/2018/12/css-position-sticky/>) (0.590)
  * [好吧，CSS3 3D transform变换，不过如此！](<https://www.zhangxinxu.com/wordpress/2012/09/css3-3d-transform-perspective-animate-transition/>) (0.410)
  * [CSS CSS3实现3D开门动画效果](<https://www.zhangxinxu.com/wordpress/2018/06/css-css3-3d-open-door-animation/>) (0.410)
  * [Safari 3D transform变换z-index层级渲染异常的研究](<https://www.zhangxinxu.com/wordpress/2016/08/safari-3d-transform-z-index/>) (0.398)
  * [直线等图形3D穿过文字的CSS实现](<https://www.zhangxinxu.com/wordpress/2021/02/css-3d-through/>) (0.398)
  * [第五届CSS大会主题分享之CSS创意与视觉表现](<https://www.zhangxinxu.com/wordpress/2019/06/cssconf-css-idea/>) (0.227)
  * [理解CSS3 transform中的Matrix(矩阵)](<https://www.zhangxinxu.com/wordpress/2012/06/css3-transform-matrix-%e7%9f%a9%e9%98%b5/>) (0.184)
  * [photon-3D光线引擎项目展示与介绍](<https://www.zhangxinxu.com/wordpress/2012/06/photon-3d-css3-animate-light/>) (0.184)
  * [SVG特征、支持以及一些实际使用问题](<https://www.zhangxinxu.com/wordpress/2012/08/svg-feature-support-bugs/>) (0.184)
  * [-webkit-text-stroke文字描边CSS属性及展开](<https://www.zhangxinxu.com/wordpress/2017/06/webkit-text-stroke-css-text-shadow/>) (RANDOM - 0.012)
