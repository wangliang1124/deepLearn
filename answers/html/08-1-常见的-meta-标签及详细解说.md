# 常见的 meta 标签及详细解说

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/ce6edbe8825d>
> 对应题目：HTML 第 8 题 · HTML meta 标签
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

### 常见的meta标签

##### 定义和用法：

**< meta> 元素可提供有关页面的元信息（meta-information），比如针对搜索引擎和更新频度的描述和关键词。  
meta 标签位于文档的头部，不包含任何内容。<meta> 标签的属性定义了与文档相关联的名称/值对。  
在 HTML 中，<meta> 标签没有结束标签。  
在 XHTML 中，<meta> 标签必须被正确地关闭。  
注释：<meta> 标签永远位于 head 元素内部。  
注释：元数据总是以名称/值的形式被成对传递的。**  
meta标签中必需的属性：

**属性：content**  
值：some_text  
描述：定义与 http-equiv 或 name 属性相关的元信息  
注意：content 属性始终要和 name 属性或 http-equiv 属性一起使用。  
meta标签中可用的属性：

**属性：http-equiv**  
值：content-type，expires，refresh，set-cookie  
描述：把 content 属性关联到 HTTP 头部。  
例如：

    <meta http-equiv="charset" content="iso-8859-1">

**属性：name**

值：author，description，keywords，generator，revised，others  
描述：把 content 属性关联到一个名称。  
例如：

    <meta name="keywords" content="HTML,ASP,PHP,SQL">

**属性：scheme**

值：some_text  
描述：定义用于翻译 content 属性值的格式。  
例如：

    <meta scheme="dreamdu tutorial" name="url" content="http://www.dreamdu.com">

meta标签的name属性语法格式是：

    <meta name="参数"content="具体的参数值">。 

其中name属性主要有以下几种参数：

### Keywords(关键字)

说明：keywords用来告诉搜索引擎你网页的关键字是什么。

举例：

    <meta name="keywords"content="meta总结,html meta,meta属性,meta跳转"> 

description(网站内容描述)

说明：description用来告诉搜索引擎你的网站主要内容。

举例：

    <meta name="description"content="haorooms博客,html的meta总结，meta是html语言head区的一个辅助性标签。"> 

#### robots(机器人向导)

说明：robots用来告诉搜索机器人哪些页面需要索引，哪些页面不需要索引。

content的参数有all,none,index,noindex,follow,nofollow。默认是all。

举例：

    <meta name="robots"content="none"> 

具体参数如下：

信息参数为all：文件将被检索，且页面上的链接可以被查询；

信息参数为none：文件将不被检索，且页面上的链接不可以被查询；

信息参数为index：文件将被检索；

信息参数为follow：页面上的链接可以被查询；

信息参数为noindex：文件将不被检索，但页面上的链接可以被查询；

信息参数为nofollow：文件将被检索，但页面上的链接不可以被查

#### author(作者)

说明：标注网页的作者

举例：

    <meta name="author"content="root,root@xxxx.com"> 

#### generator

    <meta name="generator"content="信息参数"/> 

meta标签的generator的信息参数，代表说明网站的采用的什么软件制作。

#### COPYRIGHT

    <META NAME="COPYRIGHT"CONTENT="信息参数"> 

meta标签的COPYRIGHT的信息参数，代表说明网站版权信息。

#### revisit-after

    <META name="revisit-after"CONTENT="7days"> 

revisit-after代表网站重访,7days代表7天，依此类推。

#### Viewport

说明：设置页面缩放比例

    <meta name=”viewport” content=”width=device-width, initial-scale=1, maximum-scale=1″>

width：控制 viewport 的大小，可以指定的一个值，如果 600，或者特殊的值，如 device-width 为设备的宽度（单位为缩放为 100% 时的 CSS 的像素）。  
height：和 width 相对应，指定高度。  
initial-scale：初始缩放比例，也即是当页面第一次 load 的时候缩放比例。  
maximum-scale：允许用户缩放到的最大比例。  
minimum-scale：允许用户缩放到的最小比例。  
user-scalable：用户是否可以手动缩放

### **http-equiv属性**

http-equiv顾名思义，相当于http的文件头作用，它可以向浏览器传回一些有用的信息，以帮助正确和精确地显示网页内容，与之对应的属性值为content，content中的内容其实就是各个参数的变量值。

meta标签的http-equiv属性语法格式是：

    <meta http-equiv="参数"content="参数变量值">； 

其中http-equiv属性主要有以下几种参数：

**1、Expires(期限)**

说明：可以用于设定网页的到期时间。一旦网页过期，必须到服务器上重新传输。

用法：

    <meta http-equiv="expires"content="Fri,12Jan200118:18:18GMT"> 

注意：必须使用GMT的时间格式。

**2、Pragma(cache模式)**

说明：禁止浏览器从本地计算机的缓存中访问页面内容。

用法：

    <meta http-equiv="Pragma"content="no-cache"> 

注意：这样设定，访问者将无法脱机浏览。

**3、Refresh(刷新)**

说明：自动刷新并指向新页面。

用法：

    <meta http-equiv="Refresh"content="2;URL=http://www.haorooms.com"> //(注意后面的引号，分别在秒数的前面和网址的后面) 

注意：其中的2是指停留2秒钟后自动刷新到URL网址。

**4、Set-Cookie(cookie设定)**

说明：如果网页过期，那么存盘的cookie将被删除。

用法：

    <meta http-equiv="Set-Cookie"content="cookie value=xxx;expires=Friday,12-Jan-200118:18:18GMT；path=/"> 

注意：必须使用GMT的时间格式。

**5、Window-target(显示窗口的设定)**

说明：强制页面在当前窗口以独立页面显示。

用法：

    <meta http-equiv="Window-target"content="_top"> 

注意：用来防止别人在框架里调用自己的页面。

**6、content-Type(显示字符集的设定)**

说明：设定页面使用的字符集。

用法：

    <meta http-equiv="content-Type"content="text/html;charset=gb2312"> 

具体如下：

meta标签的charset的信息参数如GB2312时，代表说明网站是采用的编码是简体中文；

meta标签的charset的信息参数如BIG5时，代表说明网站是采用的编码是繁体中文；

meta标签的charset的信息参数如iso-2022-jp时，代表说明网站是采用的编码是日文；

meta标签的charset的信息参数如ks_c_5601时，代表说明网站是采用的编码是韩文；

meta标签的charset的信息参数如ISO-8859-1时，代表说明网站是采用的编码是英文；

meta标签的charset的信息参数如UTF-8时，代表世界通用的语言编码；

**7、content-Language（显示语言的设定）**

用法：

    <meta http-equiv="Content-Language"content="zh-cn"/> 

**8、Cache-Control指定请求和响应遵循的缓存机制。**

Cache-Control指定请求和响应遵循的缓存机制。在请求消息或响应消息中设置Cache-Control并不会修改另一个消息处理过程中的缓存处理过程。请求时的缓存指令包括no-cache、no-store、max-age、max-stale、min-fresh、on

ly-if-cached，响应消息中的指令包括public、private、no-cache、no-store、no-transform、must-revalidate、proxy-revalidate、max-age。各个消息中的指令含义如下

Public指示响应可被任何缓存区缓存

Private指示对于单个用户的整个或部分响应消息，不能被共享缓存处理。这允许服务器仅仅描述当用户的部分响应消息，此响应消息对于其他用户的请求无效

no-cache指示请求或响应消息不能缓存

no-store用于防止重要的信息被无意的发布。在请求消息中发送将使得请求和响应消息都不使用缓存。

max-age指示客户机可以接收生存期不大于指定时间（以秒为单位）的响应

min-fresh指示客户机可以接收响应时间小于当前时间加上指定时间的响应

max-stale指示客户机可以接收超出超时期间的响应消息。如果指定max-stale消息的值，那么客户机可以接收超出超时期指定值之内的响应消息。

**9、http-equiv="imagetoolbar"**

    <meta http-equiv="imagetoolbar"content="false"/> 

指定是否显示图片工具栏，当为false代表不显示，当为true代表显示。

**10、Content-Script-Type**

    <Meta http-equiv="Content-Script-Type"Content="text/javascript">
