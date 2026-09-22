# 4 种 JavaScript 内存泄漏浅析及如何用谷歌工具查内存泄露

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/wengjq/Blog/issues/1>
> 对应题目：JS 深入 第 16 题 · 内存泄漏
> 抓取时间：2026-09-22

---

> 参考原文：<https://auth0.com/blog/four-types-of-leaks-in-your-javascript-code-and-how-to-get-rid-of-them/>

> 在本文中，我们将探讨客户端JavaScript代码中常见的内存泄漏类型。 我们还将学习如何使用Chrome开发工具找到它们。

## 1、介绍

内存泄漏是每个开发人员都要面临的问题。 即使使用内存管理的语言，也存在内存泄漏的情况。 内存泄漏是导致迟缓，崩溃，高延迟的根本原因，甚至会导致其他应用问题。

## 2、什么是内存泄露

实质上，内存泄漏可以定义为应用程序不再需要的内存，因为某种原因其不会返回到操作系统或可用内存池。编程语言有不同的管理内存的方式。这些方法可以减少泄漏内存的机会。然而，某一块内存是否未被使用实际上是一个不可判定的问题。 换句话说，只有开发人员才能明确是否可以将一块内存返回到操作系统。 某些编程语言提供了帮助开发人员执行此操作的功能。

## 3、JavaScript的内存管理

JavaScript是垃圾回收语言之一。 垃圾回收语言通过定期检查哪些先前分配的内存是否“可达”来帮助开发人员管理内存。 换句话说，垃圾回收语言将管理内存的问题从“什么内存仍可用？ 到“什么内存仍可达？”。区别是微妙的，但重要的是：虽然只有开发人员知道将来是否需要一块分配的内存，但是不可达的内存可以通过算法确定并标记为返回到操作系统。

> 非垃圾回收的语言通常使用其他技术来管理内存：显式管理，开发人员明确告诉编译器何时不需要一块内存; 和引用计数，其中使用计数与存储器的每个块相关联（当计数达到零时，其被返回到OS）。

## 4、JavaScript的内存泄露

垃圾回收语言泄漏的主要原因是不需要的引用。要理解什么不需要的引用，首先我们需要了解垃圾回收器如何确定一块内存是否“可达”。

> 垃圾回收语言泄漏的主要原因是不需要的引用。

**Mark-and-sweep**  
大多数垃圾回收器使用称为标记和扫描的算法。该算法由以下步骤组成：

  * 1、垃圾回收器构建一个“根”列表。根通常是在代码中保存引用的全局变量。在JavaScript中，“window”对象是可以充当根的全局变量的示例。窗口对象总是存在的，所以垃圾回收器可以考虑它和它的所有的孩子总是存在（即不是垃圾）。
  * 2、所有根被检查并标记为活动（即不是垃圾）。所有孩子也被递归检查。从根可以到达的一切都不被认为是垃圾。
  * 3、所有未标记为活动的内存块现在可以被认为是垃圾。回收器现在可以释放该内存并将其返回到操作系统。

> 现代垃圾回收器以不同的方式改进了该算法，但本质是相同的：可访问的内存段被标记，其余被垃圾回收。不需要的引用是开发者知道它不再需要，但由于某种原因，保存在活动根的树内部的内存段的引用。 在JavaScript的上下文中，不需要的引用是保存在代码中某处的变量，它不再被使用，并指向可以被释放的一块内存。 有些人会认为这些都是开发者的错误。所以要了解哪些是JavaScript中最常见的漏洞，我们需要知道在哪些方式引用通常被忽略。

## 5、四种常见的JavaScript 内存泄漏

### 5.1、意外的全局变量

JavaScript背后的目标之一是开发一种看起来像Java的语言，容易被初学者使用。 JavaScript允许的方式之一是处理未声明的变量：对未声明的变量的引用在全局对象内创建一个新的变量。 在浏览器的情况下，全局对象是窗口。 换一种说法：

      function foo(arg) {
        bar = "this is a hidden global variable";
      }

事实上：

      function foo(arg) {
        window.bar = "this is an explicit global variable";
      }

如果bar应该只在foo函数的范围内保存对变量的引用，并且您忘记使用var来声明它，那么会创建一个意外的全局变量。 在这个例子中，泄漏一个简单的字符串可能没什么，但有更糟糕的情况。

> 创建偶然的全局变量的另一种方式是通过下面这样：

      function foo() {
        this.variable = "potential accidental global";
      }
      // Foo called on its own, this points to the global object (window)
      // rather than being undefined.
      foo();

为了防止这些错误发生，添加'use strict'; 在您的JavaScript文件的开头。 这使得能够更严格地解析JavaScript以防止意外的全局变量。

> 即使我们讨论了不可预测的全局变量，但是仍有一些明确的全局变量产生的垃圾。这些是根据定义不可回收的（除非被取消或重新分配）。特别地，用于临时存储和处理大量信息的全局变量是令人关注的。 如果必须使用全局变量来存储大量数据，请确保将其置空或在完成后重新分配它。与全局变量有关的增加的内存消耗的一个常见原因是高速缓存）。缓存存储重复使用的数据。 为了有效率，高速缓存必须具有其大小的上限。 无限增长的缓存可能会导致高内存消耗，因为缓存内容无法被回收。

### 5.2、被遗忘的计时器或回调函数

setInterval的使用在JavaScript中是很常见的。大多数这些库在它们自己的实例变得不可达之后，使得对回调的任何引用不可达。在setInterval的情况下，但是，像这样的代码是很常见的：

      var someResource = getData();
      setInterval(function() {
        var node = document.getElementById('Node');
        if(node) {
          // Do stuff with node and someResource.
          node.innerHTML = JSON.stringify(someResource));
        }
      }, 1000);

此示例说明了挂起计时器可能发生的情况：引用不再需要的节点或数据的计时器。 由节点表示的对象可以在将来被移除，使得区间处理器内部的整个块不需要了。 但是，处理程序（因为时间间隔仍处于活动状态）无法回收（需要停止时间间隔才能发生）。 如果无法回收间隔处理程序，则也无法回收其依赖项。 这意味着someResource，它可能存储大小的数据，也不能被回收。

> 对于观察者的情况，重要的是进行显式调用，以便在不再需要它们时删除它们（或者相关对象即将无法访问）。 在过去，以前特别重要，因为某些浏览器（Internet Explorer 6）不能管理循环引用（参见下面的更多信息）。 现在，一旦观察到的对象变得不可达，即使没有明确删除监听器，大多数浏览器也可以回收观察者处理程序。 然而，在对象被处理之前显式地删除这些观察者仍然是良好的做法。 例如：

      var element = document.getElementById('button');
      function onClick(event) {
        element.innerHtml = 'text';
      }
      element.addEventListener('click', onClick);
      // Do stuff
      element.removeEventListener('click', onClick);
      element.parentNode.removeChild(element);
      // Now when element goes out of scope,
      // both element and onClick will be collected even in old browsers that don't
      // handle cycles well.

关于对象观察者和循环引用：

> 观察者和循环引用曾经是JavaScript开发者的祸根。 这是由于Internet Explorer的垃圾回收器中的错误（或设计决策）。旧版本的Internet Explorer无法检测DOM节点和JavaScript代码之间的循环引用。这是一个典型的观察者，通常保持对可观察者的引用（如上例所示）。换句话说，每当观察者被添加到Internet Explorer中的一个节点时，它就会导致泄漏。这是开发人员在节点或在观察者中引用之前明确删除处理程序的原因。 现在，现代浏览器（包括Internet Explorer和Microsoft Edge）使用现代垃圾回收算法，可以检测这些周期并正确处理它们。 换句话说，在使节点不可达之前，不必严格地调用removeEventListener。框架和库（jQuery）在处理节点之前删除侦听器（当为其使用特定的API时）。这是由库内部处理，并确保不产生泄漏，即使运行在有问题的浏览器，如旧的Internet Explorer。

### 5.3、脱离 DOM 的引用

有时，将DOM节点存储在数据结构中可能很有用。 假设要快速更新表中多行的内容。 在字典或数组中存储对每个DOM行的引用可能是有意义的。 当发生这种情况时，会保留对同一个DOM元素的两个引用：一个在DOM树中，另一个在字典中。 如果在将来的某个时候，您决定删除这些行，则需要使这两个引用不可访问。

      var elements = {
        button: document.getElementById('button'),
        image: document.getElementById('image'),
        text: document.getElementById('text')
      };
      function doStuff() {
        image.src = 'http://some.url/image';
        button.click();
        console.log(text.innerHTML);
        // Much more logic
      }
      function removeButton() {
        // The button is a direct child of body.
        document.body.removeChild(document.getElementById('button'));
        // At this point, we still have a reference to #button in the global
        // elements dictionary. In other words, the button element is still in
        // memory and cannot be collected by the GC.
      }

> 对此的另外考虑与对DOM树内的内部或叶节点的引用有关。 假设您在JavaScript代码中保留对表的特定单元格（标记）的引用。 在将来的某个时候，您决定从DOM中删除表，但保留对该单元格的引用。 直观地，可以假设GC将回收除了该单元之外的所有东西。 在实践中，这不会发生：单元格是该表的子节点，并且子级保持对其父级的引用。 换句话说，从JavaScript代码对表单元格的引用导致整个表保留在内存中。 在保持对DOM元素的引用时仔细考虑这一点。

### 5.4、闭包

JavaScript开发的一个关键方面是闭包：从父作用域捕获变量的匿名函数。 Meteor开发人员发现了一个特定的情况，由于JavaScript运行时的实现细节，可能以一种微妙的方式泄漏内存：

      var theThing = null;
      var replaceThing = function () {
        var originalThing = theThing;
        var unused = function () {
          if (originalThing)
            console.log("hi");
          };
          theThing = {
            longStr: new Array(1000000).join('*'),
            someMethod: function () {
              console.log(someMessage);
            }
          };
        };
      setInterval(replaceThing, 1000);

> 这个片段做了一件事：每次replaceThing被调用，theThing获取一个新的对象，其中包含一个大数组和一个新的闭包（someMethod）。同时，unused变量保持一个闭包，该闭包具有对originalThing的引用（来自之前对replaceThing的调用的Thing）。已经有点混乱了，是吗？重要的是，一旦为同一父作用域中的闭包创建了作用域，则该作用域是共享的。在这种情况下，为闭包someMethod创建的作用域由unused共享。unused的引用了originalThing。即使unused未使用，可以通过theThing使用someMethod。由于someMethod与unused共享闭包范围，即使未使用，它对originalThing的引用强制它保持活动（防止其收集）。当此代码段重复运行时，可以观察到内存使用量的稳定增加。这在GC运行时不会变小。实质上，创建一个闭包的链接列表（其根以theThing变量的形式），并且这些闭包的范围中的每一个都包含对大数组的间接引用，导致相当大的泄漏。

**Meteor的博文解释了如何修复此种问题。在replaceThing的最后添加originalThing = null。**

垃圾回收器的不直观行为：

> 虽然垃圾回收器很方便，但他们有自己的一套权衡。 这些权衡之一是非确定性。 换句话说，GC是不可预测的。 通常不可能确定何时执行回收。 这意味着在某些情况下，正在使用比程序实际需要的更多的内存。 在其他情况下，短暂停顿在特别敏感的应用中可能是明显的。 虽然非确定性意味着无法确定何时执行集合，但大多数GC实现都分享在分配期间执行集合传递的常见模式。 如果没有执行分配，则大多数GC保持静止。 考虑以下情况：

  * 1、执行相当大的一组分配。
  * 2、大多数这些元素（或所有这些元素）被标记为不可达（假设我们使指向我们不再需要的缓存的引用为空）。
  * 3、不执行进一步的分配。

> 在这种情况下，大多数GC不会运行任何进一步的集合过程。 换句话说，即使有不可达的引用可用于回收，回收器也不会回收这些引用。 这些不是严格的泄漏，但仍然导致高于通常的内存使用。

Google在他们的JavaScript内存分析文档中提供了这种行为的一个很好的例子，next!!!。

## 6、Chrome内存分析工具概述

Chrome提供了一组很好的工具来分析JavaScript代码的内存使用情况。 有两个与内存相关的基本视图：时间轴视图和配置文件视图。

### 6.1、TimeLine

[![Paste_Image.png](https://camo.githubusercontent.com/0f2c5cadd2f3856be9f40aac56bea2c15daf2a628d3d8a0929fecae52f5bd02b/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f333738393339392d373233373566653032633132386664622e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430)](<https://camo.githubusercontent.com/0f2c5cadd2f3856be9f40aac56bea2c15daf2a628d3d8a0929fecae52f5bd02b/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f333738393339392d373233373566653032633132386664622e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430>)  
TimeLine对于在代码中发现异常内存模式至关重要。 如果我们正在寻找大的泄漏，周期性的跳跃，收缩后不会收缩，就像一个红旗。 在这个截图中，我们可以看到泄漏对象的稳定增长可能是什么样子。 即使在大收集结束后，使用的内存总量高于开始时。 节点计数也较高。 这些都是代码中某处泄露的DOM节点的迹象。

### 6.2、Profiles

[![Paste_Image.png](https://camo.githubusercontent.com/413eb2801cddaee18d5b8af20ff7e32982bdeded0f41955445aa37b06a0e4cac/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f333738393339392d333065353631633338306232323533352e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430)](<https://camo.githubusercontent.com/413eb2801cddaee18d5b8af20ff7e32982bdeded0f41955445aa37b06a0e4cac/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f333738393339392d333065353631633338306232323533352e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430>)  
这是你将花费大部分时间看的视图。 Profiles允许您获取快照并比较JavaScript代码的内存使用快照。 它还允许您记录分配的时间。 在每个结果视图中，不同类型的列表都可用，但是对于我们的任务最相关的是summary（概要）列表和comparison（对照）列表。

summary（概要）列表为我们概述了分配的不同类型的对象及其聚合大小：浅大小（特定类型的所有对象的总和）和保留大小（浅大小加上由于此对象保留的其他对象的大小 ）。 它还给了我们一个对象相对于它的GC根（距离）有多远的概念。

comparison（对照）给了我们相同的信息，但允许我们比较不同的快照。 这对于查找泄漏是非常有用的。

## 7、示例：使用Chrome查找泄漏

> 基本上有两种类型的泄漏：1、泄漏引起内存使用的周期性增加。2、一次发生的泄漏，并且不会进一步增加内存。

由于明显的原因，当它们是周期性的时更容易发现泄漏。这些也是最麻烦的：如果内存在时间上增加，这种类型的泄漏将最终导致浏览器变慢或停止脚本的执行。不是周期性的泄漏可以很容易地发现。这通常会被忽视。在某种程度上，发生一次的小泄漏可以被认为是优化问题。然而，周期性的泄漏是错误并且必须解决的。

> 对于我们的示例，我们将使用Chrome的文档中的一个示例。 完整代码粘贴如下：

    var x = [];
    function createSomeNodes() {
      var div,
      i = 100,
      frag = document.createDocumentFragment();
      for (;i > 0; i--) {
        div = document.createElement("div");
        div.appendChild(document.createTextNode(i + " - "+ new Date().toTimeString()));
        frag.appendChild(div);
      }
      document.getElementById("nodes").appendChild(frag);
    }
    function grow() {
      x.push(new Array(1000000).join('x'));
      createSomeNodes();
      setTimeout(grow,1000);
    }

当调用grow时，它将开始创建div节点并将它们附加到DOM。它还将分配一个大数组，并将其附加到全局变量引用的数组。这将导致使用上述工具可以找到的内存的稳定增加。

### 7.1、了解内存是否周期性增加

Timeline非常有用。 在Chrome中打开示例，打开开发工具，转到Timeline，选择Memory，然后点击录制按钮。 然后转到页面并单击按钮开始泄漏内存。 一段时间后停止录制，看看结果：

[![Paste_Image.png](https://camo.githubusercontent.com/176c9f98e8fe0ad225d91cfb4c34c9f5fcd1fafb35c765ff995e8ac1206dbefc/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f333738393339392d383064363365343034396636636432632e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430)](<https://camo.githubusercontent.com/176c9f98e8fe0ad225d91cfb4c34c9f5fcd1fafb35c765ff995e8ac1206dbefc/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f333738393339392d383064363365343034396636636432632e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430>)

此示例将继续每秒泄漏内存。停止录制后，在grow函数中设置断点，以停止脚本强制Chrome关闭页面。在这个图像有两个大的迹象，表明我们正在记录泄漏。节点（绿线）和JS堆（蓝线）的图。节点正在稳步增加，从不减少。这是一个大的警告标志。

> JS堆也显示内存使用的稳定增长。这是很难看到由于垃圾回收器的影响。您可以看到初始内存增长的模式，随后是大幅下降，随后是增加，然后是尖峰，继续记忆的另一下降。 在这种情况下的关键在于事实，在每次内存使用后，堆的大小保持大于上一次下降。 换句话说，虽然垃圾收集器正在成功地收集大量的存储器，但是它还是周期性地泄漏了。

### 7.2、现在确定有泄漏。 让我们找到它。

> 要使用此功能，请转到Dev Tools - >设置并启用“记录堆分配堆栈跟踪”。 在拍摄之前必须这样做。

## 8、请深入阅读

## 9、总结

内存泄漏可以并且确实发生在垃圾回收语言，如JavaScript。这些可以被忽视一段时间，最终他们将肆虐你的网站。因此，内存分析工具对于查找内存泄漏至关重要。分析运行应该是开发周期的一部分，特别是对于中型或大型应用程序。开始这样做，为您的用户提供最好的体验。
