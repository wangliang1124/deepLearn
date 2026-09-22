# css 行高 line-height 的一些深入理解及应用

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.zhangxinxu.com/wordpress/2009/11/css%E8%A1%8C%E9%AB%98line-height%E7%9A%84%E4%B8%80%E4%BA%9B%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3%E5%8F%8A%E5%BA%94%E7%94%A8/>
> 对应题目：CSS 第 14 题 · 理解 line-height
> 抓取时间：2026-09-22

---

by [zhangxinxu](<http://www.zhangxinxu.com/>) from [http://www.zhangxinxu.com](<http://www.zhangxinxu.com/>)  
本文地址：<http://www.zhangxinxu.com/wordpress/?p=384>

补充于2017年12月31日：写本文时本人尚年轻，很多措辞和观点并不严谨，内容仅供参考。更体系更深入的理解在我的[《CSS世界》](<http://www.cssworld.cn/>)这边书中有详细阐述。

### 一、前言

前两天在腾讯ISD团队博客上看到一篇翻译的文章“深入理解CSS行高”（原地址失效已久），是个不错的文章，学到了不少东西，建议您看看。

这里，我也要讲讲我对`line-height`的一些理解，所讲解的东西绝大多数与上面提到的“[深入理解css 行高](<http://webteam.tencent.com/?p=1503>)”是不重复的，可以说是补充或是另外一个角度的思考。另外，将结合实际，展示`line-height`的一些特性和一些常见应用，帮助您对CSS行高`line-height`的理解。所讲述的并不一定都是正确的，欢迎指正欢迎交流。

### 二、一些字面意思

“行高”顾名思意指一行文字的高度。具体来说是指两行文字间基线之间的距离。基线实在英文字母中用到的一个概念，我们刚学英语的时使用的那个英语本子每行有四条线，其中底部第二条线就是基线，是a,c,z,x等字母的底边线。下图的红色线即为基线。

![英语本子的各条线](https://image.zhangxinxu.com/image/blog/200911/base_line.jpg)

`vertical-align`中有`top`,`middle`,`baseline`,`bottom`与之是由关联的，但具体细节如何，浏览器差异怎样，我还不是很清楚。

但是由于中文跟英文长得不一样，所以基线的说法就像老太太穿线——对不上眼。您理解为底线之差也不为不可。只是定义一回事，表现则另一回事。

### 三、line-height与line boxes高度

CSS中起高度作用的应该就是`height`以及`line-height`了吧！如果一个标签没有定义`height`属性(包括百分比高度)，那么其最终表现的高度一定是由`line-height`起作用，即使是IE6下`11`像素左右默认高度bug也是如此。待我慢慢叙来。

先说一个大家都熟知的现象，有一个空的`div`，`<div></div>`，如果没有设置至少大于`1`像素高度`height`值时，该`div`的高度就是个`0`。如果该`div`里面打入了一个空格或是文字，则此`div`就会有一个高度。那么您思考过没有，为什么`div`里面有文字后就会有高度呢？

这是个看上去很简单的问题，是理解`line-height`非常重要的一个问题。可能有人会跟认为是：文字撑开的！文字占据空间，自然将`div`撑开。我一开始也是这样理解的，但是事实上，深入理解`inline`模型后，我发现，根本不是文字撑开了`div`的高度，而是`line-height`！要证明很简单(如下测试代码)：

CSS代码：

    .test1{font-size:20px; line-height:0; border:1px solid #cccccc; background:#eeeeee;}
    .test2{font-size:0; line-height:20px; border:1px solid #cccccc; background:#eeeeee;}

HTML代码：

    <div class="test1">测试</div>
    <div class="test2">测试</div>

结果如下图(windows IE6浏览器下)：

![行高撑开高度还是文字撑开高度测试结果](https://image.zhangxinxu.com/image/blog/200911/2009-11-28_002310.png)

结果是如此的显而易见，test1 `div`有文字大小，但行高为`0`，结果`div`的高度就是个`0`；test2 `div`文字大小为`0`，但是有行高，为`20`像素，结果`div`高度就是`20`像素。这就说明撑开`div`高度的是`line-height`不是文字内容。

到底这个`line-height`行高怎么就产生了高度呢？在`inline box`模型中，有个`line boxes`，这玩意是看不见的，这个玩意的工作就是包裹每行文字。一行文字一个`line boxes`。例如“艾佛森退役”这5个字，如果它们在一行显示，你艾佛森再牛逼，对不起，只有一个`line boxes`罩着你；但“春哥纯爷们”这5个字，要是竖着写，一行一个，那真是够爷们，一个字罩着一个`line boxes`，于是总计五个`line boxes`。`line boxes`什么特性也没有，就高度。所以一个没有设置`height`属性的`div`的高度就是由一个一个`line boxes`的高度堆积而成的。

其实`line boxes`不是直接的生产者，属于中层干部，真正的活儿都是它的手下 – `inline boxes`干的，这些手下就是文字啦，图片啊，`<span>`之类的`inline`属性的标签啦。`line boxes`只是个考察汇报人员，考察它的手下谁的实际`line-height`值最高，谁最高，它就要谁的值，然后向上汇报，形成高度。例如，`<span style="line-height:20px;">取手下line-height<span style="line-height:40px;">最高</span>的值</span>`。则line boxes的高度就是40像素了。

### 四、行高的垂直居中性

行高还有一个特性，叫做垂直居中性。`line-height`的最终表现是通过`line boxes`实现的，而无论`line boxes`所占据的高度是多少（无论比文字大还是比文字小），其占据的空间都是与文字内容公用水平中垂线的。还拿上面这张图来说吧。

![行高撑开高度还是文字撑开高度测试结果](https://image.zhangxinxu.com/image/blog/200911/2009-11-28_002310.png)

看test1的结果，此时line boxes的高度为0，但是它是以文字的水平中垂线对称分布的。这一重要的特性可以用来实现文字或图片的垂直居中对齐。

### 五、在单行或多行或图片垂直居中实现上的应用

您可以狠狠地点击这里：[行高实现单行和多行文字垂直居中demo](<http://www.zhangxinxu.com/study/200911/line-height-text-v-center.html>)

#### 1、单行文字的垂直居中对齐

网上都是这么说的，把`line-height`值设置为`height`一样大小的值可以实现单行文字的垂直居中。这句话确实是正确的，但其实也是有问题的。问题在于`height`，看我的表述：“把line-height设置为您需要的box的大小可以实现单行文字的垂直居中”，差别在于我把`height`去掉了，这个`height`是多余的，您不信您可以自己试试。

#### 2、多行文字的垂直居中

要实现高度不固定的文字垂直居中使用`padding`就好了。对于高度固定的`div`，里面文字单行或多行显示，字体大小有大有小的情况怎么办呢？方法之一就是借助于`line-height`。

下图为demo页面的截图批注图：  
![多行文字垂直居中原理演示](https://image.zhangxinxu.com/image/blog/200911/2009-11-28_011819.png)

正如上面所说，`line boxes`的高度取决于它的下属职员的最高高度。而这个高度由一个不占据任何空间的空格完成，方法即使设置`font-size`为`0`，`line-height`为所需要的高度。同时，我们为了分隔`line boxes`，同时要保持在一行上，需要设置`display`属性值为`inline-block`。如下代码，有别于demo：

CSS代码：

    ~~.mulit_line{line-height:150px; border:1px dashed #cccccc; padding-left:5px; font-size:0;}
    .mulit_line span{display:-moz-inline-stack; display:inline-block; line-height:1.4em; vertical-align:middle;}
    .mulit_line i{width:0; display:-moz-inline-stack; display:inline-block; vertical-align:middle;}~~

感谢小西的提醒，下为修复IE8问题后的代码：

    .mulit_line{line-height:150px; border:1px dashed #cccccc; padding-left:5px;}
    .mulit_line span{display:-moz-inline-stack; display:inline-block; line-height:1.4em; vertical-align:middle;}
    .mulit_line i{width:0; display:-moz-inline-stack; display:inline-block; vertical-align:middle; font-size:0;}

html代码：

    <p class="mulit_line">
        <span style="font-size:12px;">这里是高度为150像素的标签内的多行文字，文字大小为12像素。<br />这里是第二行，用来测试多行的显示效果。</span><i>&nbsp;</i>
    </p>

效果如上批注图。已通过IE8以外的主流浏览器的兼容性检测。以前曾见过说IE8的`line-height`有些问题，如果谁发现IE8下有问题，欢迎指出，不甚感谢。

#### 3、图片的垂直居中

您可以狠狠地单击这里：[行高使图片垂直居中显示demo](<http://www.zhangxinxu.com/study/200911/image-center-new-method-test.html>)

此方法在“[大小不固定的图片、多行文字的水平垂直居中](<http://www.zhangxinxu.com/wordpress/?p=61> "大小不固定的图片、多行文字的水平垂直居中的永久链接")”一文中的最后补充内容里已经详细讲解了。这里不多说了。

//zxx:之前未能在IE8下测试，现发现此方法不仅在Opera下有问题，在IE8下也是表现欠佳。所以仅仅使用line-height的垂直居中法有待斟酌，或许要使用与上面多行文字垂直居中的同样的方法来实现图片垂直居中的效果。

### 六、行高在文章显示中的应用

一般社交型的网站都会有发博文或写日志的功能，其中发表后的文章显示也是有学问的，其中之一就是line-height行高。

首先要知道行高的几种表示方法：`px/em`，或`normal`，或百分值，或数值，或`inherit`继承。

在显示文章的box里，`px`的表示方法首先是要被淘汰的。因为文章里面的文字是有大有小的，使用`px`定值，由于继承性，无法实现根据文字大小自动调整间距，会出现大号文字重叠的现象。`normal`也是不行的，一般文章显示最好是`650`像素的宽度，`1.5`倍的行距较好。一般浏览器的`normal`值在`1~1.2`之间，使用`normal`必然文字间距过小，阅读吃力。百分值也有继承性，但是有个很搓的办法可以实现文字间距自动适应于文字的大小，那就是使用`*`通配符，例如：

    .article_box *{line-height:150%;}

就不会出现文字重叠的情况了。网易博客就是使用的这个方法，下图为证：

![网易博客使用百分比加通配符实现行高自适应](https://image.zhangxinxu.com/image/blog/200911/2009-11-28_020712.png)

为什么说这个方法搓呢，使用`*`通配符大大增加了CSS的渲染，效率低，而且有更好的方法，就是使用数值。`150%`虽然和`1.5`在值上是一样的，但是它们也是有差别的，差别在于继承性，使用百分比会计算`line-height`的值，然后以`px`像素为单位继承下去，而`1.5`则是先继承`1.5`这个值，遍历到了该标签再计算去`line-height`的像素值。所以同样的效果只需要下面CSS就可以实现了。

    .article_box{line-height:1.5;}

### 七、使用行高代替高度避免haslayout

在某些情形下，`line-height`可以和`height`互换，因为实现的效果一样。都能撑开一个高度，然而这两个CSS属性有一个较隐蔽的差异，就是使用`height`会使标签`haslayout`，而使用`line-height`则不会。以前只有IE6的时候曾流行使用`height`清除浮动，就是利用了IE下height使`haslayout`的属性。但有时候，`haslayout`并不需要，反而要避免。

读过我前面有关自适应按钮文章的人可能会发现我使用了`line-height`代替了`height`，其原因在于：IE6，IE7下，类似`inline-block`属性的元素里如果有`block`属性的元素，如果该`block` `haslayout`，则该标签会冲破外部`inline-block`的显示而宽度`100%`显示，从使按钮自适应文字大小的效果失效，解决方法就是使用`line-height`代替`height`。

![height与line-height在IE6下区别](https://image.zhangxinxu.com/image/blog/200911/2009-11-28_022951.png)

上图中第一个标签使用`height`定高，结果宽度直接`100%`显示；第二个标签使用`line-height`定高，结果很规矩，自适应与内部文字大小。其代码如下：

CSS部分：

    .out{display:inline-block; background:#a0b3d6; margin-top:20px;}
    .in1{display:block; height:20px;}
    .in2{display:block; line-height:20px;}

HTML部分：

    <span class="out">
        <span class="in1">height:20px;</span>
    </span>
    <span class="out">
        <span class="in2">line-height:20px;</span>
    </span>

### 八、结语

很多关于`line-height`的基础的知识这里并没有详细讲述，本文一开始提到的腾讯ISD团队的那篇关于行高的文章是不错的，对于了解`line-height`的一些特性及`inline box`模型很有帮助。本文更多的是讲述自己对于`line-height`的一些理解，简述了我使用`line-height`的一些经验。由于都是个人的些东西，加上本身自己的资历有限，所以可能会出现一些错误，一些遗漏之处等，还望了解。欢迎指正。要是能对您的学习有所帮助就再好不过了。

本文为原创文章，转载请注明来自[张鑫旭-鑫空间-鑫生活](<http://www.zhangxinxu.com/>)[[http://www.zhangxinxu.com](<http://www.zhangxinxu.com/>)]  
本文地址：<http://www.zhangxinxu.com/wordpress/?p=384>

（本篇完）

相关文章

  * [CSS vertical-align的深入理解(二)之text-top篇](<https://www.zhangxinxu.com/wordpress/2010/06/css-vertical-align%e7%9a%84%e6%b7%b1%e5%85%a5%e7%90%86%e8%a7%a3%ef%bc%88%e4%ba%8c%ef%bc%89%e4%b9%8btext-top%e7%af%87/>) (0.511)
  * [CSS float浮动的深入研究、详解及拓展(一)](<https://www.zhangxinxu.com/wordpress/2010/01/css-float%e6%b5%ae%e5%8a%a8%e7%9a%84%e6%b7%b1%e5%85%a5%e7%a0%94%e7%a9%b6%e3%80%81%e8%af%a6%e8%a7%a3%e5%8f%8a%e6%8b%93%e5%b1%95%e4%b8%80/>) (0.294)
  * [CSS line-height-step属性简介](<https://www.zhangxinxu.com/wordpress/2021/03/css-line-height-step/>) (0.233)
  * [CSS 相对/绝对(relative/absolute)定位系列（三）](<https://www.zhangxinxu.com/wordpress/2011/03/css-%e7%9b%b8%e5%af%b9%e7%bb%9d%e5%af%b9relativeabsolute%e5%ae%9a%e4%bd%8d%e7%b3%bb%e5%88%97%ef%bc%88%e4%b8%89%ef%bc%89/>) (0.202)
  * [我对CSS vertical-align的一些理解与认识（一）](<https://www.zhangxinxu.com/wordpress/2010/05/%e6%88%91%e5%af%b9css-vertical-align%e7%9a%84%e4%b8%80%e4%ba%9b%e7%90%86%e8%a7%a3%e4%b8%8e%e8%ae%a4%e8%af%86%ef%bc%88%e4%b8%80%ef%bc%89/>) (0.192)
  * [小tip: transition与visibility](<https://www.zhangxinxu.com/wordpress/2013/05/transition-visibility-show-hide/>) (0.192)
  * [display:inline-block/text-align:justify下列表的两端对齐布局](<https://www.zhangxinxu.com/wordpress/2011/03/displayinline-blocktext-alignjustify%e4%b8%8b%e5%88%97%e8%a1%a8%e7%9a%84%e4%b8%a4%e7%ab%af%e5%af%b9%e9%bd%90%e5%b8%83%e5%b1%80/>) (0.177)
  * [拜拜了,浮动布局-基于display:inline-block的列表布局](<https://www.zhangxinxu.com/wordpress/2010/11/%e6%8b%9c%e6%8b%9c%e4%ba%86%e6%b5%ae%e5%8a%a8%e5%b8%83%e5%b1%80-%e5%9f%ba%e4%ba%8edisplayinline-block%e7%9a%84%e5%88%97%e8%a1%a8%e5%b8%83%e5%b1%80/>) (0.158)
  * [:after伪类+content内容生成经典应用举例](<https://www.zhangxinxu.com/wordpress/2010/09/after%e4%bc%aa%e7%b1%bbcontent%e5%86%85%e5%ae%b9%e7%94%9f%e6%88%90%e5%b8%b8%e8%a7%81%e5%ba%94%e7%94%a8%e4%b8%be%e4%be%8b/>) (0.147)
  * [CSS深入理解vertical-align和line-height的基友关系](<https://www.zhangxinxu.com/wordpress/2015/08/css-deep-understand-vertical-align-and-line-height/>) (0.137)
  * [PNG格式小图标的CSS任意颜色赋色技术](<https://www.zhangxinxu.com/wordpress/2016/06/png-icon-change-color-by-css/>) (RANDOM - 0.004)
