# javascript 正则表达式

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.cnblogs.com/rubylouvre/archive/2010/03/09/1681222.html>
> 对应题目：正则表达式 第 0 题 · 正则表达式
> 抓取时间：2026-09-22

---

网上正则表达式的教程够多了，但由于javascript的历史比较悠久，也比较古老，因此有许多特性是不支持的。我们先从最简单地说起，文章所演示的正则基本都是perl方式。

## 元字符

( [ { \ ^ $ | ) ? * + .

## 预定义的特殊字符

字符| 正则| 描述  
---|---|---  
\t | /\t/ | 制表符  
\n | /\n/ | 换行符  
\r | /\r/ | 回车符  
\f | /\f/ | 换页符  
\a | /\a/ | alert字符  
\e | /\e/ | escape字符  
\cX | /\cX/ | 与X相对应的控制字符  
\b | /\b/ | 与回退字符  
\v | /\v/ | 垂直制表符  
\0 | /\0/ | 空字符  

## 字符类

简单类

原则上正则的一个字符对应一个字符，我们可以用[]把它们括起来，让[]这个整体对应一个字符。如

          alert(/ruby/.test("ruby"));//true
          alert(/[abc]/.test("a"));//true
          alert(/[abc]/.test("b"));//true
          alert(/[abc]/.test("c"));//true
          alert("a bat ,a Cat,a fAt bat ,a faT cat".match(/[bcf]at/gi));//bat,Cat,fAt,bat,faT,cat

负向类

也是在那个括号里做文章，前面加个元字符进行取反，表示匹配不能为括号里面的字符。

          alert(/[^abc]/.test("a"));//false
          alert(/[^abc]/.test("b"));//false
          alert(/[^abc]/.test("6"));//true
          alert(/[^abc]/.test("gg"));//true

范围类

还是在那个中括号里面做文章。有时匹配的东西过多，而且类型又相同，全部输入太麻烦，我们可以用它。特征就是在中间加了个横线。

组合类

还是在那个中括号里面做文章。允许用中括号匹配不同类型的单个字符。

          alert(/[a-f]/.test("b"));//true
          alert(/[a-f]/.test("k"));//false
          alert(/[a-z]/.test("h"));//true
          alert(/[A-Z]/.test("gg"));//false
          alert(/[^H-Y]/.test("G"));//true
          alert(/[0-9]/.test("8"));//true
          alert(/[^7-9]/.test("6"));//true

          alert(/[a-m1-5\n]/.test("a"))//true
          alert(/[a-m1-5\n]/.test("3"))//true
          var a = "\n\
                  "
          alert(/[a-m1-5\n]/.test(a))//true
          alert(/[a-m1-5\n]/.test("r"))//false

预定义类

还是在那个中括号里面做文章，不过它好像已经走到尽头了。由于是中括号的马甲，因此它们还是对应一个字符。

字符| 等同于| 描述  
---|---|---  
. | [^\n\r] | 除了换行和回车之外的任意字符  
\d | [0-9] | 数字字符  
\D | [^0-9] | 非数字字符  
\s | [ \t\n\x0B\f\r] | 空白字符  
\S | [^ \t\n\x0B\f\r] | 非空白字符  
\w | [a-zA-Z_0-9] | 单词字符(所有的字母)  
\W | [^a-zA-Z_0-9] | 非单词字符  

            alert(/\d/.test("3"))//true
            alert(/\d/.test("w"))//false
            alert(/\D/.test("w"))//true
            alert(/\w/.test("w"))//true
            alert(/\w/.test("司"))//false
            alert(/\W/.test("徒"))//true
            alert(/\s/.test(" "))//true
            alert(/\S/.test(" "))//false
            alert(/\S/.test("正"))//true
            alert(/./.test("美"))//true
            alert(/./.test("  "))//true
            var a = "\n\
                  "
            alert(/./.test(a))//true

## 量词

由于元字符与特殊字符或字符类或者它们的组合（中括号）甚至它们的马甲（预定义类）都是一对一进行匹配。我们要匹配“司徒正美这个词”，最简单都要/..../，如果长到50多个字符岂不是要死人。因此我们逼切需要一个简单的操作，来处理这数量关系。

简单量词

代码| 类型| 描述  
---|---|---  
? | 软性量词 | 出现零次或一次  
* | 软性量词 | 出现零次或多次(任意次)  
+ | 软性量词 | 出现一次或多次（至道一次）  
{n} | 硬性量词 | 对应零次或者n次  
{n,m} | 软性量词 | 至少出现n次但不超过m次  
{n,} | 软性量词 | 至少出现n次(+的升级版)  

            alert(/..../.test("司徒正美"))//true
            alert(/司徒正美/.test("司徒正美"))//true
            alert(/[\u4e00-\u9fa5]{4}/.test("司徒正美"))//true
            alert(/[\u4e00-\u9fa5]{4}/.test("司徒正美55"))//true
            alert(/^[\u4e00-\u9fa5]+$/.test("正则表达式"))//true
            alert(/^[\u4e00-\u9fa5]+$/.test("正则表达式&*@@"))//false
            alert(/\d{6}/.test("123456"))//true
            alert(/[ruby]{2}/.test("rr"))//true
            alert(/[ruby]{2}/.test("ru"))//true
            alert(/[ruby]{2}/.test("ry"))//true

/[\u4e00-\u9fa5]/用于匹配单个汉字。

贪婪量词，惰性量词与支配性量词

贪婪量词，上面提到的所有简单量词。就像成语中说的巴蛇吞象那样，一口吞下整个字符串，发现吞不下（匹配不了），再从后面一点点吐出来（去掉最后一个字符，再看这时这个整个字符串是否匹配，不断这样重复直到长度为零）

隋性量词，在简单量词后加问号。由于太懒了，先吃了前面第一个字符，如果不饱再捏起多添加一个（发现不匹配，就读下第二个，与最初的组成一个有两个字符串的字符串再尝试匹配，如果再不匹配，再吃一个组成拥有三个字符的字符串……）。其工作方式与贪婪量词相反。

支配性量词，在简单量词后加加号。上面两种都有个不断尝试的过程，而支配性量词却只尝试一次，不合口味就算了。就像一个出身高贵居支配地位的公主。但你也可以说它是最懒量词。由于javascript不支持，所以它连出场的机会也没有了。

            var re1 = /.*bbb/g;//贪婪
            var re2 = /.*?bbb/g;//惰性
            //  var re3 = /.*+bbb/g;//支配性,javascript不支持，IE与所有最新的标准浏览器都报错
            alert(re1.test("abbbaabbbaaabbbb1234")+"");//true
            alert(re1.exec("abbbaabbbaaabbbb1234")+"");//null
            alert("abbbaabbbaaabbbb1234".match(re1)+"");//abbbaabbbaaabbbb

            alert(re2.test("abbbaabbbaaabbbb1234")+"");//true
            alert(re2.exec("abbbaabbbaaabbbb1234")+"");//aabbb
            alert("abbbaabbbaaabbbb1234".match(re2)+"");//abbb,aabbb,aaabbb

## 分组

到目前为止，我们只能一个字符到匹配，虽然量词的出现，能帮助我们处理一排密紧密相连的同类型字符。但这是不够的，下面该轮到小括号出场了，中括号表示范围内选择，大括号表示重复次数。小括号允许我们重复多个字符。

            //分组+量词
            alert(/(dog){2}/.test("dogdog"))//true
            //分组+范围
            alert("baddad".match(/([bd]ad?)*/))//baddad,dad
            //分组+分组
            alert("mon and dad".match(/(mon( and dad)?)/))//mon and dad,mon and dad, and dad

## 反向引用

反向引用标识由正则表达式中的匹配组捕获的子字符串。每个反向引用都由一个编号或名称来标识，并通过“\编号”表示法进行引用。

            var color = "#990000";
            /#(\d+)/.test(color);
            alert(RegExp.$1);//990000

            alert(/(dog)\1/.test("dogdog"))//true

            var num = "1234 5678";
            var newNum = num.replace(/(\d{4}) (\d{4})/,"$2 $1");
            alert(newNum)

## 候选

继续在分组上做文章。在分组中插入管道符（“|”），把它划分为两个或多个候多项。

            var reg = /(red|black|yellow)!!/;
            alert(reg.test("red!!"))//true
            alert(reg.test("black!!"))//true
            alert(reg.test("yellow!!"))//true

## 非捕获性分组

并不是所有分组都能创建反向引用，有一种特别的分组称之为非捕获性分组，它是不会创建反向引用。反之，就是捕获性分组。要创建一个非捕获性分组，只要在分组的左括号的后面紧跟一个问号与冒号就行了。

            var color = "#990000";
            /#(?:\d+)/.test(color);
            alert(RegExp.$1);//""

题目，移除所有标签，只留下innerText!

            var html = "<p><a href='http://www.cnblogs.com/rubylouvre/'>Ruby Louvre</a>by <em>司徒正美</em></p>";
            var text = html.replace(/<(?:.|\s)*?>/g, "");
            alert(text)

注意：javascript不存在命名分组

### 前瞻

继续在分组内做文章。前瞻与后瞻其实都属于零宽断言，但javascript不支持后瞻。

零宽断言  
---  
正则| 名称| 描述  
(?=exp) | 正向前瞻 | 匹配exp前面的位置  
(?!exp) | 负向前瞻 | 匹配后面不是exp的位置  
(?<=exp) | 正向后瞻 | 匹配exp后面的位置不支持  
(?<!exp) | 负向后瞻 | 匹配前面不是exp的位置不支持  

正向前瞻用来检查接下来的出现的是不是某个特定的字符集。而负向前瞻则是检查接下来的不应该出现的特定字符串集。零宽断言是不会被捕获的。

            var str1 = "bedroom";
            var str2 = "bedding";
            var reBed = /(bed(?=room))///在我们捕获bed这个字符串时，抢先去看接下来的字符串是不是room
            alert(reBed.test(str1));//true
            alert(RegExp.$1)//bed
            alert(RegExp.$2 === "")//true
            alert(reBed.test(str2))//false

            var str1 = "bedroom";
            var str2 = "bedding";
            var reBed = /(bed(?!room))/  //要来它后面不能是room
            alert(reBed.test(str1))//false
            alert(reBed.test(str2))//true

题目，移除hr以外的所有标签，只留下innerText!

            var html = "<p><a href='http://www.cnblogs.com/rubylouvre/'>Ruby Louvre</a></p><hr/><p>by <em>司徒正美</em></p>";
            var text = html.replace(/<(?!hr)(?:.|\s)*?>/ig,"")
            alert(text)//Ruby Louvre<hr/>by 司徒正美

### 边界

一个要与字符类合用的东西。

边界  
---  
正则| 名称| 描述  
^ | 开头 | 注意不能紧跟于左中括号的后面  
$ | 结尾 |   
\b | 单词边界 | 指[a-zA-Z_0-9]之外的字符  
\B | 非单词边界 |   

题目，设计一个字符串原型方法，实现首字母大写！

            var a = "ruby";
            String.prototype.capitalize =  function () {
                return this.replace(/^\w/, function (s) {
                    return s.toUpperCase();
                });
            }
           alert(a.capitalize())//Ruby

单词边界举例。要匹配的东西的前端或未端不能为英文字母阿拉伯字数字或下横线。

            var str = "12w-eefd&efrew";
            alert(str.match(/\b\w+\b/g))//12w,eefd,efrew

实例属性| 描述  
---|---  
global | 是当前表达式模式首次匹配内容的开始位置，从0开始计数。其初始值为-1，每次成功匹配时，index属性都会随之改变。  
ignoreCase | 返回创建RegExp对象实例时指定的ignoreCase标志（i）的状态。如果创建RegExp对象实例时设置了i标志，该属性返回True，否则返回False，默认值为False。  
lastIndex | 是当前表达式模式首次匹配内容中最后一个字符的下一个位置，从0开始计数，常被作为继续搜索时的起始位置，初始值为-1， 表示从起始位置开始搜索，每次成功匹配时，lastIndex属性值都会随之改变。(只有使用exec()或test()方法才会填入，否则为0)  
multiLine | 返回创建RegExp对象实例时指定的multiLine标志（m）的状态。如果创建RegExp对象实例时设置了m标志，该属性返回True，否则返回False，默认值为False。  
source | 返回创建RegExp对象实例时指定的表达式文本字符串。  

            var str = "JS's Louvre";
            var reg = /\w/g;
            alert(reg.exec(str));//J
            alert(reg.lastIndex);//1
            alert(reg.exec(str));//S
            alert(reg.lastIndex);//2
            alert(reg.exec(str));//s
            alert(reg.lastIndex);//4
            alert(reg.exec(str));//L
            alert(reg.lastIndex);//6
