# React 构造函数中为什么要写 super(props)

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://blog.csdn.net/huangpb123/article/details/85009024>
> 对应题目：React 第 17 题 · (在构造函数中)调用 super(props) 的目的是什么
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

#### 为什么 super() 要放在构造函数 contructor 最上面执行 ？

ES6 语法中，super 指代父类的构造函数，React 里面就是指代 React.Component 的构造函数。

在你调用 super() 之前，你无法在构造函数中使用 this，JS 不允许这么做。为什么要不允许呢？

看一下下面这个例子：

    class Person {
      constructor(name) {
        this.name = name;
      }
    }

    class PolitePerson extends Person {
      constructor(name) {
        this.greetColleagues(); //这是不允许的
        super(name);
      }

      greetColleagues() {
        alert('Good morning folks!');
        alert('My name is ' + this.name + ', nice to meet you!');
      }
    }

如果允许的话，在 super() 之前执行了一个 greetColleagues 函数，greetColleagues 函数里用到了 this.name，这时还没执行 super(name)，greetColleagues 函数里就获取不到 super 传入的 name 了，此时的 this.name 是 undefined。

#### super() 里为什么要传 props？

执行 super(props) 可以使基类 React.Component 初始化 this.props。

    // React 内部
    class Component {
      constructor(props) {
        this.props = props;
        // ...
      }
    }

有时候我们不传 props，只执行 super()，或者没有设置 constructor 的情况下，依然可以在组件内使用 this.props，为什么呢？

其实 React 在组件实例化的时候，马上又给实例设置了一遍 props：

    // React 内部
    const instance = new YourComponent(props);
    instance.props = props;

**那是否意味着我们可以只写 super() 而不用 super(props) 呢？**

不是的。虽然 React 会在组件实例化的时候设置一遍 props，但在 super 调用一直到构造函数结束之前，this.props 依然是未定义的。

    class Button extends React.Component {
      constructor(props) {
        super(); // ? 我们忘了传入 props
        console.log(props);      // ✅ {}
        console.log(this.props); // ? undefined
      }
      // ...
    }

如果这时在构造函数中调用了函数，函数中有 this.props.xxx 这种写法，直接就报错了。

而用 super(props)，则不会报错。

    class Button extends React.Component {
      constructor(props) {
        super(props); // ✅ 我们传了 props
        console.log(props);      // ✅ {}
        console.log(this.props); // ✅ {}
      }
      // ...
    }

所以我们总是推荐使用 super(props) 的写法，即便这是非必要的。

参考：<https://overreacted.io/why-do-we-write-super-props/>
