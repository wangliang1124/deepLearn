# Page Visibility(页面可见性) API 介绍、微拓展

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.zhangxinxu.com/wordpress/2012/11/page-visibility-api-introduction-extend/>
> 对应题目：HTML 第 3 题 · Page Visibility API
> 抓取时间：2026-09-22

---

by [zhangxinxu](<https://www.zhangxinxu.com/>) from [https://www.zhangxinxu.com](<https://www.zhangxinxu.com/>)  
本文地址：<https://www.zhangxinxu.com/wordpress/?p=2790>

### 一、网页君的悲情谁来懂

唉，突然想到了一首悲情诗：

> 泪湿罗巾梦不成，夜深前殿按歌声。  
>  红颜未老恩先断， 斜倚薰笼坐到明。

学生时代学过的一首诗，已还给老师不知所云的诸位可参见下面释义：

> 诗的主人公是一位不幸的宫女。她一心盼望君王的临幸而终未盼得，时已深夜，只好上床，已是一层怨怅。宠幸不可得，退而求之好梦；辗转反侧，竟连梦也难成，见出两层怨怅。梦既不成，索性揽衣推枕，挣扎坐起。正当她愁苦难忍，泪湿罗巾之时，前殿又传来阵阵笙歌，原来君王正在那边寻欢作乐，这就有了三层怨怅。倘使人老珠黄，犹可解说；偏偏她盛鬓堆鸦，红颜未老，生出四层怨怅。要是君王一直没有发现她，那也罢了；事实是她曾受过君王的恩宠，而现在这种恩宠却无端断绝，见出五层怨怅。夜已深沉，濒于绝望，但一转念，犹翼君王在听歌赏舞之后，会记起她来。于是，斜倚熏笼，浓熏翠袖，以待召幸。不料，一直坐到天明，幻想终归破灭，见出六层怨怅。

为何在这阳光和煦，安静惬意的温暖冬日会有如此感伤呢？

唉，只因自己想到了可怜的网页君，其命运就跟深宫的宫女一般，令人唏嘘。

某君王啪啪啪啪打开了十几二十个选项卡（就像他当初啪啪啪啪宠幸后宫那十几二十个宫女一样）；但是，鞭长莫及，其一次只能浏览一个选项卡（就像他每晚只能宠幸一个宫女一样）；可是，其他的选项卡并不知道君王何时会再过来（就像其他的宫女并不清楚君王今晚会不会来宠幸一样）；于是，其他选项卡依然在不停地运行，守候（就像宫女依然留有希望，等待召幸）；然而，最后，君王直接啪一下浏览器关掉了，N多不停忠心守候的选项卡被无情漠视了（就像宫女们苦守整夜，结果却是一场空，只能以泪洗面）！

此番悲情怎能不让人同情怜悯，是不是啊，诸位！

哼，请不要摆出这样![](https://mat1.gtimg.com/www/mb/images/face/27.gif)或这样![](https://mat1.gtimg.com/www/mb/images/face/98.gif)的表情。  
那个谁谁，说的就是你！你应该这样子![](https://mat1.gtimg.com/www/mb/images/face/9.gif)或这样子![](https://mat1.gtimg.com/www/mb/images/face/15.gif)。

您应该像扎西拉姆·多多一样，为悲情网页君赋诗一首——《见与不见》：

> 你见，或者不见我  
>  我就在那里  
>  不悲不喜  
>  你念，或者不念我  
>  情就在那里  
>  不来不去……

时代在发展，制度也会进步。比方说明代吧，每日天渐黑时，嫔妃所住的宫门前，都挂起两只红纱笼灯。皇帝临幸某宫，则该宫门上的灯卸下来，表示皇帝已选定寝宿的地方。于是，负责巡街的宦官，传令其他各宫均卸灯寝息。失意的嫔妃们只得灭掉希求宠幸的红纱笼，明晚再重新挂上。

这就避免了嫔妃们彻夜苦等，哀怨泪雨的情形。

那网页君这边呢？

好在，就最近几年，网页君也有了相应的东西，可以告知网页你是“宠幸”了呢还是不被“宠幸”，这样，可以让网页君在不被“宠幸”时候安心睡觉，或者养个小白。这个东西就是[Page Visibility API](<https://www.w3.org/TR/page-visibility/>)，翻译成简体中文就是“**页面可见性应用程序接口** ”。

于是乎，网页君的悲情程度可以lower一点了，从这点来说，Page Visibility API是个很人性化的设计，感动![](https://mat1.gtimg.com/www/mb/images/face/111.gif)！

//zxx: 为接地气，下”Page Visibility API”均称呼为“页面可见性API”。

### 二、页面可见性API究竟为何物？

CSS中有个有用且有趣且个人比较喜欢的属性 – `visibility`. 其有两个常用属性值：`hidden`与`visible`. 分别表示不可见与可见。OK，本文所说的API中也有`Visibility`这个单词，那他们表意一致？

回答是：**YES!** //众人：妹啊，你以为是中国达人秀啊！

页面可见性API就是表示网页可见还是不可见的，巧的是，`hidden`与`visible`就是该API的两个状态值。

举个通俗的例子：  
如果你在xxxxx.com上浏览提神的图片，则当前你所看的这个网页的`visibility`就是`visible`. 

此时，如果你老妈子突然进来给你送香蕉，出现下图所示场景：  
![总是在看桌面](https://image.zhangxinxu.com/image/blog/202004/why-son-sceen.jpg)

则，此时之前提神的网页的`visibility`就是`hidden` – 最小化。

或者老妈子进来的时候，切换到人民网，提神网页的`visibility`也是`hidden` – 切换选项卡。

![](https://image.zhangxinxu.com/image/blog/202004/banana.jpg) 老妈子送的香蕉~~啦啦啦啦啦~~

这就是页面可见性API的直观认识，至于其身上哪里有麻子，下面会指出![](https://mat1.gtimg.com/www/mb/images/face/60.gif).

### 三、页面可见性API属性和事件

目前页面可见性API有两个属性，一个事件，如下：

  * `document.hidden`: Boolean值，表示当前页面可见还是不可见
  * `document.visibilityState`: 返回当前页面的可见状态。 
    1. “`hidden`“
    2. “`visible`“
    3. “`prerender`” 这个表示纳尼呢![](https://mat1.gtimg.com/www/mb/images/face/32.gif)~~恩，我也不确定，字面意思是“预渲染”。莫非指的是啪啪啪一下子开了很多个选项卡，之前选项卡依然在加载渲染的状态？或者说是浏览器新打开时记住的上一次关闭选项卡的状态？求达人指明！
    4. “`preview`” 预览。根据部分2011年底相关国外部分文章的说法，这种状态出现在，如window7系统下，鼠标放在底部（一般是）任务栏的图标上（预览）的时候。见下截图：  
![win7鼠标图标程序界面预览 张鑫旭-鑫空间-鑫生活](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_110709.png)

但是根据自己的实际测试，似乎并没有这种状态的改变——包括IE10浏览器。可能是时代改变，一切都遵循规范了吧。因此，我们重点关注前面三个状态值就可以了。 

  * `visibilitychange`: 当可见状态改变时候触发的事件。

### 四、浏览器支持与私有前缀

我写了个如下的页面可见性API支持性的测试代码：

    var isPageVisibilitySupport = (function() {
        var support = false;
        if (typeof window.screenX === "number") {
            ["webkit", "moz", "ms", "o", ""].forEach(function(prefix) {
                if (support == false && document[prefix + (prefix? "H": "h") + "idden"] + "" !== "undefined") {
                    support = true;
                }
            });        
        }
        return support;
    })();

测试发现，如下浏览器都是**支持的** ：

  * Chrome 21
  * FireFox 16.0.2
  * Opera 12.11
  * IE10

**不支持的** 浏览器：

  * IE9
  * Safari 5.1

因此，`typeof document.msHidden != "undefined"`可以用来区分IE9浏览器还是IE10浏览器。

正如上面的code所展示的，页面可见性API的所有属性以及事件，目前是需要使用私有前缀的（如果没有这些前缀，浏览器就不认识这些属性或方法了）。  
一旦有了前缀，实际应用的时候代码就有些啰哩吧嗦了（可见参见文章底部参考文章中展示的代码）！

因为要一个前缀一个前缀判断——oh, my! ![](https://mat1.gtimg.com/www/mb/images/face/34.gif) 我这个懒人最不喜欢这等麻烦事了，于是，捞起袖子，啪啪啪啪整个一个兼容性的Page Visibility API相关对象，正好包含API中的两个属性以及一个事件。完整代码如下（节省篇幅，滚动显示。如果您发现没有滚动效果啊？可能是由于在其他网站或是RSS中阅读本文，本文原地址：<https://www.zhangxinxu.com/wordpress/?p=2790>，本文作者：[张鑫旭](<https://www.zhangxinxu.com/>)，来自张鑫旭-鑫空间-鑫生活，访问原出处阅读体验更佳。  
）：

    var pageVisibility = (function() {
        var prefixSupport, keyWithPrefix = function(prefix, key) {
            if (prefix !== "") {
                // 首字母大写
                return prefix + key.slice(0,1).toUpperCase() + key.slice(1);    
            }
            return key;
        };
        var isPageVisibilitySupport = (function() {
            var support = false;
            if (typeof window.screenX === "number") {
                ["webkit", "moz", "ms", "o", ""].forEach(function(prefix) {
                    if (support == false && document[keyWithPrefix(prefix, "hidden")] != undefined) {
                        prefixSupport = prefix;
                        support = true;   
                    }
                });        
            }
            return support;
        })();

        var isHidden = function() {
            if (isPageVisibilitySupport) {
                return document[keyWithPrefix(prefixSupport, "hidden")];
            }
            return undefined;
        };

        var visibilityState = function() {
            if (isPageVisibilitySupport) {
                return document[keyWithPrefix(prefixSupport, "visibilityState")];
            }
            return undefined;
        };

        return {
            hidden: isHidden(),
            visibilityState: visibilityState(),
            visibilitychange: function(fn, usecapture) {
                usecapture = undefined || false;
                if (isPageVisibilitySupport && typeof fn === "function") {
                    return document.addEventListener(prefixSupport + "visibilitychange", function(evt) {
                        this.hidden = isHidden();
                        this.visibilityState = visibilityState();
                        fn.call(this, evt);
                    }.bind(this), usecapture);
                }
                return undefined;
            }
        };    
    })(undefined);

或者直接调用：

    <script src="https://www.zhangxinxu.com/study/201211/pageVisibility.js"></script>

其中具体细节无需关心，实际上上面这么多代码本质上就是下面这点：

    var pageVisibility = {
        hidden: _Boolean_
        visibilityState: _String_
        visibilitychange: _Function_
    };

与_原生属性事件_对应关系如下：

    pageVisibility.hidden === document.hidden（兼容处理）
    pageVisibility.visibilityState=== document.visibilityState（兼容处理）
    pageVisibility.visibilitychange(function() { /* this指的就是pageVisibility */ }); === document.addEventListener("visibilitychange", function() {});（兼容处理）

于是，要判断一个浏览器是否支持页面可见性API如下代码就可以了（无需什么webkit或moz或ms等前缀一个个判断了）：

    var isSupport = typeof pageVisibility.hidden !== "undefined"

**测试demo**  
您可以狠狠地点击这里：[兼容性的网页可见性API属性与事件demo](<https://www.zhangxinxu.com/study/201211/page-visibility-api-support-basic.html>)

![网页可见性 API基本属性与事件实例页面截图 张鑫旭-鑫空间-鑫生活](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_200225.png)

对于不支持的浏览器，如IE9浏览器，显示的则是”`undefined`“：  
![不支持网页可见性API浏览器显示undefined  张鑫旭-鑫空间-鑫生活](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_201142.png)

OK，万屎具备，只欠草纸了！下面，看看，页面可见性API都有些可以有的实际应用。

### 五、页面可见性API实际应用

先来看看老外给的一个例子，我觉得很有实际应用价值的。

首先是链接地址：<http://www.samdutton.com/pageVisibility/> //zxx: 希望不要明年这个时候被墙掉

进去后，会有一个HTML5 video显示的Google Chrome浏览器广告的30秒funny视频，如下图所示：  
![视频截图](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_202553.png)

直接浏览你是看不出什么玄乎的，请切换一个选项卡，让该页面置于后面，结果，您会发现这个选项卡的标题栏变成了这样：  
![标题栏显示视频暂停以及暂停时间](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_203118.png)

看出来没？视频播放被中断了——当page不可见的时候，视频会自动暂停！

此时，您再进入该选项卡，视频又从刚才的地方继续播放了，如下截图：  
![页面可见视频继续播放 张鑫旭-鑫空间-鑫生活](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_203714.png)

个人愚见，国内的一些视频站点是不是可以应用下这个API呢！这样当妈妈进来送香蕉的时候，直接win+D显示桌面就可以了，声音啊什么的会自动关掉，振奋视频自动暂停，多赞的一个功能啊！以前的暂停视频+最小化浏览器直接变成了一步→最小化，节约了大量的宝贵时间，极大了提升了用户体验，![](https://mat1.gtimg.com/www/mb/images/face/101.gif)恩！不错！！

上面的例子毕竟长在外人田啊，一旦建起了围墙就看不到了，因此，自己折腾了一个简单的10秒钟低质量的猫猫版本。//zxx: 上面例子视频3M+，我估算了下，1000次访问的话，我勒个去，差不多3个G的流量去了，我现在每月流量都岌岌可危，因此，大家将就下下这个百来K的视频（Chrome浏览器以及IE10下可访问，或者谁给我尺寸小一点的ogv格式任意视频，让FireFox也能OK）~~

您可以狠狠地点击这里：[10秒钟妈妈来自动暂停视频demo](<https://www.zhangxinxu.com/study/201211/page-visibility-api-video-auto-pause-play.html>)

操作同上，进入页面播放，离开页面暂停。  
![Chrome浏览器下效果截图 张鑫旭-鑫空间-鑫生活](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_213838.png)

**登录同步**  
这是我想的一个觉得蛮实用的应用。有如下场景：  
1\. 去淘宝买东西，未登录状态下，进入首页。  
2\. 然后新窗口打开任意页面，登录并成功返回。  
![淘宝网成功登录 张鑫旭-鑫空间-鑫生活](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_220307.png)  
3\. 再次访问刚才打开的首页，发现页面还是未登录状态（见下图），实际上用户已经登录了。  
![之前的首页仍然是未登录状态](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_220623.png)

目前，这种状态大家似乎习以为常，觉得很OK，实际上这种糟糕的。就像没有空调的岁月里，人们觉得风扇很OK啊；但是，现在呢，还有谁屋顶吊个风扇吗！！有了页面可见性API，我们可以把体验做地更好。

您可以狠狠地点击这里：[网页可见性API与登录同步demo](<https://www.zhangxinxu.com/study/201211/page-visibility-api-login-same-step-1.html>)

不出意外，您默认进来应该是提示你登录的：  
![](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_231025.png)

点击上图所示的“登录”文字链接，会在新窗口无刷新登录。任意用户名和密码，成功后再回到之前提示的登录页面，已经变成了：“欢迎回来，某某某”了！  
![](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_231250.png) ![](https://image.zhangxinxu.com/image/blog/201211/2012-11-29_231317.png)

只要该页面不被关闭，你怎样刷新，都是“欢迎回来，某某某”。不过，在实际应用中，检测到已经登录成功，直接刷新当前页面的居多！IE10下，貌似本地存储无法同源不同页面共享，这使得通过HTML5本地存储共享信息的做法遇到了些许阻碍。

**精确的在线时长**  
这个不用多说，只有用户当前这个页面可见的时候，才计算在线时间，这样可以避免挂机的情况，时长计算更准确（这个可能不是个好idea）。

**在线聊天离开状态**  
网页聊天的时候，可以知道用户是否“离开”还是“离线”还是“下线”。当前页面不可见，但连接还在的时候，我们可以确定该人是离开的（涉及隐私，可能也不是个好idea）。

以及**其他些应用需求**  
等到了实际需求的时候，就会想到页面可见性API，看看能不能渐进增加下用户体验等。

### 六、结语

脑细胞不够用了，肯定还有很多现有的可以应用在实际项目中的idea的，一时想不出——恩，比方说，每次用户切换到你这个页面上的时候，logo抖一下，或页面一道亮光闪过![](https://mat1.gtimg.com/www/mb/images/face/4.gif)，后者欢迎语之类……总之，是个很有用很有趣的API.

此API支持日趋稳定，不会有被去除的可能，因此，大伙儿可以放心大胆尝试之……因为是新东西，您的任何小小idea都会是首创，领先的创造者——开动你的脑筋，发挥你的创造性思维，让我们的网页更加生动多彩吧![](https://mat1.gtimg.com/www/mb/images/face/99.gif)！

集思广益，欢迎补充！如有错误，欢迎纠正！

**参考文章：**

  * [Using the Page Visibility API](<http://www.samdutton.com/pageVisibility/>)
  * Nicholas C. Zakas：[Introduction to the Page Visibility API](<http://www.nczonline.net/blog/2011/08/09/introduction-to-the-page-visibility-api/>)
  * [Page Visibility API ](<http://ie.microsoft.com/testdrive/Performance/PageVisibility/Default.html>)
  * [Page Visibility API Support in Opera 12.10](<http://my.opera.com/ODIN/blog/page-visibility-api-support-in-opera-12-10>)
  * David Walsh：[Page Visibility API](<http://davidwalsh.name/page-visibility>)
  * [Using the Page Visibility API](<https://developers.google.com/chrome/whitepapers/pagevisibility>)

本文为原创文章，转载请注明来自[张鑫旭-鑫空间-鑫生活](<https://www.zhangxinxu.com/>)[[https://www.zhangxinxu.com](<https://www.zhangxinxu.com/>)]  
本文地址：<https://www.zhangxinxu.com/wordpress/?p=2790>

（本篇完）

相关文章

  * [深度好文: 从js visibilitychange Safari下无效说开去](<https://www.zhangxinxu.com/wordpress/2021/11/js-visibilitychange-pagehide-lifecycle/>) (0.901)
  * [今天才知道，Web网页也能阻止息屏了](<https://www.zhangxinxu.com/wordpress/2024/03/js-screen-wake-lock-api/>) (0.901)
  * [HTML5 drag & drop 拖拽与拖放简介](<https://www.zhangxinxu.com/wordpress/2011/02/html5-drag-drop-%e6%8b%96%e6%8b%bd%e4%b8%8e%e6%8b%96%e6%94%be%e7%ae%80%e4%bb%8b/>) (0.099)
  * [观点：不要太依赖JavaScript库](<https://www.zhangxinxu.com/wordpress/2012/03/%e8%a7%82%e7%82%b9%ef%bc%9a%e4%b8%8d%e8%a6%81%e5%a4%aa%e4%be%9d%e8%b5%96javascript%e5%ba%93/>) (0.099)
  * [渐进使用HTML5语言识别, so easy!](<https://www.zhangxinxu.com/wordpress/2012/05/html5-speech-x-webkit-grammar/>) (0.099)
  * [HTML5全屏API在FireFox/Chrome中的显示差异](<https://www.zhangxinxu.com/wordpress/2012/10/html5-full-screen-api-firefox-chrome-difference/>) (0.099)
  * [HTML5 Battery电池状态相关API简介](<https://www.zhangxinxu.com/wordpress/2014/01/an-overview-of-html5-battery-api/>) (0.099)
  * [利用HTML5 Web Audio API给网页JS交互增加声音](<https://www.zhangxinxu.com/wordpress/2017/06/html5-web-audio-api-js-ux-voice/>) (0.099)
  * [HTML5 video视频播放Picture-in-Picture画中画技术](<https://www.zhangxinxu.com/wordpress/2018/12/html5-video-play-picture-in-picture/>) (0.099)
  * [HTML audio基础API完全使用指南](<https://www.zhangxinxu.com/wordpress/2019/07/html-audio-api-guide/>) (0.099)
  * [不使用JavaScript让IE浏览器支持HTML5元素](<https://www.zhangxinxu.com/wordpress/2012/07/no-javascript-ie-html5-elements/>) (RANDOM - 0.035)
