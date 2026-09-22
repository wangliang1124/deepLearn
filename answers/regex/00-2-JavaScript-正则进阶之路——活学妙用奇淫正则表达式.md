# JavaScript 正则进阶之路——活学妙用奇淫正则表达式

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/jawil/blog/issues/20>
> 对应题目：正则表达式 第 0 题 · 正则表达式
> 抓取时间：2026-09-22

---

原文收录在我的 GitHub博客 (<https://github.com/jawil/blog>) ，喜欢的可以关注最新动态，大家一起多交流学习，共同进步，以学习者的身份写博客，记录点滴。

> 有些童鞋肯定有所疑惑，花了大量时间学习正则表达式，却发现没有用武之地，正则不就是验证个邮箱嘛，其他地方基本用不上，其实，大部分人都是这种感觉，所以有些人干脆不学，觉得又难又没多大用处。殊不知，想要成为编程大牛，正则表达式必须玩转，GitHub上优秀的开源库和框架里面到处都是强大的正则匹配，当年jQuery作者也被称为正则小王子。这里分享一些工作中用到的和自己收集的一些正则表达式的妙用，到处闪耀着开发者智慧的火花。

实现一个需求的方法很多种，哪种更好，仁者见仁智者见智，这里只提供一种对比的思维来激发大家学习正则的兴趣和养成活用正则的思维。

作为前端开发人员，总会有点自己的奇技淫巧，毕竟前端开发不同于后端，代码全部暴漏给用户不说，代码冗余了少则影响带宽，多则效率降低。正则表达式（Regular Expression），这是一块硬骨头，很难啃，但是啃着又很香。所以今天我也来爆一些正则表达式的奇技淫巧。

**正则大法好，正则大法好，正则大法好，重要的事情说三遍。**

### 1、获取链接 **`https://www.baidu.com?name=jawil&age=23`** name的value值

**非正则实现：**

    function getParamName(attr) {

      let search = window.location.search // "?name=jawil&age=23"

      let param_str = search.split('?')[1] // "name=jawil&age=23"

      let param_arr = param_str.split('&') // ["name=jawil", "age=23"]

      let filter_arr = param_arr.filter(ele => { // ["name=jawil"]
        return ele.split('=')[0] === attr
      })

      return decodeURIComponent(filter_arr[0].split('=')[1])
    }

    console.log(getParamName('name')) // "jawil"

**用正则实现：**

    function getParamName(attr) {

      let match = RegExp(`[?&]${attr}=([^&]*)`) //分组运算符是为了把结果存到exec函数返回的结果里
        .exec(window.location.search)
      //["?name=jawil", "jawil", index: 0, input: "?name=jawil&age=23"]
      return match && decodeURIComponent(match[1].replace(/\+/g, ' ')) // url中+号表示空格,要替换掉
    }

    console.log(getParamName('name'))  // "jawil"

看不太懂先学习一下这篇文章：[[ JS 进阶 ] test, exec, match, replace](<https://segmentfault.com/a/1190000003497780>)

### 2、 数字格式化问题，1234567890 --> 1,234,567,890

**非正则实现：**

    let test = '1234567890'

    function formatCash(str) {
      let arr = []

      for (let i = 1; i < str.length; i++) {
        if (str.length % 3 && i == 1)
          arr.push(str.substr(0, str.length % 3))

        if (i % 3 === 0)
          arr.push(str.substr(i - 2, 3))

      }

      return arr.join(',')
    }

    console.log(formatCash(test)) // 1,234,567,890

**用正则实现：**

    let test1 = '1234567890'
    let format = test1.replace(/\B(?=(\d{3})+(?!\d))/g, ',')

    console.log(format) // 1,234,567,890

下面简单分析下正则`/\B(?=(\d{3})+(?!\d))/g`：

  1. `/\B(?=(\d{3})+(?!\d))/g`：正则匹配边界`\B`，边界后面必须跟着`(\d{3})+(?!\d)`;
  2. `(\d{3})+`：必须是1个或多个的3个连续数字;
  3. `(?!\d)`：第2步中的3个数字不允许后面跟着数字;
  4. `(\d{3})+(?!\d)`：所以匹配的边界后面必须跟着`3*n`（n>=1）的数字。

最终把匹配到的所有边界换成`,`即可达成目标。

### 3、去掉字符串左右两边的空格，" jaw il " --> “jaw il”

**非正则实现：**

    function trim(str) {
        let start, end
        for (let i = 0; i < str.length; i++) {
            if (str[i] !== ' ') {
                start = i
                break
            }
        }
        for (let i = str.length - 1; i > 0; i--) {
            if (str[i] !== ' ') {
                end = i
                break
            }
        }

        return str.substring(start, end + 1)
    }

    let str = "  jaw il "
    console.log(trim(str)) // "jaw il"

**用正则实现：**

    function trim(str) {
        return str.replace(/(^\s*)|(\s*$)/g, "")
    }

    let str = "  jaw il "
    console.log(trim(str)) // "jaw il"

### 4、判断一个数是否是质数 3 --> true

> 质数又称[素数](<http://baike.baidu.com/item/%E7%B4%A0%E6%95%B0>)。指在一个大于1的自然数中，除了1和此整数自身外，没法被其他自然数整除的数。

**非正则实现：**

    function isPrime(num){
        // 不是数字或者数字小于2
        if(typeof num !== "number" || !Number.isInteger(num)){　　　　　　
        // Number.isInterget 判断是否为整数
            return false
        }

        //2是质数
        if(num == 2){
            return true
        }else if(num % 2 == 0){  //排除偶数
            return false
        }
        //依次判断是否能被奇数整除，最大循环为数值的开方
        let squareRoot = Math.sqrt(num)
        //因为2已经验证过，所以从3开始；且已经排除偶数，所以每次加2
        for(let i = 3; i <= squareRoot; i += 2) {
          if (num % i === 0) {
             return false
          }
        }
        return true
    }

    console.log(isPrime(19)) // true

**用正则实现：**

    function isPrime(num) {
    return !/^1?$|^(11+?)\1+$/.test(Array(num+1).join('1'))
    }

    console.log(isPrime(19)) // true

要使用这个正规则表达式，你需要把自然数转成多个1的字符串，如：2 要写成 “11”， 3 要写成 “111”, 17 要写成“11111111111111111”，这种工作使用一些脚本语言可以轻松的完成，JS实现也很简单，我用`Array(num+1).join('1')`这种方式实现了一下。

一开始我对这个表达式持怀疑态度，但仔细研究了一下这个表达式，发现是非常合理的，下面，让我带你来细细剖析一下是这个表达式的工作原理。

首先，我们看到这个表达式中有“|”，也就是说这个表达式可以分成两个部分：`/^1?$/` 和 `/^(11+?)\1+$/`

  * **第一部分：/^1?$/** ， 这个部分相信不用我多说了，其表示匹配“空串”以及字串中只有一个“1”的字符串。
  * **第二部分：/^(11+?)\1+$/** ，这个部分是整个表达式的关键部分。其可以分成两个部分，**(11+?)** 和 **\1+$** ，前半部很简单了，匹配以“11”开头的并重复0或n个1的字符串，后面的部分意思是把前半部分作为一个字串去匹配还剩下的字符串1次或多次（这句话的意思是——剩余的字串的1的个数要是前面字串1个数的整数倍）。

可见这个正规则表达式是取非素数，要得到素数还得要对整个表达式求反。通过上面的分析，我们知道，第二部分是最重要的，对于第二部分，举几个例子，

**示例一：判断自然数8** 。我们可以知道，8转成我们的格式就是“11111111”，对于 **(11+?)** ，其匹配了“11”，于是还剩下“111111”，而 **\1+$** 正好匹配了剩下的“111111”，因为，“11”这个模式在“111111”出现了三次，符合模式匹配，返回true。所以，匹配成功，于是这个数不是质数。

**示例二：判断自然数11** 。转成我们需要的格式是“11111111111”（11个1），对于 **(11+?)** ，其匹配了“11”（前两个1），还剩下“111111111”（九个1），而 **\1+$** 无法为“11”匹配那“九个1”，因为“11”这个模式并没有在“九个1”这个串中正好出现N次。于是，我们的正则表达式引擎会尝试下一种方法，先匹配“111”（前三个1），然后把“111”作为模式去匹配剩下的“11111111”（八个1），很明显，那“八个1”并没有匹配“三个1”多次。所以，引擎会继续向下尝试……直至尝试所有可能都无法匹配成功。所以11是素数。

通过示例二，我们可以得到这样的等价数算算法，正则表达式会匹配这若干个1中有没有出现“二个1”的整数倍，“三个1”的整数倍，“四个1”的整数倍……，而，这正好是我们需要的算素数的算法。现在大家明白了吧。

### 5、字符串数组去重 ["a","b","c","a","b","c"] --> ["a","b","c"]

这里只考虑最简单字符串的数组去重，暂不考虑，对象，函数，NaN等情况，这种用正则实现起来就吃力不讨好了。

**非正则实现：**

`①ES6实现`

    let str_arr=["a","b","c","a","b","c"]

    function unique(arr){
      return [...new Set(arr)]
    }

    console.log(unique(str_arr)) // ["a","b","c"]

`②ES5实现`

    var str_arr = ["a", "b", "c", "a", "b", "c"]

    function unique(arr) {
        return arr.filter(function(ele, index, array) {
            return array.indexOf(ele) === index
        })
    }

    console.log(unique(str_arr)) // ["a","b","c"]

`③ES3实现`

    var str_arr = ["a", "b", "c", "a", "b", "c"]

    function unique(arr) {
        var obj = {},
            array = []

        for (var i = 0, len = arr.length; i < len; i++) {
            var key = arr[i] + typeof arr[i]
            if (!obj[key]) {
                obj[key] = true
                array.push(arr[i])
            }
        }
        return array
    }

    console.log(unique(str_arr)) // ["a","b","c"]

额，ES4呢。。。对不起，由于历史原因，ES4改动太大，所以被废弃了。  
可以看到从ES3到ES6，代码越来越简洁，JavaScript也越来越强大。

**用正则实现：**

    var str_arr = ["a", "b", "c", "a", "b", "c"]

    function unique(arr) {
        return arr.sort().join(",,").
        replace(/(,|^)([^,]+)(,,\2)+(,|$)/g, "$1$2$4").
        replace(/,,+/g, ",").
        replace(/,$/, "").
        split(",")
    }

    console.log(unique(str_arr)) // ["a","b","c"]

**这里我只是抛砖引玉的利用几个例子对比来展现正则表达式的强大，其实正则表达式的应用远远不止这些，这里列出的只是冰山一角，更多的奇淫技巧需要你们来创造，知识点API是有限的，技巧和创造却是无限的，欢迎大家开动脑门，创造或分享自己的奇淫技巧。**

**如果还没有系统学习正则表达式，这里提供一些网上经典的教程供大家学习。**

正则表达式（Regular Expression），这是一块硬骨头，很难啃，但是啃着又很香。

正则表达式使用单个字符串来描述、匹配一系列匹配某个句法规则的字符串。很多地方我们都需要使用正则，所以今天就将一些优秀的教程，工具总结起来。

#### 基本内容

<https://en.wikipedia.org/wiki/Regular_expression> 了解一样东西，当然先从WIKI开始最好了。

    // Regular Expression examples
    I had a \S+ day today
    [A-Za-z0-9\-_]{3,16}
    \d\d\d\d-\d\d-\d\d
    v(\d+)(\.\d+)*
    TotalMessages="(.*?)"
    <[^<>]>

#### 教程

<http://deerchao.net/tutorials/regex/regex.htm> 30分钟入门教程，网上流传甚广  
<https://qntm.org/files/re/re.html> 55分钟教程【英文】，  
<http://regex.learncodethehardway.org/book/> 一本简单的书，每一节就是一块内容  
<https://swtch.com/~rsc/regexp/regexp1.html> 正则匹配原理解析  
<http://stackoverflow.com/tags/regex/info> stackoverflow 正则标签，标签下有值得点击的链接，一些典型的问题  
<http://regexr.com/> 正则学习测试于一身  
<https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Guide/Regular_Expressions> MDN出品，JavaScript方面内容

#### 验证与测试

<https://regex101.com/> in JavaScript, Python, PCRE 16-bit, generates explanation of pattern  
<https://www.debuggex.com/> 正则验证测试，清晰明了  
<https://mengzhuo.org/regex/> 中文版正则验证测试  
<http://refiddle.com/> 测试工具  
<http://myregexp.com/> 也是测试工具，都可以试一试

#### 闯关模式实践

[http://regex.alf.nu](<http://regex.alf.nu/>) 闯关模式练习正则表达式，完成一个个正则匹配的测验  
<http://regexone.com/> 通过实际练习掌握正则表达式  
<https://regexcrossword.com/> 正则挑战，有不同难度，很丰富  
<http://callumacrae.github.io/regex-tuesday/> 正则挑战，完成正则匹配要求

#### 其它

<https://msdn.microsoft.com/zh-cn/library/az24scfc.aspx> MSDN 微软出品  
<http://www.jb51.net/tools/regex.htm> 常用正则表达式，如匹配网址、日期啊这种，这个谷歌一搜很多的  
<https://www.cheatography.com/davechild/cheat-sheets/regular-expressions/> 速查表地址，如下图

[![](https://camo.githubusercontent.com/d450956e62798d70321968331a50e113ed86d062fe6a225c457ca37c134e5938/68747470733a2f2f7773342e73696e61696d672e636e2f6c617267652f303036744e63373967793166673164316c376d6e776a333071673065627766772e6a7067)](<https://camo.githubusercontent.com/d450956e62798d70321968331a50e113ed86d062fe6a225c457ca37c134e5938/68747470733a2f2f7773342e73696e61696d672e636e2f6c617267652f303036744e63373967793166673164316c376d6e776a333071673065627766772e6a7067>)
