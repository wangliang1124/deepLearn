## JS 深入

1. 浅谈 instanceof 和 typeof 的实现原理
    > 浅谈 instanceof 和 typeof 的实现原理 https://juejin.im/post/5b0b9b9051882515773ae714
2. Symbol 类型在实际开发中的应用、可手动实现一个简单的 Symbol
    > ES6 系列之模拟实现 Symbol 类型 https://github.com/mqyqingfeng/Blog/issues/87
    > Symbol http://es6.ruanyifeng.com/#docs/symbol
3. JavaScript 中的变量在内存中的具体存储形式
    > 前端基础进阶：详细图解 JavaScript 内存空间 https://juejin.im/entry/589c29a9b123db16a3c18adf
4. 描述 new 一个对象的详细过程，手动实现一个 new 操作符
    ```js
        function new(func) {
            let target = {};
            target.__proto__ = func.prototype;
            let res = func.call(target);
            if (typeof(res) == "object" || typeof(res) == "function") {
                return res;
            }
            return target;
        }
    ```
    > JavaScript 深入之 new 的模拟实现 https://github.com/mqyqingfeng/Blog/issues/13
5. 理解 es6 class 构造以及继承的底层实现原理

6. this 的原理以及几种不同使用场景的取值

7. 闭包的实现原理和作用，可以列举几个开发中闭包的实际应用

8. 为何 try 里面放 return，finally 还会执行，理解其内部机制

9. JavaScript 如何实现异步编程，可以详细描述 EventLoop 机制

    > JavaScript 运行机制详解：再谈 Event Loop http://www.ruanyifeng.com/blog/2014/10/event-loop.html

    > JavaScript：彻底理解同步、异步和事件循环(Event Loop) https://segmentfault.com/a/1190000004322358

10. 微任务、宏任务与 Event-Loop
    > 微任务、宏任务与 Event-Loop https://juejin.im/post/5b73d7a6518825610072b42b
11. 你不知道的 javascript 之 Object.create 和 new 区别

    > 你不知道的 javascript 之 Object.create 和 new 区别 https://blog.csdn.net/blueblueskyhua/article/details/73135938

12. JavaScript 学习笔记：视口宽高、位置与滚动高度

    > https://www.qdskill.com/javascript/1063.html

13. 描述一种 JavaScript 中实现 memoization(避免重复运算)的策略。[进阶]
    > 从斐波那契数列求值优化谈 \_.memoize 方法 https://github.com/hanzichi/underscore-analysis/issues/23 <br>
    > 斐波那契数列求和的 js 方案以及优化 https://segmentfault.com/a/1190000007115162 <br>
    > 性能优化：memoization http://taobaofed.org/blog/2016/07/14/performance-optimization-memoization/ <br>
    > Faster JavaScript Memoization For Improved Application Performance https://addyosmani.com/blog/faster-javascript-memoization/ <br>
14. Promise

    > Promise 原理浅析 http://imweb.io/topic/565af932bb6a753a136242b0

    > 解读 Promise 内部实现原理 https://juejin.im/post/5a30193051882503dc53af3c#heading-0

15. JavaScript 编码规范

    > JavaScript 编码规范 https://github.com/fex-team/styleguide/blob/master/javascript.md

    > Airbnb JavaScript Style Guide https://github.com/airbnb/javascript

16. 如何将浮点数点左边的数每三位添加一个逗号，如 12000000.11 转化为『12,000,000.11』?
    ```javascript
    function commafy(num) {
        return (
            num &&
            num.toString().replace(/(\d)(?=(\d{3})+\.)/g, function($1, $2) {
                return $2 + ",";
            })
        );
    }
    let milliFormat = input => {
        return input && input.toString().replace(/(^|\s)\d+/g, m => m.replace(/(?=(?!\b)(\d{3})+$)/g, ","));
    };
    console.log(milliFormat(1200000123123.223));
    ```
    > 千位分隔符的完整攻略 https://www.tuicool.com/articles/ArQZfui
17. 如何实现数组的随机排序？
    > 数组乱序 https://github.com/hanzichi/underscore-analysis/issues/15
18. Javascript 如何实现继承？

    > http://www.cnblogs.com/humin/p/4556820.html

19. javascript 创建对象的几种方式?
    - 1、对象字面量的方式
    ```javascript
    person = { firstname: "Mark", lastname: "Yun", age: 25, eyecolor: "black" };
    ```
    - 2、用 function 来模拟无参的构造函数
    ```javascript
    function Person() {}
    var person = new Person(); //定义一个function，如果使用new"实例化",该function可以看作是一个Class
    person.name = "Mark";
    person.age = "25";
    person.work = function() {
        alert(person.name + " hello...");
    };
    person.work();
    ```
    - 3、用 function 来模拟参构造函数来实现（用 this 关键字定义构造的上下文属性）
    ```javascript
    function Pet(name, age, hobby) {
        this.name = name; //this作用域：当前对象
        this.age = age;
        this.hobby = hobby;
        this.eat = function() {
            alert("我叫" + this.name + ",我喜欢" + this.hobby + ",是个程序员");
        };
    }
    var maidou = new Pet("麦兜", 25, "coding"); //实例化、创建对象
    maidou.eat(); //调用eat方法
    ```
    - 4、用工厂方式来创建（内置对象）
    ```javascript
    var wcDog = new Object();
    wcDog.name = "旺财";
    wcDog.age = 3;
    wcDog.work = function() {
        alert("我是" + wcDog.name + ",汪汪汪......");
    };
    wcDog.work();
    ```
    - 5、用原型方式来创建
    ```javascript
    function Dog() {}
    Dog.prototype.name = "旺财";
    Dog.prototype.eat = function() {
        alert(this.name + "是个吃货");
    };
    var wangcai = new Dog();
    wangcai.eat();
    ```
    - 6、用混合方式来创建
    ```javascript
    function Car(name, price) {
        this.name = name;
        this.price = price;
    }
    Car.prototype.sell = function() {
        alert("我是" + this.name + "，我现在卖" + this.price + "万元");
    };
    var camry = new Car("凯美瑞", 27);
    camry.sell();
    ```
20. 写一个通用的事件侦听器函数
    > javascript 通用事件封装 http://www.cnblogs.com/isaboy/p/eventJavascript.html
21. 哪些操作会造成内存泄漏？

    > 4 种 JavaScript 内存泄漏浅析及如何用谷歌工具查内存泄露 https://github.com/wengjq/Blog/issues/1

    > 4 Types of Memory Leaks in JavaScript and How to Get Rid Of Them https://mp.weixin.qq.com/s/MCmlbI2Z5TAvkCgpqDN4iA

22. 请介绍一下 JS 之事件节流？什么是 JS 的函数防抖？ [进阶]

    > JavaScript 函数节流和函数去抖应用场景辨析 https://github.com/hanzichi/underscore-analysis/issues/20

    > underscore 函数去抖的实现 https://github.com/hanzichi/underscore-analysis/issues/21

    > underscore 函数节流的实现 https://github.com/hanzichi/underscore-analysis/issues/22

23. DOM 操作——怎样添加、移除、移动、复制、创建和查找节点。 [基础]
    > 深入浅出 DOM 基础——《DOM 探索之基础详解篇》学习笔记 https://github.com/jawil/blog/issues/9
24. 如何遍历一个 dom 树
    ```js
    function traversal(node) {
        //对node的处理
        if (node && node.nodeType === 1) {
            console.log(node.tagName);
        }
        var i = 0,
            childNodes = node.childNodes,
            item;
        for (; i < childNodes.length; i++) {
            item = childNodes[i];
            if (item.nodeType === 1) {
                //递归先序遍历子节点
                traversal(item);
            }
        }
    }
    ```
26. 手写代码，简单实现call,apply,bind
    ```js
        // call
        Function.prototype.call2 = function(context, ...args) {
            // 因为传进来的 context 有可能是 null
            context = context || window;
            // Function.prototype this 为当前运行的函数
            // 让 fn 的上下文为 context
            context.fn = this;
            const result = context.fn(...args);
            delete context.fn;
            return result;
        };
        // apply
        Function.prototype.apply2 = function(context, arr) {
            let context = context || window; // 因为传进来的context有可能是null
            context.fn = this;
            arr = arr || [];
            const result = context.fn(...arr); // 相当于执行了context.fn(arguments[1], arguments[2]);
            delete context.fn;
            return result; // 因为有可能this函数会有返回值return
        }
        // bind
        Function.prototype.bind2 = function() {
            var fn = this;
            var argsParent = [...arguments];
            return function() {
                fn.call(...argsParent, ...arguments);
            };
        }
    ```
    > 第 6 题：手写代码，简单实现call https://github.com/airuikun/Weekly-FE-Interview/issues/6
27. 简单手写实现promise
    > 简单手写实现promise https://github.com/airuikun/Weekly-FE-Interview/issues/10
28. 简单实现async/await中的async函数
    > 简单实现async/await中的async函数 https://github.com/airuikun/Weekly-FE-Interview/issues/14
## HTML

1. 浏览器的渲染原理

    > 浏览器的渲染原理简介 https://coolshell.cn/articles/9666.html

2. HTML5 离线缓存原理

    > HTML5 离线缓存-manifest 简介 http://yanhaijing.com/html/2014/12/28/html5-manifest/

    > HTML5 离线存储 初探 http://www.cnblogs.com/chyingp/archive/2012/12/01/explore_html5_cache.html

    > 有趣的 HTML5：离线存储 https://segmentfault.com/a/1190000000732617

3. 如何实现浏览器内多个标签页之间的通信?

    > 多个标签页之间的通信 https://segmentfault.com/q/1010000006664804

    > Storage 事件无法触发解决 https://blog.csdn.net/jlin991/article/details/55855524

4. iframe 异步加载技术及性能

    > iframe 异步加载技术及性能 http://www.cnblogs.com/beiyuu/archive/2011/07/18/iframe-tech-performance.html

5. 页面可见性（Page Visibility API） 可以有哪些用途？

    > HTML5 页面可见性接口应用 https://www.helloweba.net/javascript/390.html

    > Page Visibility(页面可见性) API 介绍、微拓展 http://www.zhangxinxu.com/wordpress/2012/11/page-visibility-api-introduction-extend/

6. Web Worker

    > web worker 详解 http://xgfe.github.io/2017/05/03/LexHuang/web-worker/

    > 深入 HTML5 Web Worker 应用实践：多线程编程 https://www.ibm.com/developerworks/cn/web/1112_sunch_webworker/

    > Web Worker 是什么鬼？ http://www.cnblogs.com/zichi/p/4954328.html

7. PostMessage

    > html5 API postMessage 跨域详解 http://blog.xieliqun.com/2016/08/25/postMessage-cross-domain/

    > HTML5 postMessage 跨域交换数据 http://www.cnblogs.com/zichi/p/4638096.html

    > Window.postMessage() https://developer.mozilla.org/en-US/docs/Web/API/Window

8. 更好的逐帧动画函数 — requestAnimationFrame 简介

    > http://www.cnblogs.com/zichi/p/5208171.html

    > 浅析 requestAnimationFrame https://taobaofed.org/blog/2017/03/02/thinking-in-request-animation-frame/

9. HTML5 File API — 让前端操作文件变的可能

    > http://www.cnblogs.com/zichi/p/html5-file-api.html

    > HTML5 — 让拖放变的流行起来 http://www.cnblogs.com/zichi/p/5080147.html

10. 让 HTML5 来为你定位
    > http://www.cnblogs.com/zichi/p/4975788.html
11. 浏览器缓存知识小结及应用
    > https://www.cnblogs.com/lyzg/p/5125934.html
12. HTML meta 标签总结与属性使用介绍
    > HTML meta 标签总结与属性使用介绍 https://segmentfault.com/a/1190000004279791

## CSS

1. 使用 css 实现一个持续的动画效果
    > 使用 css 实现一个持续的动画效果 http://www.cnblogs.com/gaoxuerong123/p/8540554.html
2. CSS3 box-sizing 详解
    > CSS3 box-sizing 详解https://www.cnblogs.com/iflygofy/p/6323275.html
3. CSS 所有选择器及其优先级
    - CSS 选择符：id 选择器(#myid)、类选择器(.myclassname)、标签选择器(div, h1, p)、相邻选择器(h1 + p)、子选择器（ul > li）、后代选择器（li a）、通配符选择器（\*）、属性选择器（a[rel="external"]）、伪类选择器（a:hover, li:nth-child）
    - !important > 内联 > id > 类 > 标签|伪类|属性 > 伪元素 > 通配符 > 继承
        > css 优先级计算规则 http://www.cnblogs.com/wangmeijian/p/4207433.html
        > 优先级是如何计算的？ https://developer.mozilla.org/zh-CN/docs/Web/CSS/Specificity
        > CSS：你未必知道的@规则 http://chenhaizhou.github.io/2015/06/26/css-at.html
4. 如何居中

    ### 内联元素居中方案

    #### 水平居中设置：

    1. 行内元素: 设置 text-align:center；
    2. Flex 布局: 设置 display:flex;justify-content:center;(灵活运用,支持 Chroime，Firefox，IE9+)

    #### 垂直居中设置：

    1. 单行文本

    - 如果父元素有 height，设置 line-height 与 height 相等即可。 如果没有 height, 设置一个 line-height 即可。

    2. 多行文本或图片

    - a:父元素设置 line-height，子元素 display: inline-block，vertical-align:middle；line-height: 1
    - b:添加一个空标签用于撑开父元素，子元素同上。

    ### 块级元素居中方案

    #### 水平居中设置：

    1. 定宽块状元素

    - 设置 左右 margin 值为 auto；

    2. 不定宽块状元素

    - a:在元素外加入 table 标签（完整的，包括 table、tbody、tr、td），该元素写在 td 内，然后设置 margin 的值为 auto；
    - b:给该元素设置 display:inline-block, 注意空白间距问题 letter-spacing: -4px;
    - c:利用 Transforms，top: 50%; left: 50%; transform: translate(-50%,-50%)

    #### 垂直居中设置：

    - 使用 position:absolute（fixed）,父元素 postion:relative, 子元素设置 margin: auto; position: absolute; top: 0; left: 0; bottom: 0; right: 0;
    - 定宽高，负外边距 margin
    - 使用 css3 的新属性 transform:translate(x,y)属性;
    - 利用 display:table-cell 属性使内容垂直居中;
    - 当做行内元素处理 display:inline-block,使用:before 元素;

    > 盘点 8 种 CSS 实现垂直居中水平居中的绝对定位居中技术 https://blog.csdn.net/freshlover/article/details/11579669

    > css 实现垂直居中 6 种方法 http://www.cnblogs.com/Yirannnnnn/p/4933332.html http://www.cnblogs.com/yugege/p/5246652.html

    > 六种实现元素水平居中https://www.w3cplus.com/css/elements-horizontally-center-with-css.html

5. 掌握一套完整的响应式布局方案

    > 一个满屏品字布局怎么设计？ https://blog.csdn.net/sjinsa/article/details/70903940

    > CSS 常见布局方式 https://juejin.im/post/599970f4518825243a78b9d5

    > CSS 布局解决方案（终结版） https://segmentfault.com/a/1190000013565024?utm_source=channel-hottest#articleHeader2

    > CSS 布局说——可能是最全的 https://segmentfault.com/a/1190000011358507#articleHeader0

    > CSS 布局十八般武艺都在这里了 http://web.jobbole.com/90844/

6. 经常遇到的浏览器的兼容性有哪些？原因，解决方法是什么，常用 hack 的技巧 ？
    > 经常遇到的浏览器兼容性问题 https://blog.csdn.net/oaa608868/article/details/53464517
7. li 与 li 之间有看不见的空白间隔是什么原因引起的？有什么解决办法？
    - 行框的排列会受到中间空白字符的影响，这些空白也会被应用样式，占据空间，所以会有间隔，把字符大小设为 0，就没有空白了。
        > li 与 li 之间有看不见的空白间隔是什么原因引起的？有什么解决办法？ https://blog.csdn.net/sjinsa/article/details/70919546
8. absolute 的 containing block(容器块)计算方式跟正常流有什么不同？

    - 如果 position 属性是 static 或 relative，包含块是最近的块级祖先(例如 inline-block, block, list-item)，此元素的百分比值计算方式为包含块的 content-box 的 width、height
    - 如果 position: absolute, 包含块是最近的 position 值为非 static 元素(fixed,absolute,relative,sticky)，如果都找不到,则为 initial containing block, 百分比计算依据包含块的 padding-box;
    - 如果 position: fixed, 包含块是初始包含块即根元素
    - 如果 position: absolute | fixed，包含块也可以是最近包含以下设置: transform,perspective,will-change: transform | perspective, filter(只在 firefox 起作用)

    > Layout and the containing block https://developer.mozilla.org/en-US/docs/Web/CSS/Containing_block

    > KB008: 包含块( Containing block ) http://w3help.org/zh-cn/kb/008/

9. 对 BFC 规范(块级格式化上下文：block formatting context)的理解？

    > BFC 原理详解 https://segmentfault.com/a/1190000006740129

    > 前端精选文摘：BFC 神奇背后的原理 http://www.cnblogs.com/lhb25/p/inside-block-formatting-ontext.html

    > 理解 CSS 中 BFC https://www.w3cplus.com/css/understanding-block-formatting-contexts-in-css.html

    > 我对 BFC 的理解 http://www.cnblogs.com/dojo-lzz/p/3999013.html

10. 浏览器是怎样解析 CSS 选择器的？

    > CSS 选择器的解析是从右向左解析的。若从左向右的匹配，发现不符合规则，需要进行回溯，会损失很多性能。若从右向左匹配，先找到所有的最右节点，对于每一个节点，向上寻找其父节点直到找到根元素或满足条件的匹配规则，则结束这个分支的遍历。两种匹配规则的性能差别很大，是因为从右向左的匹配在第一步就筛选掉了大量的不符合条件的最右节点（叶子节点），而从左向右的匹配规则的性能都浪费在了失败的查找上面。

    > CSS 选择器从右向左的匹配规则 http://www.cnblogs.com/zhaodongyu/p/3341080.html

11. 元素竖向的百分比设定是相对于容器的高度吗？

    - 当按百分比设定一个元素的宽度时，它是相对于父容器的宽度计算的，但是，对于一些表示竖向距离的属性，例如 padding-top, padding-bottom, margin-top, margin-bottom 等，当按百分比设定它们时，依据的也是父容器的宽度，而不是高度。

    > https://segmentfault.com/a/1190000012955996

12. 全屏滚动的原理是什么？用到了 CSS 的那些属性？

    - 原理：有点类似于轮播，方法一是整体的元素一直排列下去，假设有 5 个需要展示的全屏页面，那么高度是 500% ，只是展示 100%，剩下的可以通过 transform 进行 y 轴定位，也可以通过 margin-top 实现
    - overflow：hidden；transition：all 1000ms ease
        > H5 全屏滑动 https://segmentfault.com/a/1190000003691168

    > iSlider https://github.com/be-fe/iSlider

13. 视差滚动效果，如何给每页做不同的动画？（回到顶部，向下滑动要再次出现，和只出现一次分别怎么做？）

    > 小 tip: 纯 CSS 实现视差滚动效果 http://www.zhangxinxu.com/wordpress/2015/03/css-only-parallax-effect/
    > 视差滚动(Parallax Scrolling)效果的原理和实现 http://www.cnblogs.com/JoannaQ/archive/2013/02/08/2909111.html
    > Alloy Team 的《视差滚动的爱情故事》 http://www.alloyteam.com/2014/01/parallax-scrolling-love-story/

14. 你对 line-height 是如何理解的？

    > 深入理解 CSS 中的行高 http://www.cnblogs.com/rainman/archive/2011/08/05/2128068.html
    > 我对 line-height 及 vertical-align 的一点理解 https://segmentfault.com/a/1190000013031367
    > css 行高 line-height 的一些深入理解及应用 http://www.zhangxinxu.com/wordpress/2009/11/css%E8%A1%8C%E9%AB%98line-height%E7%9A%84%E4%B8%80%E4%BA%9B%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3%E5%8F%8A%E5%BA%94%E7%94%A8/

15. Sticky Footer

    > Sticky Footer, Five Ways https://css-tricks.com/couple-takes-sticky-footer/

16. CSS3 Transform 的 perspective 属性

    > http://www.alloyteam.com/2012/10/the-css3-transform-perspective-property/
    > css3 实践之摩天轮式图片轮播+3D 正方体+3D 标签云（perspective、transform-style、perspective-origin）http://www.cnblogs.com/zichi/p/4318780.html

17. 移动适配方案及相关概念
    > 移动端适配方案(上下) https://github.com/riskers/blog/issues/17


## 网络
1. HTTPS的工作原理
    > HTTPS工作原理https://www.cnblogs.com/xrq730/p/5041921.html
    > HTTPS工作原理 https://cattail.me/tech/2015/11/30/how-https-works.html

## React

## Vue

## 状态管理

## 前端工程
1.  简单实现项目代码按需加载，例如import { Button } from 'antd'，打包的时候只打包button
    > https://github.com/airuikun/Weekly-FE-Interview/issues/9  

## Git