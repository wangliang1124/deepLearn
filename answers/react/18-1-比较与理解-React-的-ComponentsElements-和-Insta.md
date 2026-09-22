# 比较与理解 React 的 Components，Elements 和 Instances

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/creeperyang/blog/issues/30>
> 对应题目：React 第 18 题 · 在 React 当中 Element 和 Component 有何区别？createElement 和 cloneElement 有什么区别？
> 抓取时间：2026-09-22

---

React是目前（2017.04）流行的创建组件化UI的框架，自身有一套完整和强大的生态系统；同时它也是我目前工作中的主力框架，所以学习和理解React是很自然的需求。

本文在**翻译**[React Components, Elements, and Instances](<https://facebook.github.io/react/blog/2015/12/18/react-components-elements-and-instances.html>)的基础上，主要专注理解React的一个核心理念：用Elements Tree描述UI。本文也应该是接下来几片React相关文章的开头，所以更合适的标题可能是：

## React学习笔记一：Components，Elements和Instances

_请注意，阅读本文最好对React有基本的了解，但React新手也应该可以畅通阅读。_

### 从JSX出发

现在我们写React应用，相当部分都是在写JSX。

JSX本身是对JavaScript语法的一个扩展，看起来像是某种模板语言，但其实不是。但正因为形似HTML，描述UI就更直观了，也极大地方便了开发；你想如果我们没有HTML，必须手写一堆的`document.createElement()`，我想前端们肯定已经崩溃了。

不过如果你一直写JSX，并且从来没脱离过JSX，可能某种程度上会阻碍我们理解React。当我们有一个JSX片段，它实际上是调用React API构建了一个Elements Tree：

    var profile = <div>
      <img src="avatar.png" className="profile" />
      <h3>{[user.firstName, user.lastName].join(' ')}</h3>
    </div>;

借助[babel-plugin-transform-react-jsx](<https://github.com/babel/babel/tree/7.0/packages/babel-plugin-transform-react-jsx>)，上面的JSX将被转译成：

    var profile = React.createElement("div", null,
      React.createElement("img", { src: "avatar.png", className: "profile" }),
      React.createElement("h3", null, [user.firstName, user.lastName].join(" "))
    );

那么，`React.createElement`是在做什么？看下相关部分代码：

    var ReactElement = function(type, key, ref, self, source, owner, props) {
      var element = {
        // This tag allow us to uniquely identify this as a React Element
        $$typeof: REACT_ELEMENT_TYPE,

        // Built-in properties that belong on the element
        type: type,
        key: key,
        ref: ref,
        props: props,

        // Record the component responsible for creating this element.
        _owner: owner,
      };
      // ...
      return element;
    };

    ReactElement.createElement = function(type, config, children) {
      // ...
      return ReactElement(
        type,
        key,
        ref,
        self,
        source,
        ReactCurrentOwner.current,
        props
      );
    };

看起来，`ReactElement.createElement`最终返回了一个对象，这个对象大概是这样的形状：

    {
      type,
      key,
      props: {
        children
      }
    }

非常明显，这就是一个Elements Tree！很好，我们知道了react的render方法是返回一个Elements Tree，react的核心就是围绕Elements Tree做文章。

下面我们就主要讲讲Components，Elements(Tree)和Instances，以及三者之间的关系。

### 传统面向对象UI编程的痛点：管理实例

如果你是React的新手，那么之前你可能只接触过组件的类和实例（component classes and instances ）。比如，你可能会  
创建一个类来声明`Button`组件，当app运行时，屏幕上可能会有多个`Button`的实例，每个都有自己的属性和私有状态。这就是传统面向对象的UI编程， _那么为什么要引入Elements的概念？_

传统UI模型中，你必须自己负责创建和销毁子组件的实例（child component instances）：

每个组件实例必须保存自己的DOM nodes和子组件实例的引用，并在对的时间创建，更新，销毁它们。代码的行数将会以可能的状态的数量的 **平方** 增长，而且组件可以直接访问子组件实例将会使解耦变得困难。

那么，React有什么不同呢？

### React用Elements Tree描述UI

> An element is a plain object describing a component instance or DOM node and its desired properties.

一个元素（element）就是一个纯对象，描述了一个组件实例或DOM node，以及它需要的属性。它仅仅包含这些信息：组件类型，属性（properties），及子元素。

元素不是实例，实际上，它更像是告诉React你需要在屏幕上显示什么的一种方式。它就是一个有2个数据域（field）的不可变描述对象（immutable description object）：

    {
      type: (string | ReactClass),
      props: Object
    }

#### DOM Elements

当元素的type是string时，那么这个元素就表示一个DOM node（type的值就是tagName，props就是attributes）。 这node就是React将渲染的。比如：

    {
      type: 'button',
      props: {
        className: 'button button-blue',
        children: {
          type: 'b',
          props: {
            children: 'OK!'
          }
        }
      }
    }

将被渲染成：

    <button class='button button-blue'>
      <b>
        OK!
      </b>
    </button>

注意下元素是怎么嵌套的。当我们想创建元素树时，我们设置children属性。

**注意：子元素和父元素都只是描述，并不是实际的实例。当你创建它们的时候，它们并不指向屏幕上的任何东西。 显然，它们比DOM轻量多了，它们只是对象。**

#### Component Elements

此外，元素的type也可以是`function`或者`class`（即对应的React Component）：

    {
      type: Button,
      props: {
        color: 'blue',
        children: 'OK!'
      }
    }

> An element describing a component is also an element, just like an element describing the DOM node. They can be nested and mixed with each other.

**这是React的核心idea：一个描述组件的元素同样是元素，和描述DOM node的元素没什么区别。它们可以互相嵌套和混合。**

你可以混合搭配DOM和Component Elements：

    const DeleteAccount = () => ({
      type: 'div',
      props: {
        children: [{
          type: 'p',
          props: {
            children: 'Are you sure?'
          }
        }, {
          type: DangerButton,
          props: {
            children: 'Yep'
          }
        }, {
          type: Button,
          props: {
            color: 'blue',
            children: 'Cancel'
          }
       }]
     }
    });

或者，如果你更喜欢JSX：

    const DeleteAccount = () => (
      <div>
        <p>Are you sure?</p>
        <DangerButton>Yep</DangerButton>
        <Button color='blue'>Cancel</Button>
      </div>
    );

这种混合搭配帮助组件可以彼此解耦，因为它们可以仅仅通过组合（composition）就能表达`is-a`和`has-a`的关系：

  * `Button`是有特定属性（specific properties）的DOM`<button>`。
  * `DangerButton`是有特定属性的`Button`。
  * `DeleteAccount`在`<div>`里包含了`Button`和`DangerButton`。

#### Components Encapsulate Element Trees

当React碰到`type`是`function|class`时，它就知道这是个组件了，它会问这个组件："给你适当的props，你返回什么元素（树）？"。

比如当它看到：

    {
      type: Button,
      props: {
        color: 'blue',
        children: 'OK!'
      }
    }

React会问`Button`要渲染什么，`Button`返回：

    {
      type: 'button',
      props: {
        className: 'button button-blue',
        children: {
          type: 'b',
          props: {
            children: 'OK!'
          }
        }
      }
    }

React会重复这种过程，直到它知道页面上所有的组件想渲染出什么DOM nodes。

对React组件来说，props是输入，元素树（Elements tree）是输出。

我们选择让React来 _创建，更新，销毁_ 实例，我们用元素来描述它们，而React负责管理这些实例。

#### Components Can Be Classes or Functions

声明组件的3种方式：

  1. `class`，推荐。
  2. `React.createClass`，不推荐。
  3. `function`，类似只有`render`的`class`。

#### Top-Down Reconciliation

    ReactDOM.render({
      type: Form,
      props: {
        isSubmitted: false,
        buttonText: 'OK!'
      }
    }, document.getElementById('root'));

    const Form = ({ isSubmitted, buttonText }) => {
      if (isSubmitted) {
        // Form submitted! Return a message element.
        return {
          type: Message,
          props: {
            text: 'Success!'
          }
        };
      }

      // Form is still visible! Return a button element.
      return {
        type: Button,
        props: {
          children: buttonText,
          color: 'blue'
        }
      };
    };

当你调用`ReactDOM.render`时，React会问`Form`组件，给定这些props，它要返回什么元素。React会以更简单的基础值逐渐提炼（"refine"）它对`Form`组件的理解，这个过程如下所示：

    // React: You told me this...
    {
      type: Form,
      props: {
        isSubmitted: false,
        buttonText: 'OK!'
      }
    }

    // React: ...And Form told me this...
    {
      type: Button,
      props: {
        children: 'OK!',
        color: 'blue'
      }
    }

    // React: ...and Button told me this! I guess I'm done.
    {
      type: 'button',
      props: {
        className: 'button button-blue',
        children: {
          type: 'b',
          props: {
            children: 'OK!'
          }
        }
      }
    }

上面是被React叫做 **reconciliation** 的过程的一部分。每当你调用`ReactDOM.render()`或`setState()`时，都会开始reconciliation过程。在reconciliation结束时，React知道了结果的DOM树，一个如`react-dom`或 `react-native`的renderer会应用必须的最小变化来更新DOM nodes（或平台特定的视图，如React Native）。

这种渐进式的提炼（refining）过程也是React应用可以容易优化的原因。如果组件树的某部分大太了，你可以让React跳过这部分的refining，如果相关props没有变化。如果props是 immutable 的话，非常容易比较它们是否变化， 所以React可以和 immutability搭配一起并提高效率。

你可能注意到这篇文章讲了很多关于组件和元素，却没讲实例。这是因为相比传统面向对象的UI框架，在React中实例没那么重要。

仅仅以类声明的组件才有实例，并且你从来不会直接创建它——React为你创建它。尽管有父组件实例访问子组件实例的机制，但这只是在必要的情况下才使用，通常应该避免。

### 总结

元素（Element）是React的一个核心概念。一般情况下，我们用`React.createElement|JSX`来创建元素，但不要以对象来手写元素，只要知道元素本质上是对象即可。

本文围绕 _Components，Elements和Instances_ 来讲解了元素，而下一篇文章将借助[snabbdom](<https://github.com/snabbdom/snabbdom>)来讲 **virtual-dom** ：怎么从元素生成对应的dom，怎么diff元素来最小更新dom。
