# 我对 line-height 及 vertical-align 的一点理解

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://segmentfault.com/a/1190000013031367>
> 对应题目：CSS 第 14 题 · 理解 line-height
> 抓取时间：2026-09-22

---

张鑫旭老师在文章《我对CSS vertical-align的一些理解与认识（一）》中提到：

> vertical-align:middle属性的表现与否，仅仅与其父标签有关，至于我们通常看到的与后面的文字垂直居中显示那都是假象！

经过摸索测试，才对这句话有种豁然开朗的感觉。

html：

            <span class="box">
                <span class="dot"></span>
                匿名元素
                <span class="text"> 我是一段卡哇伊的文字。</span>
            </span>

css：

        .box {
            margin: 36px 0;
            border: 1px dashed blue;
            font-size: 12px;
            color: white;
            background: red;
            /*height: 50px;*/  
        }

        .box .dot {
            display: inline-block;
            width: 16px;
            height: 16px;
            /*line-height:50px;*/
            background: white;
            vertical-align: baseline; // 这个baseline到底在哪里
        }

        .box .text {
            vertical-align: middle;
            /*line-height:50px; */
            font-size: 16px;
        }

首先要明白的是，一个行内元素有四条看不见的线（直接复制了张老师文章里的图片）：  
![clipboard.png](https://segmentfault.com/img/bVyf0j?w=500&h=131)  
这四条线的位置由谁决定呢，我认为是**字体的大小** ，当字体的font-size:0时，则四线重合。  
所以实际上子元素的vertical-align对齐是父元素的这几条线，看下图，我直接在父元素span里放乐“匿名元素”几个字，你能直观的发现，子元素对齐的就是“匿名元素”的baseline

另外 ：  
1.vertical-align: baseline/middle...是指此元素的baseline/middle line 和父元素的对齐   
2.对于空的元素，其baseline就是底边缘，比如.dot元素  
![clipboard.png](https://segmentfault.com/img/bV2PYf?w=850&h=230)
