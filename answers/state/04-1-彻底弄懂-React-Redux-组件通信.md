# 彻底弄懂 React-Redux 组件通信

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://blog.csdn.net/DFF1993/article/details/80410154>
> 对应题目：状态管理 第 4 题 · Redux 如何实现多个组件之间的通信，多个组件使用相同状态如何进行管理
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

为了方便使用，Redux的作者封装了一个React专用的库React-Redux，讲解之前，先来了解一下什么是容器组件和傻瓜组件？

React-Redux把组件分为容器组件和傻瓜组件（UI组件）。

## 一、容器组件

容器组件，负责和Redux Store打交道的组件，处于外层。

功能：和Redux Store打交道，读取Store的状态，用于初始化组件的状态，同时还要监听Store的状态改变；当Store状态发生变化时，需要更新组件状态，从而驱动组件重新渲染；当需要更新Store状态时，就会派发action对象。

特征：

  * 负责管理数据和业务逻辑，不负责UI的呈现
  * 带有内部状态
  * 使用Redux的API

## 二、傻瓜组件

傻瓜组件也叫做UI组件，只专心负责渲染界面的组件，处于内层。

功能：根据当前props和state，渲染出用户界面。

特征：

  * 只负责UI的呈现，不带有任何业务逻辑；
  * 没有状态（即不使用this.state这个变量）
  * 所有数据都由参数（this.props）提供；
  * 不使用任何Redux的API；

简单一句话：UI组件负责UI的呈现，容器组件负责管理数据和逻辑。

下边是容器组件和傻瓜组件的分工图：

## 三、React-Redux

React-Redux提供了两个最主要的功能：

  * connect：连接容器组件和傻瓜组件；
  * Provider：提供包含store的connect；

## 1、connect

语法如下：

    export default connect(
      mapStateToProps,
      mapDispatchToProps
    )(Home)

接收两个参数mapStateToProps和mapDispatchToProps，执行结果依然是一个函数，所以才在最后又加一个圆括号，把connect函数执行的结果立即执行，这一次参数是Home这个傻瓜组件。

这里有两次函数执行，第一次是connect函数的执行，第二次是把connect函数返回的函数再次执行，最后产生的就是容器组件。

作为容器组件，要做的工作无外乎两件事：

  * 把Store上的状态转化为内层傻瓜组件的prop；
  * 把内层傻瓜组件中的用户动作转化为派送给Store的动作。

一个是内层傻瓜对象的输入，一个是内层傻瓜对象的输出。

因此，connect的完整API如下：

    import { connect } from 'react-redux'
    export default connect(
      mapStateToProps,
      mapDispatchToProps
    )(Home)

## (1) mapStateToProps

mapStateToProps是一个函数，它建立一个从外部的state对象到UI组件的props对象的映射关系。

    function mapStateToProps(state) {
      return {
        number: state.count.number
      }
    }

上面代码中，mapStateToProps是一个函数，接受state作为参数，返回一个对象。这个对象有一个number属性，代表UI组件的同名参数，后面的count也是一个函数，可以从state算出number的值。

下面就是count的一个例子：

    import { combineReducers } from 'redux'
    const initialState={
        number:2
    };
    function update(state = initialState, action) {
        switch (action.type) {
            case 'INCREASE':
                console.log("INCREASE");
                console.log(state);
                return {
                    number: state.number+action.payload 
                };
            case 'DECREASE':
                console.log("DECREASE");
                console.log(state);
                return {
                    number:state.number-action.payload  
                };
            default:
                return state;
        }
    }
    export default combineReducers({
        count: update,
    })

**mapStateToProps会订阅Store，每当state更新的时候，就会自动执行** ，重新计算UI组件的参数，从而触发UI组件的重新渲染。

**mapStateToProps的第一个参数总是state对象** ，还可以使用第二个参数，代表容器组件的props对象。

    const mapStateToProps = (state, ownProps) => {  
        return {    
            active: ownProps.filter === state.visibilityFilter  
        }
    }

使用ownProps作为参数后，如果容器组件的参数发生变化，也会引发UI组件重新渲染。

## (2) mapDispatchToProps

mapDispatchToProps是connect函数的第二个参数，用来建立UI组件的参数到store.dispatch方法的映射。也就是说，它定义了哪些用户操作应该当做Action传给Store。

    function mapDispatchToProps(dispatch) {
      return {
        setIncrease: (state) => dispatch(state),
        setDecrease: (state) => dispatch(state)
      }
    }

## 2、Provider

connect方法生成容器组件以后，需要让容器组件拿到state对象，才能生成UI组件的参数。

Provider就是把我们用Redux创建的store传递到内部的其他组件，让内部组件可以享有这个store并提供对state的更新。

    import React, { Component } from 'react';
    import { createStore} from 'redux'
    import { Provider } from 'react-redux'
    import {BrowserRouter } from 'react-router-dom';
    import { Route } from 'react-router'

    import reducers from '../reducer/index.js'
    import  App from '../views/App.js'
    import  Home from '../views/Home.js'
    import  Another from '../views/Another.js'

    const store = createStore(reducers);

    export default class RouterIndex extends Component {
      render() {
        return ( 
            <Provider store={store}>
              <BrowserRouter>
                <App path="/App" component={App}>
                  <Route path="/App/home" component={Home} />
                  <Route path="/App/another" component={Another} />
                </App>
              </BrowserRouter>
            </Provider>
        )
      }
    }

文中主要用到了react-redux和react-router两个插件

  * react-redux实现组件之间的通信；
  * react-router实现页面之间的跳转；

源码见：<https://github.com/DuFanFan1/react-redux-demo>
