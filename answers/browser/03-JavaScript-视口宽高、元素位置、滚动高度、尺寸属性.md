# JavaScript 视口宽高、元素位置、滚动高度、尺寸属性

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/62f691f4811c>
> 对应题目：浏览器 第 3 题 · 视口宽高、位置与滚动高度
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

本章将全面学习JavaScript各种位置信息属性和方法。在我参考了大量文章之后，有的文章很全面但是缺乏直观的图片。有的文章有图片，但是描述信息较少。还有的虽然很详细，但总会漏掉一些属性。希望自己能写一篇文章，让自己更全面理解这些属性。因为很多效果都离不开JS各种位置信息的属性计算，只有理解和记住了这些属性，才能更好的使用，更好的实现比较复杂的效果。

> 这篇文章不再说明浏览器兼容问题，如果需要请参考最后的参考链接文章。

#### 一、window视图位置属性

##### 1.1、window对象获取视口（浏览器窗口）宽高

    console.log(window.innerHeight) // 939
    console.log(window.outerHeight) // 1050
    console.log(window.innerWidth)  // 809
    console.log(window.outerWidth)  // 1680

innerHeight、outerHeight、innerWidth、outerWidth

属性名 | 描述 | 备注  
---|---|---  
`window.innerHeight` | 浏览器窗口高度，如果存在水平滚动条，则包括滚动条 | 只读属性，没有默认值，不支持的浏览器则是undefined  
`window.innerWidth` | 浏览器窗口宽度，如果存在垂直滚动条，则包括滚动条 | 只读属性，没有默认值，不支持的浏览器则是undefined  
`window.outerWidth` | 浏览器窗口整个宽度，包括侧边栏，窗口镶边和调正窗口大小的边框 | 只读属性，没有默认值，不支持的浏览器则是undefined  
`window.outerHeight` | 浏览器窗口整个高度，包括窗口标题、工具栏、状态栏等 | 只读属性，没有默认值，不支持的浏览器则是undefined  

> **注意** ：IE8及以下版本不支持`window.innerHeight`和`window.innerWidth`等属性。  
>  对于不支持`window.innerHeight`等属性的浏览器中，可以读取`documentElement`和`body`的高度。最佳方式为：

    let width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth
    let height = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight

document.documentElement.clientHeight和document.body.clientHeight的区别

`document.documentElement.clientHeight`和`document.body.clientHeight`的区别：

  * `document.documentElement.clientHeight`：不包括整个文档的滚动条，但包括`<html>`元素的边框。
  * `document.body.clientHeight`：不包括整个文档的滚动条，也不包括`<html>`元素的边框，也不包括`<body>`的边框和滚动条。

##### 1.2、window对象获取整个页面滚动的像素值

属性名 | 描述 | 备注 | 别名  
---|---|---|---  
`window.pageXOffset` | 返回文档在水平方向滚动的像素值 | 只读属性，没有默认值，不支持的浏览器则是undefined |  `pageXOffset`是`scrollX`的别名  
`window.pageYOffset` | 返回文档在垂直方向已滚动的像素值 | 只读属性，没有默认值，不支持的浏览器则是undefined |  `pageYOffset`是`scrollY`的别名  

    window.pageXOffset == window.scrollX; // 总是 true
    window.pageYOffset == window.scrollY; // 总是 true

##### 1.3、window对象获取浏览器窗口在显示器中的位置

screenX、screenY、screenLeft、screenTop

属性名 | 描述 | 备注  
---|---|---  
`window.screenX` | 浏览器窗口在显示器中的水平位置 | 不支持的浏览器则是undefined  
`window.screenY` | 浏览器窗口在显示器中的垂直位置 | 不支持的浏览器则是undefined  
`window.screenLeft` | 浏览器可用空间左边距离屏幕（系统桌面）左边界的距离 | 不支持的浏览器则是undefined  
`window.screenTop` | 浏览器窗口在屏幕上的可占用空间上边距离屏幕上边界的距离 | 不支持的浏览器则是undefined  

##### 1.4、Screen对象视图属性：有关显示器（用户屏幕）信息的一些属性

window.screen.width、window.screen.height

window.screen.availWidth、window.screen. availHeight

window.screen.width、window.screen.height、window.screen.availWidth、window.screen. availHeight

属性名 | 描述 | 备注  
---|---|---  
`window.screen.height` | 显示器屏幕的高度，包括工具栏、状态栏等。 |   
`window.screen.width` | 显示器屏幕的宽度，包括工具栏、状态栏等。 |   
`window.screen.availHeight` | 浏览器窗口在屏幕上可占用的高度。 |   
`window.screen.availWidth` | 浏览器窗口在屏幕上可占用的宽度。 |   
`window.screen.colorDepth` | 表示显示器的颜色深度。 |   
`window.screen.pixelDepth` | 该属性基本上与colorDepth一样。 |   

#### 二、元素视图位置属性

关于元素大小位置等信息的一些属性有三个家族（为了自己好记~）：

  * `client`家族：`clientLeft`、`clientTop`、`clientWidth`、`clientHeight`、`height`、`width`
  * `offset`家族：`offsetLeft`、`offsetTop` 、`offsetWidth`、`offsetHeight`、 `offsetParent`
  * `scroll`家族：`scrollLeft`、`scrollTop`、`scrollWidth` 、 `scrollHeight`

##### 2.1、client家族介绍

属性名 | 描述 | 备注  
---|---|---  
`clientLeft` | 表示内容区域的左上角相对于整个元素左上角水平位置（包括边框和滚动条但是不包含元素的padding或margin） | 单纯就是border宽度，返回该方向的border宽度。  
`clientTop` | 表示内容区域的左上角相对于整个元素左上角垂直位置（包括边框和滚动条但是不包含元素的padding或margin） | 单纯就是border高度，返回该方向的border高度。  
`clientWidth` | 表示内容区域的宽度，包括padding大小，但是不包括边框和滚动条。 |   
`clientHeight` | 表示内容区域的高度，包括padding大小，但是不包括边框和滚动条。 |   
`height` | 表示内容区域的高度，不包括padding大小、边框和滚动条。 |   
`width` | 表示内容区域的高度，不包括padding大小、边框和滚动条。 |   

##### 2.2、offset家族介绍

    <main style="position: relative" id="main">
      <article>
        <div id="example" style="position: absolute; left: 180px; top: 180px">...</div>
      </article>
    </main>
    <script>
      alert(example.offsetParent.id); // main
      alert(example.offsetLeft); // 180 (note: a number, not a string "180px")
      alert(example.offsetTop); // 180
    </script>

属性名 | 描述 | 备注  
---|---|---  
`offsetLeft` | 相对于最近的祖先定位元素（CSS position 属性被设置为 relative、absolute 或 fixed 的元素）的左偏移值 |   
`offsetTop` | 相对于最近的祖先定位元素（CSS position 属性被设置为 relative、absolute 或 fixed 的元素）的上偏移值）。 |   
`offsetWidth` | 整个元素的宽度（包括边框）。 |   
`offsetHeight` | 整个元素的高度（包括边框）。 |   
`offsetParent` | 第一个祖定位元素 | offsetParent元素只可能是：<body>、position不是static的元素、<table>, <th> 或<td>，但必须要position: static  

##### 2.3、scroll家族介绍

属性名 | 描述 | 备注  
---|---|---  
`scrollLeft` | 表示元素滚动的宽度 | 可读可写  
`scrollTop` | 表示元素滚动的高度 | 可读可写  
`scrollWidth` | 表示整个内容区域的宽度，包括隐藏的部分。如果元素没有隐藏的部分，则相关的值应该等用于clientWidth和clientHeight。当你向下滚动滚动条的时候，scrollWidth应该等用于scrollTop + clientHeight |   
`scrollHeight` | 表示整个内容区域的高度，包括隐藏的部分。如果元素没有隐藏的部分，则相关的值应该等用于clientWidth和clientHeight。当你向下滚动滚动条的时候，scrollHeight应该等用于scrollLeft + clientWidth |   

#### 三、文档视图(DocumentView)和元素视图(ElementView)方法

关于文档和元素视图的方法有一下几种

  * `elementFromPoint()`
  * `getBoundingClientRect()`
  * `getClientRects()`
  * `scrollIntoView()`

下面会一一介绍这几种方法。

##### 3.1、`elementFromPoint()`方法介绍

返回给定坐标处所在的元素。

###### 3.2、`getBoundingClientRect()`方法介绍

得到矩形元素的界线，返回的是一个对象，包含 top, left, right, 和 bottom四个属性值，大小都是相对于文档视图左上角计算而来。

    {
       bottom: 252
       height: 92
       left: 704
       right: 976
       top: 160
       width: 272
       x: 704
       y: 160
    }

##### 3.3、`getClientRects()`方法介绍

获取元素占据页面的所有矩形区域。返回元素的数个矩形区域，返回的结果是个对象列表，具有数组特性。这里的矩形选区只针对inline box，因此，只针对a, span, em这类标签元素。

###### 3.4、`scrollIntoView()`方法介绍

让元素滚动到可视区域。可以实现元素的锚点跳转功能。

#### 四、小案例

##### 4.1、返回顶部demo

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="X-UA-Compatible" content="ie=edge">
      <title>Document</title>
      <style>
        html {
          height: 5000px;
        }
      </style>
    </head>
    <body>

    <div id="backToTop" style="position:fixed;bottom:80px;right:20px;display: none;cursor: pointer;">返回顶部</div>

    <script>

    if (!window.requestAnimationFrame) {
      requestAnimationFrame = function(fn) {
        setTimeout(fn, 17)
      };    
    }

    if (!window.cancelAnimationFrame) {
      window.cancelAnimationFrame = function(id) {
        clearTimeout(id)
      } 
    }
    const topEl = document.getElementById('backToTop')
    window.addEventListener('scroll',function() {
      const winScrollTop = getWinScrollTop()
      if(winScrollTop > 200) {
        topEl.style.display = 'block'
      } else {
        topEl.style.display = 'none'
      }
    })

    //使用定时器，将scrollTop的值每次减少，直到减少到0，则动画完毕
    document.getElementById('backToTop').onclick = function() {
      let timer = null
      timer = requestAnimationFrame(function fn() {
        const backToTop = getWinScrollTop()
        if(backToTop > 0) {
          document.body.scrollTop = document.documentElement.scrollTop = backToTop - 100
          timer = requestAnimationFrame(fn)
        } else {
          cancelAnimationFrame(timer)
        }
      })
    }
    function getWinScrollTop() {
      return window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop
    }
    </script>
    </body>
    </html>

#### 五、参考链接
