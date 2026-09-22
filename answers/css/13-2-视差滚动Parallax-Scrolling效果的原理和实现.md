# 视差滚动(Parallax Scrolling)效果的原理和实现

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.cnblogs.com/JoannaQ/archive/2013/02/08/2909111.html>
> 对应题目：CSS 第 13 题 · 视差滚动
> 抓取时间：2026-09-22

---

**视差滚动（Parallax Scrolling）** 是指让多层背景以不同的速度移动，形成立体的运动效果，带来非常出色的视觉体验。作为今年网页设计的热点趋势，越来越多的网站应用了这项技术。

可以先看看效果：<http://www.ok-studios.de/home/>

**一、什么是视差滚动？**

视差效果，原本是一个天文学术语，当我们观察星空时，离我们远的星星移动速度较慢，离我们近的星星移动速度则较快。当我们坐在车上向车窗外 看时，也会有这样的感觉，远处的群山似乎没有在动，而近处的稻田却在飞速掠过。许多游戏中都使用视差效果来增加场景的立体感。说的简单点就是网页内的元素在滚动屏幕时发生的位置的变化，然而各个不同的元素位置变化的速度不同，导致网页内的元素有层次错落的错觉，这和我们人体的眼球效果很像。我看到多家产品商用视差滚动效果来展示产品，从不同的空间角度和用户体验，起到了非常不错的效果。

目前这种视差滚动效果被越来越多的国外网站所应用， 成为网页设计的热点趋势。

通过一个很长的网页页面，其中利用一些令人惊叹的插图和图形，并使用视差滚动（Parallax Scrolling）效果，让多层背景以不同的速度移动，形成立体的运动效果，带来非常出色的视觉体验。完美的展示了一个复杂的过程，让你犹如置身其中。厌倦了千篇一律，呆板网页设计的你不放一试。

就是固定背景不让它随着滚动轴移动，但包含背景的容器是跟着滚动的，所造成的视觉差异看起来就像跟转换场景一样。

**二、视差滚动效果的主要特点：**

1、直观的设计，快速的响应速度，更合适运用于单页面

2、差异滚动 分层视差  
页面上很多的元素在相互独立地滚动着，如果我们来对其它分层的话，可以有两到三层 ：背景层，内容层，贴图层。  

**三、原理**

通过前景与背景在场景移动时产生不同的视差，从而达到简单的立体效果

页面上很多的元素在相互独立地滚动着，如果我们来对其它分层的话，可以有两到三层 ：背景层，内容层，贴图层

**差异滚动的实现规则：**

  * 背景层的滚动(最慢)
  * 贴图层(内容层和背景层之间的元素)的滚动(次慢)
  * 内容层的滚动(可以和页面的滚动速度一致)

我们让三个图层的滚动速度不一致，就做出了漂亮的差异滚动效果

![](http://images0.cnblogs.com/blog/433579/201302/08042206-04026f450dd94bb88c532d9fecb988f5.jpg)

![](http://images0.cnblogs.com/blog/433579/201302/08042215-a093f73cbfcc4eadb7185ee08622cbec.jpg)

![](http://images0.cnblogs.com/blog/433579/201302/08042312-6022fb0a83d44f678bc8d0163c299693.jpg)

![](http://images0.cnblogs.com/blog/433579/201302/08042328-a51a3ae051604b6b80b82798b80b9d8b.jpg)

1、运用大背景

这些背景图像一般是高分辨率，大图，覆盖整个网站。高清照片是一个迅速抓住观众的好方式，可以产生极具冲击力的视觉效果,用户的视线会不自觉地落在宽大的背景上

注意：

1\. 1、背景图的色彩、内容在选择时要十分讲究，前提是不要破坏用户的体验，不然再漂亮的照片也是枉然。

图片类型最好选取趋向于一些比较柔和、略带透明的一类，不要影响到网站主体内容的阅读，识别，讲究协调。

1.2、以大量图片为特色的页面应该考虑图像的预加载问题，以便为用户提供更好更流畅的视觉体验.

2、你也可以用简单的配色方案

没有比纯色的背景更直观更简洁。纯色可以有很多种表达方式，一个视差区间内颜色最好保持使用2到3种，我们可以调整颜色的透明度，来达到各种视觉效果

3、定位好背景层，贴图层和内容层之间的关系

根据页面自身的功能来定义是否需要贴图层，贴图层的存在是为了更有效的传达视觉效果，但如果它成为了干扰，就会违背了我们使用的初衷

内容层的展现是最主要的，无论背景层和贴图层有多少花哨，在设计师设计过程中，内容层对用户的展示是最优先的

4、讲故事

有力的表现、简约的风格和设计的美感共同构成了一个出色地交互式叙事体验。我们经常听到这样的话：内容是王道，技术只是实现内容的一种工具。当你能够成功地把有力的信息和漂亮的执行力结合起来，你就能创造出人们喜欢并且享受其中的体验。 ————Wieden+Kennedy

TWO 数据可视化——信息图形设计 故事1 传统水银体温计和大字母水银体温计 

![](http://admin5.com/upimg/allimg/130116/1911343354-13.jpg)

**四、实现方法和工具**

**1、在CSS中定义背景滚动方式的属性是backgroud-attacthment**

**background-attachment** \-- 定义背景图片随滚动轴的移动方式

  * 取值: scroll | fixed | inherit 
    * scroll: 默认值。背景图像会随着页面其余部分的滚动而移动。
    * fixed: 当页面的其余部分滚动时，背景图像不会移动。
    * inherit: 规定应该从父元素继承 background-attachment 属性的设置。
    * 初始值: scroll
    * 继承性: 否
    * 适用于: 所有元素

附带w3c的链接：<http://www.w3school.com.cn/css/pr_background-attachment.asp>

浏览器的支持性：

测试了chrome,opera,safari,firefox,ie7-8都是可以的，所以就是说IE6下不行~

在IE6下使用这个属性，需要把background-attachment:fixed放置于body或html当中，就是说你说在其它标签里面是没用。上面的w3c里可以看得到效果就是因为它是放在body里的。

    <!doctype html>
    <html>
        <head>
            <meta charset="utf-8">
            <title>滚动视觉差示例</title>
            <style>
                *{
                    padding:0;
                    margin:0
                }
                body{
                    text-align:center;
                    background-attachment:fixed;
                }
                #main{
                    width: 1280px;
                    margin:auto
                }
                .header{
                    background:#fff;
                    padding: 10px 0
                }
                .bg-attachment{
                    background:url(6.jpg) center center no-repeat;
                    box-shadow:0 7px 18px #000000 inset,0 -7px 18px #000000 inset;
                    -webkit-box-shadow:0 7px 18px #000000 inset,0 -7px 18px #000000 inset;
                    -moz-box-shadow: 0 7px 18px #000000 inset,0 -7px 18px #000000 inset;
                    -o-box-shadow: 0 7px 18px #000000 inset,0 -7px 18px #000000 inset;
                    -ms-box-shadow: 0 7px 18px #000000 inset,0 -7px 18px #000000 inset;
                    background-attachment:fixed;
                }
                .bg-attachment .shadow{
                    width:80%;
                    height:700px;
                    overflow:hidden;
                    margin:auto;
                }
                .div2{
                    background:url(qingz.jpg) center center no-repeat;
                    background-attachment:fixed;
                }
            </style>
        </head>
        <body>
            <div id="main">
                <div class="header">
                    <img src="5.jpg">
                </div>
                <div class="bg-attachment">
                    <div class="shadow"></div>
                </div>
                <div class="header">
                    <img src="qi.jpg">
                </div>
                <div class="bg-attachment div2">
                    <div class="shadow"></div>
                </div>
            </div>
        </body>
    </html>

**2、插件**

[Scrollorama](<http://johnpolacek.github.com/scrollorama/>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154136Ehk.jpg)](<http://johnpolacek.github.com/scrollorama/>)

### [curtain.js](<https://github.com/victa/curtain.js>) **类似于幕布升起的效果**

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154137qp7.jpg)](<https://github.com/victa/curtain.js>)

### [jQuery-Parallax](<https://github.com/IanLunn/jQuery-Parallax>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154137UPI.jpg)](<https://github.com/IanLunn/jQuery-Parallax>)

### [stellar.js](<http://markdalgleish.com/projects/stellar.js/>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154137tdh.jpg)](<http://markdalgleish.com/projects/stellar.js/>)

### [jparallax](<http://stephband.info/jparallax/>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/1541376Su.jpg)](<http://stephband.info/jparallax/>)

### [Skrollr](<http://prinzhorn.github.com/skrollr/>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154137yG4.jpg)](<http://prinzhorn.github.com/skrollr/>)

### [Parallax.js](<http://stolksdorf.github.com/Parallaxjs/>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154137org.jpg)](<http://stolksdorf.github.com/Parallaxjs/>)

### [A Simple Parallax Scrolling Technique via Nettuts+](<http://net.tutsplus.com/tutorials/html-css-techniques/simple-parallax-scrolling-technique/>)

[![滚动视差网站工具与教程](http://www.qianduan.net/wp-content/uploads/image/2012/12/154137RvI.jpg)](<http://net.tutsplus.com/tutorials/html-css-techniques/simple-parallax-scrolling-technique/>)

****[Parallax Slider](<http://tympanus.net/Tutorials/ParallaxSlider/>)****

**3、教程**

  * **[Javascript视差效果](<http://www.ianlunn.co.uk/blog/code-tutorials/javascript-parallax-effects-a-deeper-look/>)**
  * **[Nike Better World场景的背后](<http://coding.smashingmagazine.com/2011/07/12/behind-the-scenes-of-nike-better-world/>)** 一份为那些急切想重现NIKE网站滚动效果的设计师准备的教程。 
  * **[用jQuery和CSS构建一个具有视差滚动效果的网站界面](<http://f6design.com/projects/parallax-scrolling/>) **一份为那些想在此领域了解的更深的设计师准备的例子和教程。 
  * **[用JQuery创建一个时尚的具有视差背景的效果](<http://f6design.com/journal/2011/08/06/build-a-parallax-scrolling-website-interface-with-jquery-and-css/>)** 一份教程，在背景上帮你添加一些滚动的云彩。 
  * **[动画背景式的网页头部](<http://www.jquery4u.com/animation/jquery-parallax-tutorial/>)** 用一个动画式的网页头部来让你的访问者为你欢呼吧！
  * **[视差滚动教程](<http://www.richardshepherd.com/smashing/parallax/background.html>)** 一份视差效果和内容同时出现的有趣的教程。 

**四、超炫的视差滚动效果网站设计欣赏**

**[GLP创意](<http://www.tridentpp.com/>)**

![无限滚动-18](http://www.ffpic.com/upload/20130909/2013090907264958.jpg)

[**divups**](<http://www.divups.com/>)

[**![](http://images0.cnblogs.com/blog/433579/201305/28224211-f7637a00f8ba465b8f18b2c0cf32a0c2.png)**](<http://www.divups.com/>)

##### [New ebay](<http://www.ebay.com/new/>)

[![New ebay](http://img.qianduan.net/uploads/2012/10/parallaxscrolling0.jpg)](<http://www.ebay.com/new/>)

[360 Long Road Zurich](<http://www.360langstrasse.sf.tv/page/>)

![](http://images0.cnblogs.com/blog/433579/201302/08041851-003fc97359bc4f518842cb28113d9c57.jpg)

##### [Q Music Titanic](<http://titanic.q-music.be/>)

[![Q music Titanic](http://img.qianduan.net/uploads/2012/10/parallaxscrolling2.jpg)](<http://titanic.q-music.be/>)

##### [Putzengel](<http://www.putzengel.at/#moveto_contact>)

[![Putzengel](http://img.qianduan.net/uploads/2012/10/parallaxscrolling3.jpg)](<http://www.putzengel.at/#moveto_contact>)

##### [OK Studios](<http://www.ok-studios.de/home/>)

[![OK Studios](http://img.qianduan.net/uploads/2012/10/parallaxscrolling4.jpg)](<http://www.ok-studios.de/home/>)

##### [Nike Better World](<http://www.nikebetterworld.com/about>)

[![Nike Better World](http://img.qianduan.net/uploads/2012/10/parallaxscrolling5.jpg)](<http://www.nikebetterworld.com/about>)

##### [Ben the Bodyguard](<http://benthebodyguard.com/index.php>)

[![Ben the Body Guard](http://img.qianduan.net/uploads/2012/10/parallaxscrolling6.jpg)](<http://benthebodyguard.com/index.php>)

##### [Egopop Creative Studio](<http://www.egopop.net/>)

[![Egopop Creative Studio](http://img.qianduan.net/uploads/2012/10/parallaxscrolling7.jpg)](<http://www.egopop.net/>)

##### [Smokey Bones](<http://smokeybones.com/>)

[![Smokey Bones](http://img.qianduan.net/uploads/2012/10/parallaxscrolling8.jpg)](<http://smokeybones.com/>)

##### [Cultural Solutions](<http://www.culturalsolutions.co.uk/>)

[![Cultural Solutions](http://img.qianduan.net/uploads/2012/10/parallaxscrolling9.jpg)](<http://www.culturalsolutions.co.uk/>)

##### [The Beatles Rock Band](<http://www.thebeatlesrockband.com/>)

[![The Beatles Rock Band](http://img.qianduan.net/uploads/2012/10/parallaxscrolling10.jpg)](<http://www.thebeatlesrockband.com/>)

##### [XHTML Slicing](<http://www.xhtmlslicing.com/>)

[![XHTML Slicing](http://img.qianduan.net/uploads/2012/10/parallaxscrolling11.jpg)](<http://www.xhtmlslicing.com/>)

##### [Farmhouse Fare](<http://www.farmhousefare.co.uk/>)

[![Farmhouse Fare](http://img.qianduan.net/uploads/2012/10/parallaxscrolling12.jpg)](<http://www.farmhousefare.co.uk/>)

##### [Sullivan NYC](<http://www.sullivannyc.com/>)

[![Sullivan NYC](http://img.qianduan.net/uploads/2012/10/parallaxscrolling13.jpg)](<http://www.sullivannyc.com/>)

##### [I to Sie Ceni](<http://www.itosieceni.pl/>)

[![I to Sie Ceni](http://img.qianduan.net/uploads/2012/10/parallaxscrolling14.jpg)](<http://www.itosieceni.pl/>)

##### [Grab and Go](<http://grabandgo.pt/grab.html>)

[![Grab and Go](http://img.qianduan.net/uploads/2012/10/parallaxscrolling15.jpg)](<http://grabandgo.pt/grab.html>)

##### [Micro-Site for Mario Kart Wii](<http://www.nintendo.com.au/gamesites/mariokartwii/#competition>)

[![Micro-site for Mario Kart Wii](http://img.qianduan.net/uploads/2012/10/parallaxscrolling16.jpg)](<http://www.nintendo.com.au/gamesites/mariokartwii/#competition>)

##### [Air Jordan 2012](<http://www.nike.com/jumpman23/aj2012/>)

[![Air Jordan 2012](http://img.qianduan.net/uploads/2012/10/parallaxscrolling17.jpg)](<http://www.nike.com/jumpman23/aj2012/>)

##### [Micro-site for Mario Kart Wii](<http://www.nintendo.com.au/gamesites/mariokartwii/#home>)

[![Micro-site for Mario Kart Wii](http://img.qianduan.net/uploads/2012/10/parallaxscrolling18.jpg)](<http://www.nintendo.com.au/gamesites/mariokartwii/#home>)

##### [Unfold](<http://unfold.no/>)

[![Unfold](http://img.qianduan.net/uploads/2012/10/parallaxscrolling19.jpg)](<http://unfold.no/>)

##### [Dentsu Network](<http://www.dentsunetwork.com/#/history>)

[![Dentsu Network](http://img.qianduan.net/uploads/2012/10/parallaxscrolling20.jpg)](<http://www.dentsunetwork.com/#/history>)

##### [ResIm](<http://www.resolutionim.com/speed>)

[![ResIm](http://img.qianduan.net/uploads/2012/10/parallaxscrolling21.jpg)](<http://www.resolutionim.com/speed>)

##### [Jan Ploch](<http://www.janploch.de/>)

[![Jan Ploch](http://img.qianduan.net/uploads/2012/10/parallaxscrolling22.jpg)](<http://www.janploch.de/>)

##### [Kry-Ptis](<http://www.kryptis.com/#about>)

[![Kry-Ptis](http://img.qianduan.net/uploads/2012/10/parallaxscrolling23.jpg)](<http://www.kryptis.com/#about>)

##### [Anna Safroncik](<http://annasafroncik.it/>)

[![Anna Safroncik](http://img.qianduan.net/uploads/2012/10/parallaxscrolling24.jpg)](<http://annasafroncik.it/>)

##### [Unfinished Business](<http://www.unfinishedbusiness.is/>)

[![Unfinished Business](http://img.qianduan.net/uploads/2012/10/parallaxscrolling25.jpg)](<http://www.unfinishedbusiness.is/>)

##### [Volkswagen-Beetle](<http://www.beetle.com/>)

[![Volkswagen-Beetle](http://img.qianduan.net/uploads/2012/10/parallaxscrolling26.jpg)](<http://www.beetle.com/>)

##### [Appmiral](<http://www.appmiral.com/>)

[![Appmiral](http://img.qianduan.net/uploads/2012/10/parallaxscrolling27.jpg)](<http://www.appmiral.com/>)

##### [Atlantis World’s Fair](<http://lostworldsfairs.com/atlantis/>)

[![Atlantis World's Fair](http://img.qianduan.net/uploads/2012/10/parallaxscrolling28.jpg)](<http://lostworldsfairs.com/atlantis/>)

##### [Johan Reinhold](<http://www.johanreinhold.com/>)

[![Johan Reinhold](http://img.qianduan.net/uploads/2012/10/parallaxscrolling29.jpg)](<http://www.johanreinhold.com/>)

##### [Iutopi](<http://www.iutopi.com/>)

[![Iutopi](http://img.qianduan.net/uploads/2012/10/parallaxscrolling30.jpg)](<http://www.iutopi.com/>)

##### [Beautiful Explorer](<http://www.beautifulexplorer.com/main.html?skip=1>)

[![Beautiful Explorer](http://img.qianduan.net/uploads/2012/10/parallaxscrolling31.jpg)](<http://www.beautifulexplorer.com/main.html?skip=1>)

##### [Bagigia](<http://www.bagigia.com/>)

[![Bagigia](http://img.qianduan.net/uploads/2012/10/parallaxscrolling32.jpg)](<http://www.bagigia.com/>)

##### [Activate Drinks](<http://activatedrinks.com/#/products>)

[![Activate Drinks](http://img.qianduan.net/uploads/2012/10/parallaxscrolling33.jpg)](<http://activatedrinks.com/#/products>)

##### [Tokyu Agency Recruit 2013](<http://www.tokyu-agc.co.jp/recruit/2013/special/>)

[![Tokyu Agency Recruit 2013](http://img.qianduan.net/uploads/2012/10/parallaxscrolling34.jpg)](<http://www.tokyu-agc.co.jp/recruit/2013/special/>)

##### [Von Dutch](<http://www.vondutch.com/>)

[![Von Dutch](http://img.qianduan.net/uploads/2012/10/parallaxscrolling35.jpg)](<http://www.vondutch.com/>)

##### [Playtend](<http://playtend.com/>)

[![Playtend](http://img.qianduan.net/uploads/2012/10/parallaxscrolling36.jpg)](<http://playtend.com/>)

##### [Phase 2 Design Studio](<http://www.phase2technology.com/design>)

[![Phase 2 Design Studio](http://img.qianduan.net/uploads/2012/10/parallaxscrolling37.jpg)](<http://www.phase2technology.com/design>)

##### [Friendly Gents](<http://www.friendlygents.com/>)

[![Friendly Gents](http://img.qianduan.net/uploads/2012/10/parallaxscrolling38.jpg)](<http://www.friendlygents.com/>)

##### [TokioLab](<http://www.tokiolab.it/#/>)

[![TokioLab](http://img.qianduan.net/uploads/2012/10/parallaxscrolling39.jpg)](<http://www.tokiolab.it/#/>)

##### [Krystalrae](<http://krystalrae.com/#collection>)

[![Krystalrae](http://img.qianduan.net/uploads/2012/10/parallaxscrolling40.jpg)](<http://krystalrae.com/#collection>)

##### [No leath](<http://www.noleath.com/noleath/>)

[![No leath](http://img.qianduan.net/uploads/2012/10/parallaxscrolling41.jpg)](<http://www.noleath.com/noleath/>)

##### [Dangers of Fracking](<http://dangersoffracking.com/> "Dangers of Fracking")

[![](http://img.qianduan.net/uploads/2012/10/parallaxscrolling42.jpg)](<http://dangersoffracking.com/> "Dangers of Fracking")

##### [Mo’s & Bows](<http://www.mosandbows.com.au/> "Mo's and Bows")

[![](http://img.qianduan.net/uploads/2012/10/parallaxscrolling43.jpg)](<http://www.mosandbows.com.au/>)

##### [Tinke](<http://www.zensorium.com/tinke/> "Tinke")

[![](http://img.qianduan.net/uploads/2012/10/parallaxscrolling44.jpg)](<http://www.zensorium.com/tinke/>)

##### [Whiteboard](<http://whiteboard.is/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling45.jpg)](<http://whiteboard.is/>)

##### [New Zealand](<http://www.newzealand.com/us/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling46.jpg)](<http://www.newzealand.com/us/>)

##### [Marcus Thomas](<http://www.marcusthomasllc.com/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling47.jpg)](<http://www.marcusthomasllc.com/>)

##### [Fishy](<http://www.fishy.com.br/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling48.jpg)](<http://www.fishy.com.br/>)

##### [Soleil Noir](<http://www.soleilnoir.net/believein/#/start>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling49.jpg)](<http://www.soleilnoir.net/believein/#/start>)

##### [kinvara3](<http://community.saucony.com/kinvara3/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling50.jpg)](<http://community.saucony.com/kinvara3/>)

##### [Smokey Bones](<http://www.smokeybones.com/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling51.jpg)](<http://www.smokeybones.com/>)

##### [Laurentius : Jaarverslag 2010](<http://www.laurentiuswonen.com/jaarverslag2010/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling52.jpg)](<http://www.laurentiuswonen.com/jaarverslag2010/>)

##### [ala](<http://ala.ch/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling53.jpg)](<http://ala.ch/>)

##### [Bomb Girls](<http://www.globaltv.com/bombgirls/index.html>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling54.jpg)](<http://www.globaltv.com/bombgirls/index.html>)

##### [Head2Heart](<http://www.head2heart.us/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling55.jpg)](<http://www.head2heart.us/>)

##### [Michelberger Booze<](<http://www.michelbergerbooze.com/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling56.jpg)](<http://www.michelbergerbooze.com/>)

##### [Ascensión Latorre](<http://www.ascensionlatorre.com/es/home>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling57.jpg)](<http://www.ascensionlatorre.com/es/home>)

##### [Biamar](<http://www.biamar.com.br/>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling58.jpg)](<http://www.biamar.com.br/>)

##### [inTacto 10 Years](<http://www.intacto10years.com/index_start.php>)

[![Parallax Scrolling in Web Design](http://img.qianduan.net/uploads/2012/10/parallaxscrolling59.jpg)](<http://www.intacto10years.com/index_start.php>)
