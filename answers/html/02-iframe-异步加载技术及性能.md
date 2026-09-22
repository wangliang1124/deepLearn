# iframe 异步加载技术及性能

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.cnblogs.com/beiyuu/archive/2011/07/18/iframe-tech-performance.html>
> 对应题目：HTML 第 2 题 · iframe 异步加载技术及性能
> 抓取时间：2026-09-22

---

这是一篇原创翻译文章。[原文地址](<http://www.aaronpeters.nl/blog/iframe-loading-techniques-performance?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed:+aaronpeters+\(Aaron+Peters\)>)。

我们会经常使用iframes来加载第三方的内容、广告或者插件。使用iframe是因为他可以和主页面并行加载，不会阻塞主页面。当然使用iframe也是有利有弊的：Steve Souders在他的blog里面有阐述：[Using Iframes Sparingly](<http://www.stevesouders.com/blog/2009/06/03/using-iframes-sparingly/>):

  * iframe会阻塞主页面的onload事件
  * 主页面和iframe共享同一个连接池

阻塞主页面的onload是这两个问题中最影响性能的方面。一般都是想让onload时间越早触发越好，一方面是用户体验过更重要的是google给网站的加载速度的打分：用户可以用IE和FF中Google工具栏来计时。

**那么为了提高页面性能，怎样才能不阻塞主页面的onload事件的来加载iframe呢？**

这篇讲了四种加载iframe的方法：普通iframe，onload之后加载iframe，setTimeout() iframe和异步加载iframe。每种方法的加载结果我都用IE8的时间线来展示。我建议多注意下动态异步加载这个方法，因为这是性能表现最佳的。另外，还有一种友好iframe(friendly iframe)技术。他可能算不上是iframe加载的技术，但是必须使用iframe，他是无阻塞加载的。

## 普通方法加载iframe

这是一种人尽皆知的普通加载方法，它没有浏览器的兼容性问题。

    1 <iframe src="/path/to/file" frameborder="0" width="728" height="90" scrolling="auto"> </iframe>

使用这种加载方法会在各浏览器中有如下表现：

  * iframe会在主页面的onload之前加载
  * iframe会在所有iframe的内容都加载完毕之后触发iframe的onload
  * 主页面的onload会在iframes的onload触发之后触发，所以iframe会阻塞主页面的加载
  * 当iframe在加载的过程中，浏览器的会标识正在加载东西，处于忙碌状态。

[这里](<http://www.aaronpeters.nl/sandbox/wpo/iframe-normal.html>)是一个演示页面，时间线图显示出iframe会阻塞主页面的加载。

![](http://www.aaronpeters.nl/blog/images/iframe/normal-iframe-IE8-waterfall-big.png)

我的建议：注意onload阻塞。如果iframe的内容只需要很短的时间来加载和执行，那么也不是个大问题，而且使用这种方法还有个好处是可以和主页面并行加载。但是如果加载这个iframe需要很长时间，用户体验就很差了。你得自己测试一下然后在http://www.webpagetest.org/也做些测试，根据onload的时间看看是否需要其他加载方法。

## 在onload之后加载iframe

如果你想在iframe中加载一些内容，但是这些内容对于页面来说不是那么的重要。或者这些内容不需要马上展现给用户的，需要点击触发之类的。那么可以考虑在主页面载入之后加载iframe。

     1 <script>  
     2   
     3 //doesn't block the load event  
     4 function createIframe() {  
     5     var i = document.createElement("iframe");  
     6     i.src = "path/to/file";  
     7     i.scrolling = "auto";  
     8     i.frameborder = "0";  
     9     i.width = "200px";  
    10     i.height = "100px";  
    11     document.getElementById("div-that-holds-the-iframe").appendChild(i);  
    12 };  
    13 // Check for browser support of event handling capability  
    14 if (window.addEventListener) window.addEventListener("load", createIframe, false);  
    15 else if (window.attachEvent) window.attachEvent("onload", createIframe);  
    16 else window.onload = createIframe;  
    17 </script>

这种加载方法也是没有浏览器的兼容性问题的：

  * iframe会在主页面onload之后开始加载
  * 主页面的onload事件触发与iframe无关，所以iframe不会阻塞加载
  * 当iframe加载的时候，浏览器会标识正在加载

[这是](<http://www.aaronpeters.nl/sandbox/wpo/iframe-dynamic-after-onload.html>)是一个测试页面，时间线图如下

![](http://s1.aaronpeters.nl/blog/images/iframe/iframe-after-onload-IE8-waterfall-small.png)

这种方法比普通方法有什么好处呢？load事件会马上触发，有两个好处：

  * 其他等待主页面onload事件的代码可以尽早执行
  * Google Toolbar计算你页面加载的时间会大大减少

但是，当iframe加载的时候，还是会看到浏览器的忙碌状态，相对于普通加载方法，用户看到忙碌状态的时间更长。还有就是用户还没等到页面完全加载完的时候就已经离开了。有些情况下这是个问题，比如广告。

## setTimeout()来加载iframe

这种方法的目的是不阻塞onload事件。

Steve Souders(又是他？)有一个这种方法的测试页面(http://stevesouders.com/efws/iframe-onload-nonblocking.php)。他写道：“src通过setTimeout动态的设置，这种方法可以再所有的浏览器中避免阻塞”。

    <iframe id="iframe1" src="" width="200" height="100" border="2">  
     </iframe>  
    <script>  

    function setIframeSrc() {  
        var s = "path/to/file";  
        var iframe1 = document.getElementById('iframe1');  
        if ( - 1 == navigator.userAgent.indexOf("MSIE")) {  
            iframe1.src = s;  
        } else {  
            iframe1.location = s;  
        }  
    }  
    setTimeout(setIframeSrc, 5);  
    </script>

在除了IE8以外的所有浏览器中会有如下表现：

  * iframe会在主页面onload之前开始加载
  * iframe的onload事件会在iframe的内容都加载完毕之后触发
  * iframe不会阻塞主页面的onload事件(IE8除外)
  * 为什么不会阻塞主页面的onload呢(IE8除外)？因为setTimeout()
  * 当iframe加载的时候，浏览器会显示忙碌状态

下面是时间线图

![](http://s1.aaronpeters.nl/blog/images/iframe/iframe-settimeout-IE8-waterfall-small.png)

因为IE8的问题，这种技术就不适合很多网站了。如果有超过10%的用户使用IE8,十分之一的用户体验就会差。你会说那也只是比普通加载差一点点，其实普通加载性能上也不差。onload事件对于10%的用户来说都更长。。。。额，你自己考虑吧。但是最好在看了下面这个很赞的异步加载方法之后再决定吧。

我在参加Velocity 2010的时候，Meebo的两个工程师(@marcuswestin and Martin Hunt)做了一个关于他们的Meebo Bar的演讲。他们使用iframe来加载一些插件，并且真正做到了无阻塞加载。对于有的开发者来说，他们的做法还比较新鲜。很赞，超级赞。但是一些原因导致这种技术没有得到相应的关注，我希望这篇blog能把它发扬光大。

    <script>  

    (function(d) {  
        var iframe = d.body.appendChild(d.createElement('iframe')),  
        doc = iframe.contentWindow.document;  

        // style the iframe with some CSS  
        iframe.style.cssText = "position:absolute;width:200px;height:100px;left:0px;";  

        doc.open().write('<body onload="' + 'var d = document;d.getElementsByTagName(\'head\')[0].' + 'appendChild(d.createElement(\'script\')).src' + '=\'\/path\/to\/file\'">');  

        doc.close(); //iframe onload event happens  
    })(document);  
    </script>

神奇的地方就在<body onload=”">:这个iframe一开始没有内容，所以onload会立即触发。然后你创建一个script元素，用他来加载内容、广告、插件什么的，然后再把这个script添加到HEAD中去，这样iframe内容的加载就不会阻塞主页面的onload！你应该看看他在个浏览器中的表现：

  * iframe会在主页面onload之前开始加载
  * iframe的onload会立即触发，因为iframe的内容一开始为空
  * 主页面的onload不会被阻塞
  * 为什么这个iframe不会阻塞主页面的onload？因为<body onload=”">
  * 如果你不在iframe使用onload监听，那么iframe的加载就会阻塞主页面的onload
  * 当iframe加载的时候，浏览器终于不显示忙碌状态了（非常好）

[我的测试页](<http://www.aaronpeters.nl/sandbox/wpo/iframe-dynamic-asynch.html>)给出下面的时间线：

![](http://s1.aaronpeters.nl/blog/images/iframe/iframe-dynamic-asynch-IE8-waterfall-small.png)

转义字符让代码看着有些难受，这都不是问题。试试吧。

## 友好型iframe加载

这是用来加载广告的。虽然这不是一种iframe的加载技术，但是是用iframe来盛放广告的。他的亮点不在于iframe如何加载，而是主页面、iframe、广告如何协同工作的。如下：

  * 先创建一个iframe。设置他的src为一个相同域名下的静态html文件
  * 在这个iframe里面，设置js变量inDapIF=true来告诉广告它已经加载在这个iframe里面了
  * 在这个iframe里面，创建一个script元素加上广告的url作为src，然后像普通广告代码一样加载
  * 当广告加载完成，重置iframe大小来适应广告
  * 这种方法也没有浏览器的兼容性问题。

[Ad Ops Council在推荐过这个方法](<http://www.iab.net/media/file/rich_media_ajax_best_practices.pdf>)，AOL也是用这种方法。想看看源码：[这里有一个](<http://www.artzstudio.com/files/fif-demo/>)。一家瑞典的出版社Aftonbladet对于这种加载有很不错的结论：在他们的主页上，加载时间减少30%，用户每周增加7%，新闻部分的点击量增加35%。我建议可以看看他们的资料：[High Performance Web Sites, With Ads: Don’t let third parties make you slow](<http://www.slideshare.net/jarlund/hign-performance-web-sites-with-ads-dont-let-third-parties-make-you-slow>)

我没有创建相关的测试页，所以也没有第一首的资料。从我调研的结果来说：

如果你只想在你的网页上调用一个确定的src地址的iframe的话这个方法不是很有用。

如果你想在网页上展示多个广告，比较灵活的方法的是：加载一个广告，然后更新iframe加载另一个主页面的DOMContentLoaded时间不会被阻塞，页面渲染也不会被阻塞，当然，主页面的onload事件还是会被阻塞。
