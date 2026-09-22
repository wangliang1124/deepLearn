# CSS3 box-sizing 详解

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.cnblogs.com/iflygofy/p/6323275.html>
> 对应题目：CSS 第 2 题 · CSS3 Box-sizing
> 抓取时间：2026-09-22

---

人们慢慢的意识到传统的盒子模型不直接，所以他们新增了一个叫做 `box-sizing` 的CSS属性。

**`box-sizing:`** 盒大小,盒模型.

我们经常遇到左右模块宽度为50%，加个边框会掉下去，加一个这个样式就能解决，看下栗子：

    <!DOCTYPE html>
    <html>
    <head>
    <style> 
    div.container
    {
    width:300px;
    border:10px solid blue;
    }
    div.box
    {
    box-sizing:border-box;
    -moz-box-sizing:border-box; /* Firefox */
    -webkit-box-sizing:border-box; /* Safari */
    width:50%;
    height:80px;
    padding:10px;
    border:10px solid red;
    float:left;
    }
    </style>
    </head>
    <body>

    <div class="container">
    <div class="box">这个 div 占据左半部分。</div>
    <div class="box">这个 div 占据右半部分。</div>
    <div style="clear:both;"></div>
    </div>

    </body>
    </html>

![](data:image/png;base64,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)

box-sizing属性可以为三个值之一：content-box（default），border-box，padding-box。

content-box，border和padding不计算入width之内

padding-box，padding计算入width内

border-box，border和padding计算入width之内，其实就是怪异模式了。

梨子：

    <style type="text/css">
        .content-box{
            box-sizing:content-box;
            -moz-box-sizing:content-box;
            width: 100px;
            height: 100px;
            padding: 20px;
            border: 5px solid #E6A43F;
            background: blue;
        }
        .padding-box{
            box-sizing:padding-box;
            -moz-box-sizing:padding-box;
            width: 100px;
            height: 100px;
            padding: 20px;
            border: 5px solid #186645;
            background: red;                
        }
        .border-box{
            box-sizing:border-box;
            -moz-box-sizing:border-box;
            width: 100px;
            height: 100px;
            padding: 20px;
            border: 5px solid #3DA3EF;
            background: yellow;
        }
    </style>

![](data:image/png;base64,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)
