# HTML-meta 标签详解

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/30bf38c799e4>
> 对应题目：HTML 第 8 题 · HTML meta 标签
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

先附上几篇网上查找的关于meta标签的资料、文章，看完这个几篇文章后，会对meta标签有一定的了解！  
[HTML meta标签总结与属性使用介绍](<https://link.jianshu.com?t=http://www.cnblogs.com/wangyang108/p/5995379.html>)  
[html5手机网站需要加的那些meta/link标签，html5 meta全解](<https://link.jianshu.com?t=http://blog.csdn.net/kongjiea/article/details/17092413>)

##### 下边这些内容是对一些资料进行了整理，因为有的文章由于广告或者页面排版看起来不是很舒服，所以对一些介绍meta标签比较全面的文章进行了整理。内容会有重复或者冲突，仅供参考！！！

* * *

**第一篇**  
META的属性有三个:name,http-equiv和content  
先说Name和Content:  
META的NAME属性就说说明当前的META标签是什么类型,以便于搜索引擎抓取,索引网页。相应的Content就是告诉搜索引擎相关的信息。  
打个比方`<meta name= keywords content= meta />`这行代码的意思就是说:这个网页的关键词是meta”  
Name的常用取值有下面几种  
1、Keywords:关键字,即告诉搜索引擎,这个网页的主题是什么。示例:`<meta name= Keywords Content= 关键字,关键字1,关键字2,关键字3,...,... />`  
每个关键字之间,应该用用英文的逗号,”分隔开。  
当数个META元素提供文档语言从属信息时,搜索引擎会使用lang特性来过滤并通过用户的语言优先参照来显示搜索结果。例如:  
`<meta name= Kyewords Content= vacation,greece,sunshine >`  
`<meta name= Kyewords Content= vacances,grè:ce,soleil >`  
2、Description:简介,即告诉搜索引擎,这个网页的大致内容。就好像Keywords是手机,Description再详细说一下手机的大体功能、优势等等。  
示例:`<meta name= Description Content= 这个网页讲述了的META用法... >`  
3、Robots:纯粹写给搜索引擎看的,因为Keywords和Description,人类还可以看懂,而Robots是非专业人士所无法理解的。  
当name为Robots时,Content可选参数有  
index:当前页面可以被抓取  
follow:被当前页面内所链接的页面可以抓取  
noindex:当前页面不可以被抓取  
nofollow:被当前页面内所链接的页面不可以抓取  
由于Content的内容可以是双选的,例如CONTENT= INDEX,FOLLOW ,所以上述这四个参数,共可以组成4种不同的双选结果。  
其中  
`<META NAME= Robots CONTENT= index,follow />`可以写成`<META NAME= Robots CONTENT= all />`  
`<META NAME= Robots CONTENT= noindex,nofollow />`可以写成`<META NAME= Robots CONTENT= none />`  
4、Author:作者,即告诉搜索引擎,这个页面的作者是谁,一般那种文章性质的页面,这个属性被应用得比较多。  
示例`<meta name= Author Content= czBin,11year@Gmail.com >`  
5、Copyright:版权,告诉搜索引擎,这个页面的版权是属于谁的。  
示例:`<meta name= Copyright Content= 版权信息 >`  
6、Generator:制作软件,难道搜索引擎连这个也需要知道?用FrontPage和Dreamweaver制作出的页面,抓取方式不同吗?  
示例:`<meta name= Generator Content= PCDATA|FrontPage| >`  
7、revisit-after:更新时间,即告诉搜索引擎,这个页面多长时间会更新,到时候,需要来重新抓取示例:`<META name= revisit-after CONTENT= 2 days >`  
再说HTTP-EQUIV:  
META的HTTP-EQUIV属性,其作用类似于HTTP头协议,它会告诉浏览器一些关于字符设定,页面刷新,cookie,和缓存等等相关信息。  
常用的HTTP-EQUIV取值有如下11种:

1、Content-Type:声明页面所适用的的字符集,以及页面文档属性。示例:  
`<meta http-equiv= Content-Type Content= text/html; Charset=gb2312 >`'  
告诉浏览器,该页面为HTML类文档,并且,适用gb2312(中文)作为默认字符。

2、Refresh:设置页面刷新或自动跳转的时间  
。示例  
:  
`<meta http-equiv= Refresh Content= 60 >`  
Content= 60 的意思是说,60秒后,页面刷新  
`<meta http-equiv= Refresh Content= 10; Url=http://www.isinwin.cn >`  
Content= 10 的意思是说,10秒后,网页将自动跳转。

3、Expires:设定网页的过期时间,当网页过期后,必须重新读取页面信息  
。示例  
:  
`<meta http-equiv= Expires Content= Fri, 15 Jun 2007 01:13:13 GMT >`  
`<meta http-equiv= Expires Content= 0 >`  
时间格式必须为GMT标准时间,Content设置为0则代表该网页永不过期。

4、Pragma:禁止浏览器缓存网页。示例:  
`<meta http-equiv= Pragma Content= No-cach >`  
禁止浏览器缓存页面（但是浏览者同样可以保存页面）

5、Set-Cookie :设定cookie的过期时间。示例:  
`<meta http-equiv= Set-Cookie Content= cookievalue=xxx; expires=Wednesday, 21-Oct-98 16:14:21 GMT; path=/ >`

6、Window-target:强制页面在当前窗口以独立页面显示  
。示例  
:  
`<meta http-equiv= Widow-target Content= _top >`  
这个属性是用来防止别人在框架里调用你的页面。Content选项:_blank、_top、_self、_parent。

* * *

**第二篇**  
name属性  
<\-- 页面作者 -->  
`<meta name="author" content="author name" />`  
<\-- 页面描述 -->  
`<meta name="description" content="meta元素共有三个可选属性(不超过150字符)" />`  
<\-- 页面关键词 -->  
`<meta name="keywords" content="meta标签总结,meta标签" />`  
<\-- 页面生成器 -->  
`<meta name="generator" content="hexo" />`  
<\-- 页面修改信息 -->  
`<meta name="revised" content="story,2015/07/22" />`  
<\-- 版权信息 -->  
`<meta name="copyright" content="All Rights Reserved" />`  
<\-- 页面爬虫设置 -->  
`<meta name="robots" content="index,follow" />`  
<\-- robots的content取值 -->  
<\-- all：文件将被检索，且页面上的链接可以被查询 -->  
<\-- none：文件将不被检索，且页面上的链接不可以被查询 -->  
<\-- index：文件将被检索 -->  
<\-- follow：页面上的链接可以被查询 -->  
<\-- noindex：文件将不被检索，但页面上的链接可以被查询 -->  
<\-- nofollow：文件将被检索，但页面上的链接不可以被查询 -->  
http-equiv  
<\-- 字符编码 -->  
`<meta http-equiv="content-type" content="text/html;charset=UTF-8" />`  
<\-- 页面到期时间 -->  
`<meta http-equiv="expire" content="Wed,22Jul201511:11:11GMT" />`  
<\-- 页面重刷新，0秒后刷新并跳转 -->  
`<meta http-equiv="refresh" content="0;URL=''" />`  
<\-- cookie设置 -->  
`<meta http-equiv="set-cookie" content="cookie value=xxx;expires=Wed,22-Jul-201511:11:11GMT；path=/" />`  
<\-- 脚本类型 -->  
`<meta http-equiv="Content-Script-Type"Content="text/javascript">`  
<\-- 禁止从本地缓存中读取页面 -->  
`<meta http-equiv="Pragma"content="no-cache">`  
移动端  
`<meta name="viewport" content="width=device-width, initial-scale=1.0,maximum-scale=1.0, user-scalable=no"/>`  
<\-- viewport的content取值 -->  
<\-- width：宽度（数值 / device-width）（200~10000，默认为980px） -->  
<\-- height：高度（数值 / device-height）（223~10000） -->  
<\-- initial-scale：初始缩放比例 （0~10） -->  
<\-- minimum-scale：允许用户缩放到的最小比例 -->  
<\-- maximum-scale：允许用户缩放到的最大比例 -->  
<\-- user-scalable：是否允许用户缩放 (no/yes) -->

<\-- uc强制竖屏 -->  
`<meta name="screen-orientation" content="portrait">`  
<\-- QQ强制竖屏 -->  
`<meta name="x5-orientation" content="portrait">`  
<\-- UC强制全屏 -->  
`<meta name="full-screen" content="yes">`  
<\-- QQ强制全屏 -->  
`<meta name="x5-fullscreen" content="true">`  
<\-- UC应用模式 -->  
`<meta name="browsermode" content="application">`  
<\-- QQ应用模式 -->  
`<meta name="x5-page-mode" content="app">`

<\-- IOS启用 WebApp 全屏模式 -->  
`<meta name="apple-mobile-web-app-capable" content="yes" />`  
<\-- IOS全屏模式下隐藏状态栏/设置状态栏颜色 content的值为default | black | black-translucent -->  
`<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />`  
<\-- IOS添加到主屏后的标题 -->  
`<meta name="apple-mobile-web-app-title" content="标题">`  
<\-- IOS添加智能 App 广告条 Smart App Banner -->  
`<meta name="apple-itunes-app" content="app-id=myAppStoreID, affiliate-data=myAffiliateData, app-argument=myURL">`

<\-- 去除iphone 识别数字为号码 -->  
`<meta name="format-detection" content="telephone=no">`  
<\-- 不识别邮箱 -->  
`<meta name="format-detection" content="email=no">`  
<\-- 禁止跳转至地图 -->  
`<meta name="format-detection" content="adress=no">`  
<\-- 可以连写-->  
`<meta name="format-detection" content="telephone=no,email=no,adress=no">`
