# 使用 css 实现一个持续的动画效果

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.cnblogs.com/gaoxuerong123/p/8540554.html>
> 对应题目：CSS 第 1 题 · CSS Animation
> 抓取时间：2026-09-22

---

1 <!DOCTYPE html>
     2 <html>
     3     <head>
     4         <meta charset="utf-8">
     5         <style>
     6             div{
     7                 width: 100px;
     8                 height: 100px;
     9                 position: relative;
    10                 animation: firstdiv 2s linear 1s infinite alternate;
    11             }
    12             @keyframes firstdiv{
    13                 0%{top:0;left:0;background-color: greenyellow;}
    14                 25%{top:0;left:100px;background-color: green;}
    15                 50%{top:100px;left:100px;background-color: yellow;}
    16                 75%{top:100px;left:0;background-color: gold;}
    17                 100%{top:0;left:0;background-color: greenyellow;}
    18                  
    19             }
    20         </style>
    21     </head>
    22     <body>
    23         <div></div>
    24     </body>
    25 </html>
