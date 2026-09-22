# redux 中间件原理及实现

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/8c2a37247020>
> 对应题目：状态管理 第 5 题 · Redux 中间件是什么东西，接受几个参数（两端的柯里化函数）
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

最近看跟react相关库的源码，越来越发现里面中间件机制的特别重要，各种类库都是基于此封装的功能，比如redux简单的几个函数，却巧妙的实现了中间件创建，组合，调用，下面就一一分析

先看下面最简单的`redux`使用例子

    import { createStore, applyMiddleware, compose } from 'redux'
    import thunk from 'redux-thunk'
    import reducers from './reducer'

    const store = createStore(reducers, compose(
        applyMiddleware(thunk),
        window.devToolsExtension ? window.devToolsExtension() : f => f
    ))

#### 创建中间件

我们从最里面看，这里的`thunk`就是个满足redux的中间件实现，打开源码看看，`createThunkMiddleware`利用函数柯里化的特性缓存了三层参数变量，后面调用了才暴露出去的，所以`thunk`其实只缓存了两层参数变量

    function createThunkMiddleware(extraArgument) {
      return ({ dispatch, getState }) => next => action => {
        if (typeof action === 'function') {
          return action(dispatch, getState, extraArgument);
        }
        return next(action);
      };
    }
    const thunk = createThunkMiddleware();
    thunk.withExtraArgument = createThunkMiddleware;
    export default thunk;

`thunk`简化后就是, 接受两个参数`dispatch`和 `getState`, 返回一个函数，继续调用则会传入`next`就是真正的`dispatch`的， 这里`action`一般都是一个对象，比如`{type: AUTH_SUCCESS, payload:data}`, 就用`dispatch(action)`去触发变更组件，但是这个中间件判断了一下`action`是函数`function`的时候，会调用这个函数，然后把参数传进去

    function thunk ({ dispatch, getState }) {
       return next => actioin => {
          if (typeof action === 'function') {
             return action(dispatch, getState);
          }
          return next(action);
      }
    }

那么`action`是函数的时候是怎么样的呢，这就是`reudx-thunk`实现的功能, 在有异步请求的时候，应该返回一个函数，比如下面, 这就可以在里面继续使用`dispatch`和`getState`了，真是煞费苦心啊，就为了实现代码隔离的时候还能够使用`redux`里面的`dispatch`和`getState`来获取状态和触发`action`实现更新组件

    export function login({user, pwd}) {
        return (dispatch, getState) => {
            axios.post('/user/login', {user, pwd})
            .then(res=>{
                if (res.status === 200 && res.data.code === 0){
                    dispatch(authSuccess(res.data.data))
                } else {
                    dispatch(errorMsg(res.data.msg))
                }
            })
        }
    }

#### 使用中间件

上面搞清楚了中间件的创建，那么怎么使用呢，这下就要看`applyMiddleware`这个函数了，代码如下，也没有几行，可是信息量很大啊，整体来看又是柯里化来保存参数，证明如果有中间件的话，会传入`createStore`，在这里面构建`store`，生成每个中间件都需要的`dispatch`和`getState`, 接着重点来了，遍历`middlewares`中间件数组，分别调用每个中间件一次

    export default function applyMiddleware(...middlewares) {
      return (createStore) => (reducer, preloadedState, enhancer) => {
        const store = createStore(reducer, preloadedState, enhancer)
        let dispatch = store.dispatch
        let chain = []
        const middlewareAPI = {
          getState: store.getState,
          dispatch: (action) => dispatch(action)
        }
        chain = middlewares.map(middleware => middleware(middlewareAPI))
        dispatch = compose(...chain)(store.dispatch)
        return {
          ...store,
          dispatch
        }
      }
    }

    export default function compose(...funcs) {
      if (funcs.length === 0) {
        return arg => arg
      }
      if (funcs.length === 1) {
        return funcs[0]
      }
      return funcs.reduce((a, b) => (...args) => a(b(...args)))
    }
