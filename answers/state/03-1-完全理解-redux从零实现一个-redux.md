# 完全理解 redux（从零实现一个 redux）

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/brickspert/blog/issues/22>
> 对应题目：状态管理 第 3 题 · Redux
> 抓取时间：2026-09-22

---

# 完全理解 redux

关注公众号「前端技术砖家」，拉你进交流群，大家一起共同交流和进步。

[![image](https://user-images.githubusercontent.com/12526493/80437152-76f00400-8933-11ea-8a95-edda05152736.png)](<https://user-images.githubusercontent.com/12526493/80437152-76f00400-8933-11ea-8a95-edda05152736.png>)

### 目录

  1. [前言](<https://github.com/brickspert/blog/issues/22#intro>)
  2. [状态管理器](<https://github.com/brickspert/blog/issues/22#state>)
  3. [多文件协作](<https://github.com/brickspert/blog/issues/22#coordination>)
     * reducer 的拆分和合并
     * state 的拆分和合并
  4. [中间件 middleware](<https://github.com/brickspert/blog/issues/22#middleware>)
  5. [完整的 redux](<https://github.com/brickspert/blog/issues/22#redux>)
  6. [最佳实践](<https://github.com/brickspert/blog/issues/22#practice>)
  7. [总结](<https://github.com/brickspert/blog/issues/22#summary>)

前言

记得开始接触 react 技术栈的时候，最难理解的地方就是 redux。全是新名词：reducer、store、dispatch、middleware 等等，我就理解 state 一个名词。

网上找的 redux 文章，要不有一本书的厚度，要不很玄乎，晦涩难懂，越看越觉得难，越看越怕，信心都没有了！

花了很长时间熟悉 redux，慢慢的发现它其实真的很简单。本章不会把 redux 的各种概念，名词解释一遍，这样和其他教程没有任何区别，没有太大意义。我会带大家从零实现一个完整的 redux，让大家知其然，知其所以然。

开始前，你必须知道一些事情：

  * redux 和 react 没有关系，redux 可以用在任何框架中，忘掉 react。
  * connect 不属于 redux，它其实属于 react-redux，请先忘掉它，下一章节，我们会介绍它。
  * 请一定先忘记 reducer、store、dispatch、middleware 等等这些名词。
  * redux 是一个状态管理器。

Let's Go！

状态管理器

#### 简单的状态管理器

redux 是一个状态管理器，那什么是状态呢？状态就是数据，比如计数器中的 count。

我们来使用下状态

    console.log(state.count);

我们来修改下状态

好了，现在我们实现了状态（计数）的修改和使用了。

> 读者：你当我傻吗？你说的这个谁不知道？捶你👊！
> 
> 笔者：哎哎哎，别打我！有话好好说！redux 核心就是这个呀！我们一步一步扩展开来嘛！

当然上面的有一个很明显的问题：修改 count 之后，使用 count 的地方不能收到通知。我们可以使用发布-订阅模式来解决这个问题。

    /*------count 的发布订阅者实践------*/
    let state = {
      count: 1
    };
    let listeners = [];

    /*订阅*/
    function subscribe(listener) {
      listeners.push(listener);
    }

    function changeCount(count) {
      state.count = count;
      /*当 count 改变的时候，我们要去通知所有的订阅者*/
      for (let i = 0; i < listeners.length; i++) {
        const listener = listeners[i];
        listener();
      }
    }

我们来尝试使用下这个简单的计数状态管理器。

    /*来订阅一下，当 count 改变的时候，我要实时输出新的值*/
    subscribe(() => {
      console.log(state.count);
    });

    /*我们来修改下 state，当然我们不能直接去改 state 了，我们要通过 changeCount 来修改*/
    changeCount(2);
    changeCount(3);
    changeCount(4);

现在我们可以看到，我们修改 count 的时候，会输出相应的 count 值。

现在有两个新的问题摆在我们面前

  * 这个状态管理器只能管理 count，不通用
  * 公共的代码要封装起来

我们尝试来解决这个问题，把公共的代码封装起来

    const createStore = function (initState) {
      let state = initState;
      let listeners = [];

      /*订阅*/
      function subscribe(listener) {
        listeners.push(listener);
      }

      function changeState(newState) {
        state = newState;
        /*通知*/
        for (let i = 0; i < listeners.length; i++) {
          const listener = listeners[i];
          listener();
        }
      }

      function getState() {
        return state;
      }

      return {
        subscribe,
        changeState,
        getState
      }
    }

我们来使用这个状态管理器管理多个状态 counter 和 info 试试

    let initState = {
      counter: {
        count: 0
      },
      info: {
        name: '',
        description: ''
      }
    }

    let store = createStore(initState);

    store.subscribe(() => {
      let state = store.getState();
      console.log(`${state.info.name}：${state.info.description}`);
    });
    store.subscribe(() => {
      let state = store.getState();
      console.log(state.counter.count);
    });

    store.changeState({
      ...store.getState(),
      info: {
        name: '前端九部',
        description: '我们都是前端爱好者！'
      }
    });

    store.changeState({
      ...store.getState(),
      counter: {
        count: 1
      }
    });

到这里我们完成了一个简单的状态管理器。

这里需要理解的是 `createStore`，提供了 `changeState`，`getState`，`subscribe` 三个能力。

本小节完整源码见 [demo-1](<https://github.com/frontend9/redux-demo/tree/master/demo-1>)

#### 有计划的状态管理器

我们用上面的状态管理器来实现一个自增，自减的计数器。

    let initState = {
      count: 0
    }
    let store = createStore(initState);

    store.subscribe(() => {
      let state = store.getState();
      console.log(state.count);
    });
    /*自增*/
    store.changeState({
      count: store.getState().count + 1
    });
    /*自减*/
    store.changeState({
      count: store.getState().count - 1
    });
    /*我想随便改*/
    store.changeState({
      count: 'abc'
    });

你一定发现了问题，count 被改成了字符串 `abc`，因为我们对 count 的修改没有任何约束，任何地方，任何人都可以修改。

我们需要约束，不允许计划外的 count 修改，我们只允许 count 自增和自减两种改变方式！

那我们分两步来解决这个问题

  1. 制定一个 state 修改计划，告诉 store，我的修改计划是什么。
  2. 修改 store.changeState 方法，告诉它修改 state 的时候，按照我们的计划修改。

我们来设置一个 plan 函数，接收现在的 state，和一个 action，返回经过改变后的新的 state。

    /*注意：action = {type:'',other:''}, action 必须有一个 type 属性*/
    function plan(state, action) {
      switch (action.type) {
        case 'INCREMENT':
          return {
            ...state,
            count: state.count + 1
          }
        case 'DECREMENT':
          return {
            ...state,
            count: state.count - 1
          }
        default:
          return state;
      }
    }

我们把这个计划告诉 store，store.changeState 以后改变 state 要按照我的计划来改。

    /*增加一个参数 plan*/
    const createStore = function (plan, initState) {
      let state = initState;
      let listeners = [];

      function subscribe(listener) {
        listeners.push(listener);
      }

      function changeState(action) {
        /*请按照我的计划修改 state*/  
        state = plan(state, action);
        for (let i = 0; i < listeners.length; i++) {
          const listener = listeners[i];
          listener();
        }
      }

      function getState() {
        return state;
      }

      return {
        subscribe,
        changeState,
        getState
      }
    }

我们来尝试使用下新的 createStore 来实现自增和自减

    let initState = {
      count: 0
    }
    /*把plan函数*/
    let store = createStore(plan, initState);

    store.subscribe(() => {
      let state = store.getState();
      console.log(state.count);
    });
    /*自增*/
    store.changeState({
      type: 'INCREMENT'
    });
    /*自减*/
    store.changeState({
      type: 'DECREMENT'
    });
    /*我想随便改 计划外的修改是无效的！*/
    store.changeState({
      count: 'abc'
    });

到这里为止，我们已经实现了一个有计划的状态管理器！

我们商量一下吧？我们给 plan 和 changeState 改下名字好不好？**plan 改成 reducer，changeState 改成 dispatch！**不管你同不同意，我都要换，因为新名字比较厉害（其实因为 redux 是这么叫的）!

本小节完整源码见 [demo-2](<https://github.com/frontend9/redux-demo/tree/master/demo-2>)

多文件协作

#### reducer 的拆分和合并

这一小节我们来处理下 reducer 的问题。啥问题？

我们知道 reducer 是一个计划函数，接收老的 state，按计划返回新的 state。那我们项目中，有大量的 state，每个 state 都需要计划函数，如果全部写在一起会是啥样子呢？

所有的计划写在一个 reducer 函数里面，会导致 reducer 函数及其庞大复杂。按经验来说，我们肯定会按组件维度来拆分出很多个 reducer 函数，然后通过一个函数来把他们合并起来。

我们来管理两个 state，一个 counter，一个 info。

    let state = {
      counter: {
        count: 0
      },
      info: {
        name: '前端九部',
        description: '我们都是前端爱好者！'
      }
    }

他们各自的 reducer

    /*counterReducer, 一个子reducer*/
    /*注意：counterReducer 接收的 state 是 state.counter*/
    function counterReducer(state, action) {
      switch (action.type) {
        case 'INCREMENT':
          return {
            count: state.count + 1
          }
        case 'DECREMENT':
          return {
            ...state,
            count: state.count - 1
          }
        default:
          return state;
      }
    }

    /*InfoReducer，一个子reducer*/
    /*注意：InfoReducer 接收的 state 是 state.info*/
    function InfoReducer(state, action) {
      switch (action.type) {
        case 'SET_NAME':
          return {
            ...state,
            name: action.name
          }
        case 'SET_DESCRIPTION':
          return {
            ...state,
            description: action.description
          }
        default:
          return state;
      }
    }

那我们用 combineReducers 函数来把多个 reducer 函数合并成一个 reducer 函数。大概这样用

    const reducer = combineReducers({
        counter: counterReducer,
        info: InfoReducer
    });

我们尝试实现下 combineReducers 函数

    function combineReducers(reducers) {

      /* reducerKeys = ['counter', 'info']*/
      const reducerKeys = Object.keys(reducers)

      /*返回合并后的新的reducer函数*/
      return function combination(state = {}, action) {
        /*生成的新的state*/
        const nextState = {}

        /*遍历执行所有的reducers，整合成为一个新的state*/
        for (let i = 0; i < reducerKeys.length; i++) {
          const key = reducerKeys[i]
          const reducer = reducers[key]
          /*之前的 key 的 state*/
          const previousStateForKey = state[key]
          /*执行 分 reducer，获得新的state*/
          const nextStateForKey = reducer(previousStateForKey, action)

          nextState[key] = nextStateForKey
        }
        return nextState;
      }
    }

我们来尝试下 combineReducers 的威力吧

    const reducer = combineReducers({
      counter: counterReducer,
      info: InfoReducer
    });

    let initState = {
      counter: {
        count: 0
      },
      info: {
        name: '前端九部',
        description: '我们都是前端爱好者！'
      }
    }

    let store = createStore(reducer, initState);

    store.subscribe(() => {
      let state = store.getState();
      console.log(state.counter.count, state.info.name, state.info.description);
    });
    /*自增*/
    store.dispatch({
      type: 'INCREMENT'
    });

    /*修改 name*/
    store.dispatch({
      type: 'SET_NAME',
      name: '前端九部2号'
    });

本小节完整源码见 [demo-3](<https://github.com/frontend9/redux-demo/tree/master/demo-3>)

#### state 的拆分和合并

上一小节，我们把 reducer 按组件维度拆分了，通过 combineReducers 合并了起来。但是还有个问题， state 我们还是写在一起的，这样会造成 state 树很庞大，不直观，很难维护。我们需要拆分，一个 state，一个 reducer 写一块。

这一小节比较简单，我就不卖关子了，用法大概是这样（注意注释）

    /* counter 自己的 state 和 reducer 写在一起*/
    let initState = {
      count: 0
    }
    function counterReducer(state, action) {
      /*注意：如果 state 没有初始值，那就给他初始值！！*/  
      if (!state) {
          state = initState;
      }
      switch (action.type) {
        case 'INCREMENT':
          return {
            count: state.count + 1
          }
        default:    
          return state;
      }
    }

我们修改下 createStore 函数，增加一行 `dispatch({ type: Symbol() })`

    const createStore = function (reducer, initState) {
      let state = initState;
      let listeners = [];

      function subscribe(listener) {
        listeners.push(listener);
      }

      function dispatch(action) {
        state = reducer(state, action);
        for (let i = 0; i < listeners.length; i++) {
          const listener = listeners[i];
          listener();
        }
      }

      function getState() {
        return state;
      }
      /* 注意！！！只修改了这里，用一个不匹配任何计划的 type，来获取初始值 */
      dispatch({ type: Symbol() })

      return {
        subscribe,
        dispatch,
        getState
      }
    }

我们思考下这行可以带来什么效果？

  1. createStore 的时候，用一个不匹配任何 type 的 action，来触发 `state = reducer(state, action)`
  2. 因为 action.type 不匹配，每个子 reducer 都会进到 default 项，返回自己初始化的 state，这样就获得了初始化的 state 树了。

你可以试试

    /*这里没有传 initState 哦 */
    const store = createStore(reducer);
    /*这里看看初始化的 state 是什么*/
    console.dir(store.getState());

本小节完整源码见 [demo-4](<https://github.com/frontend9/redux-demo/tree/master/demo-4>)

到这里为止，我们已经实现了一个七七八八的 redux 啦！

中间件 middleware

中间件 middleware 是 redux 中最难理解的地方。但是我挑战一下用最通俗的语言来讲明白它。如果你看完这一小节，还没明白中间件是什么，不知道如何写一个中间件，那就是我的锅了！

中间件是对 dispatch 的扩展，或者说重写，增强 dispatch 的功能！

#### 记录日志

我现在有一个需求，在每次修改 state 的时候，记录下来 修改前的 state ，为什么修改了，以及修改后的 state。我们可以通过重写 store.dispatch 来实现，直接看代码

    const store = createStore(reducer);
    const next = store.dispatch;

    /*重写了store.dispatch*/
    store.dispatch = (action) => {
      console.log('this state', store.getState());
      console.log('action', action);
      next(action);
      console.log('next state', store.getState());
    }

我们来使用下

    store.dispatch({
      type: 'INCREMENT'
    });

日志输出为

    this state { counter: { count: 0 } }
    action { type: 'INCREMENT' }
    1
    next state { counter: { count: 1 } }

现在我们已经实现了一个完美的记录 state 修改日志的功能！

#### 记录异常

我又有一个需求，需要记录每次数据出错的原因，我们扩展下 dispatch

    const store = createStore(reducer);
    const next = store.dispatch;

    store.dispatch = (action) => {
      try {
        next(action);
      } catch (err) {
        console.error('错误报告: ', err)
      }
    }

这样每次 dispatch 出异常的时候，我们都会记录下来。

#### 多中间件的合作

我现在既需要记录日志，又需要记录异常，怎么办？当然很简单了，两个函数合起来呗！

    store.dispatch = (action) => {
      try {
        console.log('this state', store.getState());
        console.log('action', action);
        next(action);
        console.log('next state', store.getState());
      } catch (err) {
        console.error('错误报告: ', err)
      }
    }

如果又来一个需求怎么办？接着改 dispatch 函数？那再来10个需求呢？到时候 dispatch 函数肯定庞大混乱到无法维护了！这个方式不可取呀！

我们需要考虑如何实现扩展性很强的多中间件合作模式。

  1. 我们把 loggerMiddleware 提取出来

         const store = createStore(reducer);
         const next = store.dispatch;

         const loggerMiddleware = (action) => {
           console.log('this state', store.getState());
           console.log('action', action);
           next(action);
           console.log('next state', store.getState());
         }

         store.dispatch = (action) => {
           try {
             loggerMiddleware(action);
           } catch (err) {
             console.error('错误报告: ', err)
           }
         }

  2. 我们把 exceptionMiddleware 提取出来

         const exceptionMiddleware = (action) => {
           try {
             /*next(action)*/
             loggerMiddleware(action);
           } catch (err) {
             console.error('错误报告: ', err)
           } 
         }
         store.dispatch = exceptionMiddleware;

  3. 现在的代码有一个很严重的问题，就是 exceptionMiddleware 里面写死了 loggerMiddleware，我们需要让 `next(action)`变成动态的，随便哪个中间件都可以

         const exceptionMiddleware = (next) => (action) => {
           try {
             /*loggerMiddleware(action);*/
             next(action);
           } catch (err) {
             console.error('错误报告: ', err)
           } 
         }
         /*loggerMiddleware 变成参数传进去*/
         store.dispatch = exceptionMiddleware(loggerMiddleware);

  4. 同样的道理，loggerMiddleware 里面的 next 现在恒等于 store.dispatch，导致 loggerMiddleware 里面无法扩展别的中间件了！我们也把 next 写成动态的

         const loggerMiddleware = (next) => (action) => {
           console.log('this state', store.getState());
           console.log('action', action);
           next(action);
           console.log('next state', store.getState());
         }

到这里为止，我们已经探索出了一个扩展性很高的中间件合作模式！

    const store = createStore(reducer);
    const next = store.dispatch;

    const loggerMiddleware = (next) => (action) => {
      console.log('this state', store.getState());
      console.log('action', action);
      next(action);
      console.log('next state', store.getState());
    }

    const exceptionMiddleware = (next) => (action) => {
      try {
        next(action);
      } catch (err) {
        console.error('错误报告: ', err)
      }
    }

    store.dispatch = exceptionMiddleware(loggerMiddleware(next));

这时候我们开开心心的新建了一个 `loggerMiddleware.js`，一个`exceptionMiddleware.js`文件，想把两个中间件独立到单独的文件中去。会碰到什么问题吗？

loggerMiddleware 中包含了外部变量 store，导致我们无法把中间件独立出去。那我们把 store 也作为一个参数传进去好了~

    const store = createStore(reducer);
    const next  = store.dispatch;

    const loggerMiddleware = (store) => (next) => (action) => {
      console.log('this state', store.getState());
      console.log('action', action);
      next(action);
      console.log('next state', store.getState());
    }

    const exceptionMiddleware = (store) => (next) => (action) => {
      try {
        next(action);
      } catch (err) {
        console.error('错误报告: ', err)
      }
    }

    const logger = loggerMiddleware(store);
    const exception = exceptionMiddleware(store);
    store.dispatch = exception(logger(next));

到这里为止，我们真正的实现了两个可以独立的中间件啦！

现在我有一个需求，在打印日志之前输出当前的时间戳。用中间件来实现！

    const timeMiddleware = (store) => (next) => (action) => {
      console.log('time', new Date().getTime());
      next(action);
    }
    ...
    const time = timeMiddleware(store);
    store.dispatch = exception(time(logger(next)));

本小节完整源码见 [demo-6](<https://github.com/frontend9/redux-demo/tree/master/demo-6>)

#### 中间件使用方式优化

上一节我们已经完全实现了正确的中间件！但是中间件的使用方式不是很友好

    import loggerMiddleware from './middlewares/loggerMiddleware';
    import exceptionMiddleware from './middlewares/exceptionMiddleware';
    import timeMiddleware from './middlewares/timeMiddleware';

    ...

    const store = createStore(reducer);
    const next = store.dispatch;

    const logger = loggerMiddleware(store);
    const exception = exceptionMiddleware(store);
    const time = timeMiddleware(store);
    store.dispatch = exception(time(logger(next)));

其实我们只需要知道三个中间件，剩下的细节都可以封装起来！我们通过扩展 createStore 来实现！

先来看看期望的用法

    /*接收旧的 createStore，返回新的 createStore*/
    const newCreateStore = applyMiddleware(exceptionMiddleware, timeMiddleware, loggerMiddleware)(createStore);

    /*返回了一个 dispatch 被重写过的 store*/
    const store = newCreateStore(reducer);

实现 applyMiddleware

    const applyMiddleware = function (...middlewares) {
      /*返回一个重写createStore的方法*/
      return function rewriteCreateStoreFunc(oldCreateStore) {
         /*返回重写后新的 createStore*/
        return function newCreateStore(reducer, initState) {
          /*1. 生成store*/
          const store = oldCreateStore(reducer, initState);
          /*给每个 middleware 传下store，相当于 const logger = loggerMiddleware(store);*/
          /* const chain = [exception, time, logger]*/
          const chain = middlewares.map(middleware => middleware(store));
          let dispatch = store.dispatch;
          /* 实现 exception(time((logger(dispatch))))*/
          chain.reverse().map(middleware => {
            dispatch = middleware(dispatch);
          });

          /*2. 重写 dispatch*/
          store.dispatch = dispatch;
          return store;
        }
      }
    }

#### 让用户体验美好

现在还有个小问题，我们有两种 createStore 了

    /*没有中间件的 createStore*/
    import { createStore } from './redux';
    const store = createStore(reducer, initState);

    /*有中间件的 createStore*/
    const rewriteCreateStoreFunc = applyMiddleware(exceptionMiddleware, timeMiddleware, loggerMiddleware);
    const newCreateStore = rewriteCreateStoreFunc(createStore);
    const store = newCreateStore(reducer, initState);

为了让用户用起来统一一些，我们可以很简单的使他们的使用方式一致，我们修改下 createStore 方法

    const createStore = (reducer, initState, rewriteCreateStoreFunc) => {
        /*如果有 rewriteCreateStoreFunc，那就采用新的 createStore */
        if(rewriteCreateStoreFunc){
           const newCreateStore =  rewriteCreateStoreFunc(createStore);
           return newCreateStore(reducer, initState);
        }
        /*否则按照正常的流程走*/
        ...
    }

最终的用法

    const rewriteCreateStoreFunc = applyMiddleware(exceptionMiddleware, timeMiddleware, loggerMiddleware);

    const store = createStore(reducer, initState, rewriteCreateStoreFunc);

本小节完整源码见 [demo-7](<https://github.com/frontend9/redux-demo/tree/master/demo-7>)

完整的 redux

#### 退订

不能退订的订阅都是耍流浪！我们修改下 store.subscribe 方法，增加退订功能

      function subscribe(listener) {
        listeners.push(listener);
        return function unsubscribe() {
          const index = listeners.indexOf(listener)
          listeners.splice(index, 1)
        }
      }

使用

    const unsubscribe = store.subscribe(() => {
      let state = store.getState();
      console.log(state.counter.count);
    });
    /*退订*/
    unsubscribe();

#### 中间件拿到的store

现在的中间件拿到了完整的 store，他甚至可以修改我们的 subscribe 方法，按照最小开放策略，我们只用把 getState 给中间件就可以了！因为我们只允许你用 getState 方法！

修改下 applyMiddleware 中给中间件传的 store

    /*const chain = middlewares.map(middleware => middleware(store));*/
    const simpleStore = { getState: store.getState };
    const chain = middlewares.map(middleware => middleware(simpleStore));

#### compose

我们的 applyMiddleware 中，把 [A, B, C] 转换成 A(B(C(next)))，是这样实现的

    const chain = [A, B, C];
    let dispatch = store.dispatch;
    chain.reverse().map(middleware => {
       dispatch = middleware(dispatch);
    });

redux 提供了一个 compose 方式，可以帮我们做这个事情

    const chain = [A, B, C];
    dispatch = compose(...chain)(store.dispatch)

看下他是如何实现的

    export default function compose(...funcs) {
      if (funcs.length === 1) {
        return funcs[0]
      }
      return funcs.reduce((a, b) => (...args) => a(b(...args)))
    }

当然 compose 函数对于新人来说可能比较难理解，你只需要他是做什么的就行啦！

#### 省略initState

有时候我们创建 store 的时候不传 initState，我们怎么用？

    const store = createStore(reducer, {}, rewriteCreateStoreFunc);

redux 允许我们这样写

    const store = createStore(reducer, rewriteCreateStoreFunc);

我们仅需要改下 createStore 函数，如果第二个参数是一个object，我们认为他是 initState，如果是 function，我们就认为他是 rewriteCreateStoreFunc。

    function craeteStore(reducer, initState, rewriteCreateStoreFunc){
        if (typeof initState === 'function'){
        rewriteCreateStoreFunc = initState;
        initState = undefined;
      }
      ...
    }

#### 2 行代码的 replaceReducer

reducer 拆分后，和组件是一一对应的。我们就希望在做按需加载的时候，reducer也可以跟着组件在必要的时候再加载，然后用新的 reducer 替换老的 reducer。

    const createStore = function (reducer, initState) {
      ...
      function replaceReducer(nextReducer) {
        reducer = nextReducer
        /*刷新一遍 state 的值，新来的 reducer 把自己的默认状态放到 state 树上去*/
        dispatch({ type: Symbol() })
      }
      ...
      return {
        ...
        replaceReducer
      }
    }

我们来尝试使用下

    const reducer = combineReducers({
      counter: counterReducer
    });
    const store = createStore(reducer);

    /*生成新的reducer*/
    const nextReducer = combineReducers({
      counter: counterReducer,
      info: infoReducer
    });
    /*replaceReducer*/
    store.replaceReducer(nextReducer);

replaceReducer 示例源码见 [demo-5](<https://github.com/frontend9/redux-demo/tree/master/demo-5>)

#### bindActionCreators

bindActionCreators 我们很少很少用到，一般只有在 react-redux 的 connect 实现中用到。

他是做什么的？他通过闭包，把 dispatch 和 actionCreator 隐藏起来，让其他地方感知不到 redux 的存在。

我们通过普通的方式来 隐藏 dispatch 和 actionCreator 试试，注意最后两行代码

    const reducer = combineReducers({
      counter: counterReducer,
      info: infoReducer
    });
    const store = createStore(reducer);

    /*返回 action 的函数就叫 actionCreator*/
    function increment() {
      return {
        type: 'INCREMENT'
      }
    }

    function setName(name) {
      return {
        type: 'SET_NAME',
        name: name
      }
    }

    const actions = {
      increment: function () {
        return store.dispatch(increment.apply(this, arguments))
      },
      setName: function () {
        return store.dispatch(setName.apply(this, arguments))
      }
    }
    /*注意：我们可以把 actions 传到任何地方去*/
    /*其他地方在实现自增的时候，根本不知道 dispatch，actionCreator等细节*/
    actions.increment(); /*自增*/
    actions.setName('九部威武'); /*修改 info.name*/

我眼睛一看，这个 actions 生成的时候，好多公共代码，提取一下

    const actions = bindActionCreators({ increment, setName }, store.dispatch);

来看一下 bindActionCreators 的源码，超级简单（就是生成了刚才的 actions）

    /*核心的代码在这里，通过闭包隐藏了 actionCreator 和 dispatch*/
    function bindActionCreator(actionCreator, dispatch) {
      return function () {
        return dispatch(actionCreator.apply(this, arguments))
      }
    }

    /* actionCreators 必须是 function 或者 object */
    export default function bindActionCreators(actionCreators, dispatch) {
      if (typeof actionCreators === 'function') {
        return bindActionCreator(actionCreators, dispatch)
      }

      if (typeof actionCreators !== 'object' || actionCreators === null) {
        throw new Error()
      }

      const keys = Object.keys(actionCreators)
      const boundActionCreators = {}
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i]
        const actionCreator = actionCreators[key]
        if (typeof actionCreator === 'function') {
          boundActionCreators[key] = bindActionCreator(actionCreator, dispatch)
        }
      }
      return boundActionCreators
    }

bindActionCreators 示例源码见 [demo-8](<https://github.com/frontend9/redux-demo/tree/master/demo-8>)

#### 大功告成

完整的示例源码见 [demo-9](<https://github.com/frontend9/redux-demo/tree/master/demo-9>)，你可以和 [redux](<https://github.com/reduxjs/redux/issues>) 源码做一下对比，你会发现，我们已经实现了 redux 所有的功能了。

当然，为了保证代码的理解性，我们少了一些参数验证。比如 `createStore(reducer)`的参数 reducer 必须是 function 等等。

最佳实践

#### 纯函数

什么是纯函数？

纯函数是这样一种函数，即相同的输入，永远会得到相同的输出，而且没有任何可观察的副作用。

通俗来讲，就两个要素

  1. 相同的输入，一定会得到相同的输出
  2. 不会有 “触发事件”，更改输入参数，依赖外部参数，打印 log 等等副作用

    /*不是纯函数，因为同样的输入，输出结果不一致*/
    function a( count ){
       return count + Math.random();
    }

    /*不是纯函数，因为外部的 arr 被修改了*/
    function b( arr ){
        return arr.push(1);
    }
    let arr = [1, 2, 3];
    b(arr);
    console.log(arr); //[1, 2, 3, 1]

    /*不是纯函数，以为依赖了外部的 x*/
    let x = 1;
    function c( count ){
        return count + x;
    }

我们的 reducer 计划函数，就必须是一个纯函数！

**只要传入参数相同，返回计算得到的下一个 state 就一定相同。没有特殊情况、没有副作用，没有 API 请求、没有变量修改，单纯执行计算。**

总结

到了最后，我想把 redux 中关键的名词列出来，你每个都知道是干啥的吗？

  * createStore

创建 store 对象，包含 getState, dispatch, subscribe, replaceReducer

  * reducer

reducer 是一个计划函数，接收旧的 state 和 action，生成新的 state

  * action

action 是一个对象，必须包含 type 字段

  * dispatch

`dispatch( action )` 触发 action，生成新的 state

  * subscribe

实现订阅功能，每次触发 dispatch 的时候，会执行订阅函数

  * combineReducers

多 reducer 合并成一个 reducer

  * replaceReducer

替换 reducer 函数

  * middleware

扩展 dispatch 函数！

你再看 redux 流程图，是不是大彻大悟了？

[![redux 流程图](https://user-images.githubusercontent.com/12526493/48312444-8ff2e100-e5e9-11e8-844a-48ffd9933265.png)](<https://user-images.githubusercontent.com/12526493/48312444-8ff2e100-e5e9-11e8-844a-48ffd9933265.png>)

(redux 流程图)
