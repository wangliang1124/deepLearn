# React 中组件通信的几种方式

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://juejin.cn/post/6844903520500449288>
> 对应题目：React 第 1 题 · 组件之间如何通信
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

![react组件通信](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2017/12/10/1603ebfaf5ec3909~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.awebp)

> 首次发表在[个人博客](<https://link.juejin.cn?target=http%3A%2F%2Fwangyaxing.top%2F2017%2F12%2F10%2Freact%25E4%25B8%25AD%25E7%25BB%2584%25E4%25BB%25B6%25E9%2580%259A%25E4%25BF%25A1%25E7%259A%2584%25E5%2587%25A0%25E7%25A7%258D%25E6%2596%25B9%25E5%25BC%258F%2F%23more> "http://wangyaxing.top/2017/12/10/react%E4%B8%AD%E7%BB%84%E4%BB%B6%E9%80%9A%E4%BF%A1%E7%9A%84%E5%87%A0%E7%A7%8D%E6%96%B9%E5%BC%8F/#more")

# 需要组件之进行通信的几种情况

  * 父组件向子组件通信
  * 子组件向父组件通信
  * 跨级组件通信
  * 没有嵌套关系组件之间的通信

## 1\. 父组件向子组件通信

React数据流动是单向的,父组件向子组件通信也是最常见的;父组件通过props向子组件传递需要的信息 Child.jsx

    import React from 'react';
    import PropTypes from 'prop-types';

    export default function Child({ name }) {
        return <h1>Hello, {name}</h1>;
    }

    Child.propTypes = {
        name: PropTypes.string.isRequired,
    };

Parent.jsx

    import React, { Component } from 'react';

    import Child from './Child';

    class Parent extends Component {
        render() {
            return (
                <div>
                    <Child name="Sara" />
                </div>
            );
        }
    }

    export default Parent;

## 2\. 子组件向父组件通信

### 回调函数

实现在子组件中点击隐藏组件按钮可以将自身隐藏的功能

List3.jsx

    import React, { Component } from 'react';
    import PropTypes from 'prop-types';

    class List3 extends Component {
        static propTypes = {
            hideConponent: PropTypes.func.isRequired,
        }
        render() {
            return (
                <div>
                    哈哈,我是List3
                    <button onClick={this.props.hideConponent}>隐藏List3组件</button>
                </div>
            );
        }
    }

    export default List3;

App.jsx

    import React, { Component } from 'react';

    import List3 from './components/List3';
    export default class App extends Component {
        constructor(...args) {
            super(...args);
            this.state = {
                isShowList3: false,
            };
        }
        showConponent = () => {
            this.setState({
                isShowList3: true,
            });
        }
        hideConponent = () => {
            this.setState({
                isShowList3: false,
            });
        }
        render() {
            return (
                <div>
                    <button onClick={this.showConponent}>显示Lists组件</button>
                    {
                        this.state.isShowList3 ?
                            <List3 hideConponent={this.hideConponent} />
                        :
                        null
                    }

                </div>
            );
        }
    }

观察一下实现方法,可以发现它与传统回调函数的实现方法一样.而且setState一般与回调函数均会成对出现,因为回调函数即是转换内部状态是的函数传统;

## 3\. 跨级组件通信

> 例如A组件和B组件之间要进行通信,先找到A和B公共的父组件,A先向C组件通信,C组件通过props和B组件通信,此时C组件起的就是中间件的作用

> context是一个全局变量,像是一个大容器,在任何地方都可以访问到,我们可以把要通信的信息放在context上,然后在其他组件中可以随意取到; 但是React官方不建议使用大量context,尽管他可以减少逐层传递,但是当组件结构复杂的时候,我们并不知道context是从哪里传过来的;而且context是一个全局变量,全局变量正是导致应用走向混乱的罪魁祸首.

### 使用context

下面例子中的组件关系: ListItem是List的子组件,List是app的子组件

ListItem.jsx

    import React, { Component } from 'react';
    import PropTypes from 'prop-types';

    class ListItem extends Component {
        // 子组件声明自己要使用context
        static contextTypes = {
            color: PropTypes.string,
        }
        static propTypes = {
            value: PropTypes.string,
        }
        render() {
            const { value } = this.props;
            return (
                <li style={{ background: this.context.color }}>
                    <span>{value}</span>
                </li>
            );
        }
    }

    export default ListItem;

List.jsx

    import ListItem from './ListItem';

    class List extends Component {
        // 父组件声明自己支持context
        static childContextTypes = {
            color: PropTypes.string,
        }
        static propTypes = {
            list: PropTypes.array,
        }
        // 提供一个函数,用来返回相应的context对象
        getChildContext() {
            return {
                color: 'red',
            };
        }
        render() {
            const { list } = this.props;
            return (
                <div>
                    <ul>
                        {
                            list.map((entry, index) =>
                                <ListItem key={`list-${index}`} value={entry.text} />,
                           )
                        }
                    </ul>
                </div>
            );
        }
    }

    export default List;

App.jsx

    import React, { Component } from 'react';
    import List from './components/List';

    const list = [
        {
            text: '题目一',
        },
        {
            text: '题目二',
        },
    ];
    export default class App extends Component {
        render() {
            return (
                <div>
                    <List
                        list={list}
                    />
                </div>
            );
        }
    }

## 4\. 没有嵌套关系的组件通信

> 在componentDidMount事件中,如果组件挂载完成,再订阅事件;在组件卸载的时候,在componentWillUnmount事件中取消事件的订阅; 以常用的发布/订阅模式举例,借用Node.js Events模块的浏览器版实现

### 使用自定义事件的方式

下面例子中的组件关系: List1和List2没有任何嵌套关系,App是他们的父组件;

实现这样一个功能: 点击List2中的一个按钮,改变List1中的信息显示 首先需要项目中安装events 包：

    npm install events --save

在src下新建一个util目录里面建一个events.js

    import { EventEmitter } from 'events';

    export default new EventEmitter();

list1.jsx

    import React, { Component } from 'react';
    import emitter from '../util/events';

    class List extends Component {
        constructor(props) {
            super(props);
            this.state = {
                message: 'List1',
            };
        }
        componentDidMount() {
            // 组件装载完成以后声明一个自定义事件
            this.eventEmitter = emitter.addListener('changeMessage', (message) => {
                this.setState({
                    message,
                });
            });
        }
        componentWillUnmount() {
            emitter.removeListener(this.eventEmitter);
        }
        render() {
            return (
                <div>
                    {this.state.message}
                </div>
            );
        }
    }

    export default List;

List2.jsx

    import React, { Component } from 'react';
    import emitter from '../util/events';

    class List2 extends Component {
        handleClick = (message) => {
            emitter.emit('changeMessage', message);
        };
        render() {
            return (
                <div>
                    <button onClick={this.handleClick.bind(this, 'List2')}>点击我改变List1组件中显示信息</button>
                </div>
            );
        }
    }

APP.jsx

    import React, { Component } from 'react';
    import List1 from './components/List1';
    import List2 from './components/List2';

    export default class App extends Component {
        render() {
            return (
                <div>
                    <List1 />
                    <List2 />
                </div>
            );
        }
    }

自定义事件是典型的发布订阅模式,通过向事件对象上添加监听器和触发事件来实现组件之间的通信

## 总结

  * 父组件向子组件通信: props
  * 子组件向父组件通信: 回调函数/自定义事件
  * 跨级组件通信: 层层组件传递props/context
  * 没有嵌套关系组件之间的通信: 自定义事件

> 在进行组件通信的时候,主要看业务的具体需求,选择最合适的; 当业务逻辑复杂到一定程度,就可以考虑引入[Mobx](<https://link.juejin.cn?target=http%3A%2F%2Fcn.mobx.js.org%2F> "http://cn.mobx.js.org/"),[Redux](<https://link.juejin.cn?target=https%3A%2F%2Fredux.js.org%2F> "https://redux.js.org/")等状态管理工具

## 参考
