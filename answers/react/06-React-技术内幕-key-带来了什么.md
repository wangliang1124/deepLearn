# React 技术内幕 key 带来了什么

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://juejin.cn/post/6844903493900173320>
> 对应题目：React 第 6 题 · React 中 keys 的作用是什么？
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

首先欢迎大家关注我的掘金[账号](<https://juejin.cn/user/3650034331551671> "https://juejin.cn/user/3650034331551671")和Github[博客](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2FMrErHu%2Fblog> "https://github.com/MrErHu/blog")，也算是对我的一点鼓励，毕竟写东西没法获得变现，能坚持下去也是靠的是自己的热情和大家的鼓励。

大家在使用React的过程中，当组件的子元素是一系列类型相同元素时，就必须添加一个属性`key`,否则React将给出一个warning:  

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/9/3/dd914fe9176a8cf016e1ba462a07b87f~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

所以我们需要了解一下`key`值在React中起到了什么作用，在这之前我们先出一个小题目: 

    import React from 'react'
    import ReactDOM from 'react-dom'

    function App() {
        return (
            <ul>
                {
                    [1,1,2,2].map((val)=><li key={val}>{val}</li>)
                }
            </ul>
        )
    }

    ReactDOM.render(<App/>,document.getElementById('root'))

现在要提问了，上面的例子显示的是: 1,1,2,2还是1,2呢。事实上显示的只有1和2，所以我们不禁要问为什么? 

## 一致性处理(Reconciliation) 

我们知道每当组件的`props`和`state`发送改变时，React都会调用render去重新渲染UI，实质上render函数作用就是返回最新的元素树。这里我们要明确一个点: 什么是组件？什么是元素?  

React元素是用来描述UI对象的，JSX的实质就是React.createElement的语法糖，作用就是生成React元素。而React组件是一个方法或者类(Class)，其目的就是接受输入并返回一个ReactElement，当然调用React组件一般采用的也是通过JSX的方法，其本质也是通过React.createElement方式去调用组件的。  

我们之前说过，组件`state`和`props`的改变会引起render函数的调用，而render函数会返回新的元素树。我们知道React使得我们并不需要关心更改的内容，只需要将精力集中于数据的变化，React会负责前后UI更新。这时候React就面临一个问题，如果对比当前的元素树与之前的元素树，从而找到最优的方法(或者说是步骤最少的方法)将一颗树转化成另一棵树，从而去更新真实的DOM元素。目前存在大量的方法可以将一棵树转化成另一棵树，但它们的时间复杂度基本都是O(n3),这么庞大的时间数量级我们是不能接受的，试想如果我们的组件返回的元素树中含有100个元素，那么一次一致性比较就要达到1000000的数量级，这显然是低效的，不可接受的。这时React就采用了启发式的算法。 

## 启发式算法

了解一下什么是启发式算法：

> 启发式算法指人在解决问题时所采取的一种根据经验规则进行发现的方法。其特点是在解决问题时,利用过去的经验,选择已经行之有效的方法，而不是系统地、以确定的步骤去寻求答案。

React启发式算法就是采用一系列**前提** 和**假设** ，使得比较前后元素树的时间复杂度由O(n3)降低为O(n)，React启发式算法的前提条件主要包括两点:

  1. 不同的两个元素会产生不同的树
  2. 可以使用key属性来表明不同的渲染中哪些元素是相同的

### 元素类型的比较

函数`React.createElement`的第一个参数就是`type`，表示的就是元素的类型。React比较两棵元素树的过程是同步的，当React比较到元素树中同一位置的元素节点时，如果前后元素的类型不同时,不论该元素是组件类型还是DOM类型的，那么以这个节点(React元素)为子树的所有节点都会被销毁并重新构建。举个例子: 

    //old tree
    <div>
      <Counter />
    </div>

    //new tree
    <span>
      <Counter />
    </span>

上面表示前后两个render函数返回的元素树，由于`Counter`元素的父元素由`div`变成了`span`，那么那就导致`Counter`的卸载(`unmount`)和重新安装(`mount`)。这看起来没有什么问题，但是在某些情况下问题就会凸显出来，比如**状态的丢失** 。下面我们再看一个例子: 

    import React, {Component} from 'react'
    import ReactDOM from 'react-dom'

    class Counter extends Component {

        constructor(props){
            super(props);
        }

        state = {
            value: 0
        }

        componentWillMount(){
            console.log('componentWillMount');
        }

        componentDidMount(){
            this.timer = setInterval(()=>{
                this.setState({
                    value: this.state.value + 1
                })
            },1000)
        }

        componentWillUnmount(){
            clearInterval(this.timer);
            console.log('componentWillUnmount');
        }

        render(){
            return(
                <div>{this.state.value}</div>
            )
        }
    }

    function Demo(props) {
        return props.flag ? (<div><Counter/></div>) : (<span><Counter/></span>);
    }

    class App extends Component{
        constructor(props){
            super(props);
        }

        state = {
            flag: false
        }

        render(){
            return(
                <div>
                    <Demo flag = {this.state.flag}/>
                    <button
                        onClick={()=>{
                            this.setState({
                                flag: !this.state.flag
                            })
                        }}
                    >
                        Click
                    </button>
                </div>
            )
        }
    }

    ReactDOM.render(<App/>, document.getElementById('root'))

上面的例子中，我们首先让计数器`Counter`运行几秒钟，然后我们点击按钮的话，我们会发现计数器的值会归零为0，并且`Counter`分别调用`componentWillUnmount`与`componentWillMount`并完成组件卸载与安装的过程。需要注意的是，状态(`state`)的丢失有时候会造成不可预知的问题，需要尤为注意。  

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/9/3/60d9eea1171b8f859bbcfd7f24b1ad5d~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

那如果比较前后元素类型是相同的情况下，情况就有所区别，如果该元素类型是DOM类型，比如:

    <div className="before" title="stuff" />

    <div className="after" title="stuff" />

那么React包保持底层DOM元素不变，仅更新改变的DOM元素属性，比如在上面的例子中，React仅会更新div标签的`className`属性。如果改变的是style属性中的某一个属性，也不会整个更改style，而仅仅是更新其中改变的项目。

如果前后的比较元素是组件类型，那么也会保持组件实例的不变，React会更新组件实例的属性来匹配新的元素，并在元素实例上调用`componentWillReceiveProps()` 与 `componentWillUpdate()`。 

### key属性

在上面的前后元素树比较过程中，如果某个元素的子元素是动态数组类型的，那么比较的过程可能就要有所区分，比如: 

    //注意:
    //li元素是数组生成的，下面只是表示元素树，并不代表实际代码
    //old tree
    <ul>
      <li>first</li>
      <li>second</li>
    </ul>

    //new tree
    <ul>
      <li>first</li>
      <li>second</li>
      <li>third</li>
    </ul>

当React同时迭代比较前后两棵元素树的子元素列表时，性能相对不会太差，因为前两个项都是相同的，新的元素树中有第三个项目，那么React会比较`<li>first</li>`树与`<li>second</li>`树之后，插入`<li>third</li>`树，但是下面这个例子就不同的: 

    //注意:
    //li元素是数组生成的，下面只是表示元素树，并不代表实际代码
    //old tree
    <ul>
      <li>Duke</li>
      <li>Villanova</li>
    </ul>

    //new tree
    <ul>
      <li>Connecticut</li>
      <li>Duke</li>
      <li>Villanova</li>
    </ul>

React在比较第一个`li`就发现了差异(`<li>Duke</li>`与`<li>Connecticut</li>`)，如果React将第一个`li`中的内容进行更新，那么你会发现第二个`li`(`<li>Villanova</li>`与`<li>Duke</li>`)也需要将`li`中内容进行更新，并且第三个`<li>`需要安装新的元素，但事实真的是如此吗？其实不然，我们发现新的元素树和旧的元素树，只有第一项是不同的，后两项其实并没有发生改变，如果React懂得在旧的元素树开始出插入`<li>Connecticut</li>`，那么性能会极大的提高，关键问题是React如何进行这种判别，这时React就用到了**`key`属性**。  

例如:

    //注意:
    //li元素是数组生成的，下面只是表示元素树，并不代表实际代码
    //old tree
    <ul>
      <li key="2015">Duke</li>
      <li key="2016">Villanova</li>
    </ul>

    //new tree
    <ul>
      <li key="2014">Connecticut</li>
      <li key="2015">Duke</li>
      <li key="2016">Villanova</li>
    </ul>

通过key值React比较`<li key="2015">Duke</li>`与`<li key="2014">Connecticut</li>`时，会发现`key`值是不同，表示`<li key="2014">Connecticut</li>`是新插入的项，因此会在开始出插入`<li key="2014">Connecticut</li>`,随后分别比较`<li key="2015">Duke</li>`与`<li key="2016">Villanova</li>`,发现`li`项没有发生改变，仅仅只是被移动而已。这种情况下，性能的提升是非常可观的。因此，从上面看`key`值必须要**稳定** 、**可预测** 的并且是**唯一** 的。不稳定的key(类似于Math.random()函数的结果)可能会产生非常多的组件实例并且DOM节点也会非必要性的重新创建。这将会造成极大的性能损失和组件内state的丢失。  

回到刚开始的问题，如果存在两个`key`值相同时，会发生什么？比如: 

     <ul>
        {
            [1,1,2,2].map((val)=><li>{val}</li>)
        }
    </ul>

我们会发现如果存在前后两个相同的`key`，React会认为这两个元素其实是一个元素，后一个具有相同key值的元素会被忽略。为了验证这个事实，我们可以看下一个例子:

    import React, {Component} from 'react'
    import ReactDOM from 'react-dom'

    function Demo(props) {
        return (
            <div>{props.value}</div>
        )
    }

    class App extends Component {
        constructor(props) {
            super(props);
        }

        render() {
            return (
                <div>
                    {
                        [1, 1, 2, 2].map((val, index) => {
                            return (
                                <Demo
                                    key={val}
                                    value={val + '-' + index}
                                />
                            )
                        })
                    }
                </div>
            )
        }
    }

    ReactDOM.render(<App/>, document.getElementById('root'))

我们发现最后的显示效果是这样的:

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/9/3/5cd9bb63b85faf735450de1777ae9042~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

到这里我们已经基本明白了`key`属性在React中的作用，因为`key`是React内部使用的属性，所以在组件内部是无法获取到`key`值的，如果你真的需要这个值，就需要换个名字再传一次了。  

其实还有一个现象不知道大家观察到了没有，比如: 

    //case1
    function App() {
        return (
            <ul>
                {
                    [
                        <li key={1}>1</li>,
                        <li key={2}>2</li>
                    ]
                }
            </ul>
        )
    }
    //case2
    function App() {
        return (
            <ul>
                <li>1</li>
                <li>2</li>
            </ul>
        )
    }

我们会发现，第一种场景是需要传入key值的，第二种就不需要传入key，为什么呢？其实我们可以看一下JSX编译之后的代码: 

    //case1
    function App() {
        return React.createElement('ul',null,[
            React.createElement('li',{key: 1}, "1"),
            React.createElement('li',{key: 2}, "2")
        ])
    }
    //case2
    function App() {
        return React.createElement('ul',
            null,
            React.createElement('li',{key: 1}, "1"),
            React.createElement('li',{key: 2}, "2")
        )
    }

我们发现第一个场景中，子元素的传入**以数组的形式** 传入第三个参数，但是在第二个场景中，子元素是以参数的形式依次传入的。在第二种场景中，每个元素出现在固定的参数位置上，React就是通过这个位置作为天然的`key`值去判别的，所以你就不用传入key值的，但是第一种场景下，以数组的类型将全部子元素传入，React就不能通过参数位置的方法去判别，所以就必须你手动地方式去传入`key`值。  

React通过采用这种启发式的算法，来优化一致性的操作。但这都是React的内部实现方式，可能在React后序的版本中不断细化启发式算法，甚至采用别的启发式算法。但是如果我们有时候能够了解到内部算法的实现细节的话，对于优化应用性能可以起到非常好的效果，对于共同学习的大家，以此共勉。
