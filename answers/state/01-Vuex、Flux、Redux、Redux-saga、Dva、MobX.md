# Vuex、Flux、Redux、Redux-saga、Dva、MobX

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://zhuanlan.zhihu.com/p/53599723>
> 对应题目：状态管理 第 1 题 · Vuex、Flux、Redux、Redux-saga、Dva、MobX
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

## 这篇文章试着聊明白这一堆看起来挺复杂的东西。在聊之前，大家要始终记得一句话：**一切前端概念，都是纸老虎** 。

不管是Vue，还是 React，都需要管理状态（state），比如组件之间都有**共享状态** 的需要。什么是共享状态？比如一个组件需要使用另一个组件的状态，或者一个组件需要改变另一个组件的状态，都是共享状态。

父子组件之间，兄弟组件之间共享状态，往往需要写很多没有必要的代码，比如把状态提升到父组件里，或者给兄弟组件写一个父组件，听听就觉得挺啰嗦。

如果不对状态进行有效的管理，状态在什么时候，由于什么原因，如何变化就会不受控制，就很难跟踪和测试了。如果没有经历过这方面的困扰，可以简单理解为**会搞得很乱就对了** 。

在软件开发里，有些通用的思想，比如隔离变化，约定优于配置等，隔离变化就是说做好抽象，把一些容易变化的地方找到共性，隔离出来，不要去影响其他的代码。约定优于配置就是很多东西我们不一定要写一大堆的配置，比如我们几个人约定，view 文件夹里只能放视图，不能放过滤器，过滤器必须放到 filter 文件夹里，那这就是一种约定，约定好之后，我们就不用写一大堆配置文件了，我们要找所有的视图，直接从 view 文件夹里找就行。

根据这些思想，对于状态管理的解决思路就是：**把组件之间需要共享的状态抽取出来，遵循特定的约定，统一来管理，让状态的变化可以预测** 。根据这个思路，产生了很多的模式和库，我们来挨个聊聊。

## Store 模式

最简单的处理就是把状态存到一个外部变量里面，比如：`this.$root.$data`，当然也可以是一个全局变量。但是这样有一个问题，就是数据改变后，不会留下变更过的记录，这样不利于调试。

所以我们稍微搞得复杂一点，用一个简单的 Store 模式：

    var store = {
      state: {
        message: 'Hello!'
      },
      setMessageAction (newValue) {
        // 发生改变记录点日志啥的
        this.state.message = newValue
      },
      clearMessageAction () {
        this.state.message = ''
      }
    }

store 的 state 来存数据，store 里面有一堆的 action，这些 action 来控制 state 的改变，也就是不直接去对 state 做改变，而是通过 action 来改变，因为都走 action，我们就可以知道到底改变（mutation）是如何被触发的，出现错误，也可以记录记录日志啥的。

![](https://picx.zhimg.com/v2-9f751fb87f2512d9e907f7e226d8e271_1440w.jpg)

不过这里没有限制组件里面不能修改 store 里面的 state，万一组件瞎胡修改，不通过 action，那我们也没法跟踪这些修改是怎么发生的。所以就需要**规定一下** ，组件不允许直接修改属于 store 实例的 state，**组件必须通过 action 来改变 state** ，也就是说，组件里面应该执行 action 来分发 (dispatch) 事件通知 store 去改变。这样约定的好处是，我们能够记录所有 store 中发生的 state 改变，同时实现能做到记录变更 (mutation)、保存状态快照、历史回滚/时光旅行的先进的调试工具。

这样进化了一下，一个简单的 Flux 架构就实现了。

## Flux

Flux其实是一种思想，就像MVC，MVVM之类的，他给出了一些基本概念，所有的框架都可以根据他的思想来做一些实现。

Flux把一个应用分成了4个部分： _View_ Action _Dispatcher_ Store

![](https://pic2.zhimg.com/v2-fb6a545f55dac505d0ded33fa2284bc5_1440w.jpg)

比如我们搞一个应用，显而易见，这个应用里面会有一堆的 View，这个 View 可以是Vue的，也可以是 React的，啥框架都行，啥技术都行。

View 肯定是要展示数据的，所谓的数据，就是 Store，Store 很容易明白，就是存数据的地方。当然我们可以把 Store 都放到一起，也可以分开来放，所以就有一堆的 Store。但是这些 View 都有一个特点，就是 Store 变了得跟着变。

View 怎么跟着变呢？一般 Store 一旦发生改变，都会往外面发送一个事件，比如 change，通知所有的订阅者。View 通过订阅也好，监听也好，不同的框架有不同的技术，反正 Store 变了，View 就会变。

View 不是光用来看的，一般都会有用户操作，用户点个按钮，改个表单啥的，就需要修改 Store。Flux 要求，View 要想修改 Store，必须经过一套流程，有点像我们刚才 Store 模式里面说的那样。视图先要告诉 Dispatcher，让 Dispatcher dispatch 一个 action，Dispatcher 就像是个中转站，收到 View 发出的 action，然后转发给 Store。比如新建一个用户，View 会发出一个叫 addUser 的 action 通过 Dispatcher 来转发，Dispatcher 会把 addUser 这个 action 发给所有的 store，store 就会触发 addUser 这个 action，来更新数据。数据一更新，那么 View 也就跟着更新了。

这个过程有几个需要注意的点： _Dispatcher 的作用是接收**所有** 的 Action，然后发给**所有** 的 Store。这里的 Action 可能是 View 触发的，也有可能是其他地方触发的，比如测试用例。转发的话也不是转发给某个 Store，而是所有 Store。 _ Store 的改变只能通过 Action，不能通过其他方式。也就是说 Store 不应该有公开的 Setter，所有 Setter 都应该是私有的，只能有公开的 Getter。具体 Action 的处理逻辑一般放在 Store 里。

听听描述看看图，可以发现，Flux的最大特点就是数据都是**单向流动** 的。

## Redux

Flux 有一些缺点（特点），比如一个应用可以拥有多个 Store，多个Store之间可能有依赖关系；Store 封装了数据还有处理数据的逻辑。

所以大家在使用的时候，一般会用 Redux，他和 Flux 思想比较类似，也有差别。

![](https://picx.zhimg.com/v2-9e7e7d6b492706746ba19845bd559963_1440w.jpg)

## Store

Redux 里面只有一个 Store，整个应用的数据都在这个大 Store 里面。Store 的 State 不能直接修改，每次只能返回一个新的 State。Redux 整了一个 createStore 函数来生成 Store。

    import { createStore } from 'redux';
    const store = createStore(fn);

Store 允许使用 store.subscribe 方法设置监听函数，一旦 State 发生变化，就自动执行这个函数。这样不管 View 是用什么实现的，只要把 View 的更新函数 subscribe 一下，就可以实现 State 变化之后，View 自动渲染了。比如在 React 里，把组件的render方法或setState方法订阅进去就行。

## Action

和 Flux 一样，Redux 里面也有 Action，Action 就是 View 发出的通知，告诉 Store State 要改变。Action 必须有一个 type 属性，代表 Action 的名称，其他可以设置一堆属性，作为参数供 State 变更时参考。

    const action = {
      type: 'ADD_TODO',
      payload: 'Learn Redux'
    };

Redux 可以用 Action Creator 批量来生成一些 Action。

## Reducer

Redux 没有 Dispatcher 的概念，Store 里面已经集成了 dispatch 方法。store.dispatch()是 View 发出 Action 的唯一方法。

    import { createStore } from 'redux';
    const store = createStore(fn);

    store.dispatch({
      type: 'ADD_TODO',
      payload: 'Learn Redux'
    });

Redux 用一个叫做 Reducer 的**纯函数** 来处理事件。Store 收到 Action 以后，必须给出一个**新的 State** （就是刚才说的Store 的 State 不能直接修改，每次只能返回一个新的 State**）** ，这样 View 才会发生变化。这种 State 的计算过程就叫做 Reducer。

什么是纯函数呢，就是说没有任何的副作用，比如这样一个函数：

    function getAge(user) {
      user.age = user.age + 1;
      return user.age;
    }

这个函数就有副作用，每一次相同的输入，都可能导致不同的输出，而且还会影响输入 user 的值，再比如：

    let b = 10;
    function compare(a) {
      return a >= b;
    }

这个函数也有副作用，就是依赖外部的环境，b 在别处被改变了，返回值对于相同的 a 就有可能不一样。

而 Reducer 是一个纯函数，对于相同的输入，永远都只会有相同的输出，不会影响外部的变量，也不会被外部变量影响，不得改写参数。它的作用大概就是这样，根据应用的状态和当前的 action 推导出新的 state：

    (previousState, action) => newState

类比 Flux，Flux 有些像：

为什么叫做 Reducer 呢？reduce 是一个函数式编程的概念，经常和 map 放在一起说，简单来说，map 就是映射，reduce 就是归纳。映射就是把一个列表按照一定规则映射成另一个列表，而 reduce 是把一个列表通过一定规则进行合并，也可以理解为对初始值进行一系列的操作，返回一个新的值。

比如 Array 就有一个方法叫 reduce，Array.prototype.reduce(reducer, ?initialValue)，把 Array 整吧整吧弄成一个 newValue。

    const array1 = [1, 2, 3, 4];
    const reducer = (accumulator, currentValue) => accumulator + currentValue;

    // 1 + 2 + 3 + 4
    console.log(array1.reduce(reducer));
    // expected output: 10

    // 5 + 1 + 2 + 3 + 4
    console.log(array1.reduce(reducer, 5));
    // expected output: 15

看起来和 Redux 的 Reducer 是不是好像好像，Redux 的 Reducer 就是 reduce 一个列表（action的列表）和一个 initialValue（初始的 State）到一个新的 value（新的 State）。

把上面的概念连起来，举个例子：

下面的代码声明了 reducer：

    const defaultState = 0;
    const reducer = (state = defaultState, action) => {
      switch (action.type) {
        case 'ADD':
          return state + action.payload;
        default: 
          return state;
      }
    };

createStore接受 Reducer 作为参数，生成一个新的 Store。以后每当store.dispatch发送过来一个新的 Action，就会自动调用 Reducer，得到新的 State。

    import { createStore } from 'redux';
    const store = createStore(reducer);

createStore 内部干了什么事儿呢？通过一个简单的 createStore 的实现，可以了解大概的原理（可以略过不看）：

    const createStore = (reducer) => {
      let state;
      let listeners = [];

      const getState = () => state;

      const dispatch = (action) => {
        state = reducer(state, action);
        listeners.forEach(listener => listener());
      };

      const subscribe = (listener) => {
        listeners.push(listener);
        return () => {
          listeners = listeners.filter(l => l !== listener);
        }
      };

      dispatch({});

      return { getState, dispatch, subscribe };
    };

Redux 有很多的 Reducer，对于大型应用来说，State 必然十分庞大，导致 Reducer 函数也十分庞大，所以需要做拆分。Redux 里每一个 Reducer 负责维护 State 树里面的一部分数据，多个 Reducer 可以通过 combineReducers 方法合成一个根 Reducer，这个根 Reducer 负责维护整个 State。

    import { combineReducers } from 'redux';

    // 注意这种简写形式，State 的属性名必须与子 Reducer 同名
    const chatReducer = combineReducers({
      Reducer1,
      Reducer2,
      Reducer3
    })

combineReducers 干了什么事儿呢？通过简单的 combineReducers 的实现，可以了解大概的原理（可以略过不看）：

    const combineReducers = reducers => {
      return (state = {}, action) => {
        return Object.keys(reducers).reduce(
          (nextState, key) => {
            nextState[key] = reducers[key](state[key], action);
            return nextState;
          },
          {} 
        );
      };
    };

## 流程

![](https://picx.zhimg.com/v2-9e7e7d6b492706746ba19845bd559963_1440w.jpg)

再回顾一下刚才的流程图，尝试走一遍 Redux 流程：

1、用户通过 View 发出 Action：

2、然后 Store 自动调用 Reducer，并且传入两个参数：当前 State 和收到的 Action。 Reducer 会返回新的 State 。

    let nextState = xxxReducer(previousState, action);

3、State 一旦有变化，Store 就会调用监听函数。

    store.subscribe(listener);

4、listener可以通过 store.getState() 得到当前状态。如果使用的是 React，这时可以触发重新渲染 View。

    function listerner() {
      let newState = store.getState();
      component.setState(newState);   
    }

## 对比 Flux

和 Flux 比较一下：Flux 中 Store 是各自为战的，每个 Store 只对对应的 View 负责，每次更新都只通知对应的View：

![](https://pic1.zhimg.com/v2-4f3428e4dbb2e0c5b1988275b82da14e_1440w.jpg)

Redux 中各子 Reducer 都是由根 Reducer 统一管理的，每个子 Reducer 的变化都要经过根 Reducer 的整合：

![](https://picx.zhimg.com/v2-3eea040acf4cd03884ba3e903b936425_1440w.jpg)

简单来说，Redux有三大原则： _ 单一数据源：Flux 的数据源可以是多个。 _ State 是只读的：Flux 的 State 可以随便改。 * 使用纯函数来执行修改：Flux 执行修改的不一定是纯函数。

Redux 和 Flux 一样都是**单向数据流** 。

## 中间件

刚才说到的都是比较理想的同步状态。在实际项目中，一般都会有同步和异步操作，所以 Flux、Redux 之类的思想，最终都要落地到同步异步的处理中来。

在 Redux 中，同步的表现就是：Action 发出以后，Reducer 立即算出 State。那么异步的表现就是：Action 发出以后，过一段时间再执行 Reducer。

那怎么才能 Reducer 在异步操作结束后自动执行呢？Redux 引入了中间件 Middleware 的概念。

其实我们重新回顾一下刚才的流程，可以发现每一个步骤都很纯粹，都不太适合加入异步的操作，比如 Reducer，纯函数，肯定不能承担异步操作，那样会被外部IO干扰。Action呢，就是一个纯对象，放不了操作。那想来想去，只能在 View 里发送 Action 的时候，加上一些异步操作了。比如下面的代码，给原来的 dispatch 方法包裹了一层，加上了一些日志打印的功能：

    let next = store.dispatch;
    store.dispatch = function dispatchAndLog(action) {
      console.log('dispatching', action);
      next(action);
      console.log('next state', store.getState());
    }

既然能加日志打印，当然也能加入异步操作。所以中间件简单来说，就是对 store.dispatch 方法进行一些改造的函数。不展开说了，所以如果想详细了解中间件，可以[点这里](<https://link.zhihu.com/?target=https%3A//cn.redux.js.org/docs/advanced/Middleware.html>)。

Redux 提供了一个 applyMiddleware 方法来应用中间件：

    const store = createStore(
      reducer,
      applyMiddleware(thunk, promise, logger)
    );

这个方法主要就是把所有的中间件组成一个数组，依次执行。也就是说，任何被发送到 store 的 action 现在都会经过thunk，promise，logger 这几个中间件了。

## 处理异步

对于异步操作来说，有两个非常关键的时刻：发起请求的时刻，和接收到响应的时刻（可能成功，也可能失败或者超时），这两个时刻都可能会更改应用的 state。一般是这样一个过程：

  1. 请求开始时，dispatch 一个请求开始 Action，触发 State 更新为“正在请求”状态，View 重新渲染，比如展现个Loading啥的。
  2. 请求结束后，如果成功，dispatch 一个请求成功 Action，隐藏掉 Loading，把新的数据更新到 State；如果失败，dispatch 一个请求失败 Action，隐藏掉 Loading，给个失败提示。

显然，用 Redux 处理异步，可以自己写中间件来处理，当然大多数人会选择一些现成的支持异步处理的中间件。比如 [redux-thunk](<https://link.zhihu.com/?target=https%3A//github.com/gaearon/redux-thunk>) 或 [redux-promise](<https://link.zhihu.com/?target=https%3A//github.com/acdlite/redux-promise>) 。

## Redux-thunk

thunk 比较简单，没有做太多的封装，把大部分自主权交给了用户：

    const createFetchDataAction = function(id) {
        return function(dispatch, getState) {
            // 开始请求，dispatch 一个 FETCH_DATA_START action
            dispatch({
                type: FETCH_DATA_START, 
                payload: id
            })
            api.fetchData(id) 
                .then(response => {
                    // 请求成功，dispatch 一个 FETCH_DATA_SUCCESS action
                    dispatch({
                        type: FETCH_DATA_SUCCESS,
                        payload: response
                    })
                })
                .catch(error => {
                    // 请求失败，dispatch 一个 FETCH_DATA_FAILED action   
                    dispatch({
                        type: FETCH_DATA_FAILED,
                        payload: error
                    })
                }) 
        }
    }

    //reducer
    const reducer = function(oldState, action) {
        switch(action.type) {
        case FETCH_DATA_START : 
            // 处理 loading 等
        case FETCH_DATA_SUCCESS : 
            // 更新 store 等
        case FETCH_DATA_FAILED : 
            // 提示异常
        }
    }

缺点就是用户要写的代码有点多，可以看到上面的代码比较啰嗦，一个请求就要搞这么一套东西。

## Redux-promise

redus-promise 和 redux-thunk 的思想类似，只不过做了一些简化，成功失败手动 dispatch 被封装成自动了：

    const FETCH_DATA = 'FETCH_DATA'
    //action creator
    const getData = function(id) {
        return {
            type: FETCH_DATA,
            payload: api.fetchData(id) // 直接将 promise 作为 payload
        }
    }
    //reducer
    const reducer = function(oldState, action) {
        switch(action.type) {
        case FETCH_DATA: 
            if (action.status === 'success') {
                 // 更新 store 等处理
            } else {
                    // 提示异常
            }
        }
    }

刚才的什么 then、catch 之类的被中间件自行处理了，代码简单不少，不过要处理 Loading 啥的，还需要写额外的代码。

其实任何时候都是这样：**封装少，自由度高，但是代码就会变复杂；封装多，代码变简单了，但是自由度就会变差。** redux-thunk 和 redux-promise 刚好就是代表这两个面。

redux-thunk 和 redux-promise 的具体使用就不介绍了，这里只聊一下大概的思路。大部分简单的异步业务场景，redux-thunk 或者 redux-promise 都可以满足了。

* * *

上面说的 Flux 和 Redux，和具体的前端框架没有什么关系，只是思想和约定层面。下面就要和我们常用的 Vue 或 React 结合起来了：

## Vuex

Vuex 主要用于 Vue，和 Flux，Redux 的思想很类似。

![](https://pic3.zhimg.com/v2-1b21813cd1d621658fe7402f0af4b104_1440w.jpg)

## Store

每一个 Vuex 里面有一个全局的 Store，包含着应用中的状态 State，这个 State 只是需要在组件中共享的数据，不用放所有的 State，没必要。这个 State 是单一的，和 Redux 类似，所以，一个应用仅会包含一个 Store 实例。单一状态树的好处是能够直接地定位任一特定的状态片段，在调试的过程中也能轻易地取得整个当前应用状态的快照。

Vuex通过 store 选项，把 state 注入到了整个应用中，这样子组件能通过 this.\$store 访问到 state 了。

    const app = new Vue({
      el: '#app',
      // 把 store 对象提供给 “store” 选项，这可以把 store 的实例注入所有的子组件
      store,
      components: { Counter },
      template: `
        <div class="app">
          <counter></counter>
        </div>
      `
    })
    const Counter = {
      template: `<div>{{ count }}</div>`,
      computed: {
        count () {
          return this.$store.state.count
        }
      }
    }

State 改变，View 就会跟着改变，这个改变利用的是 Vue 的响应式机制。

## Mutation

显而易见，State 不能直接改，需要通过一个约定的方式，这个方式在 Vuex 里面叫做 mutation，更改 Vuex 的 store 中的状态的唯一方法是提交 mutation。Vuex 中的 mutation 非常类似于事件：每个 mutation 都有一个字符串的 事件类型 (type) 和 一个 回调函数 (handler)。

    const store = new Vuex.Store({
      state: {
        count: 1
      },
      mutations: {
        increment (state) {
          // 变更状态
          state.count++
        }
      }
    })

触发 mutation 事件的方式不是直接调用，比如 increment(state) 是不行的，而要通过 store.commit 方法：

    store.commit('increment')

注意：**mutation 都是同步事务** 。

mutation 有些类似 Redux 的 Reducer，但是 Vuex 不要求每次都搞一个新的 State，可以直接修改 State，这块儿又和 Flux 有些类似。具尤大的说法，Redux 强制的 immutability，在保证了每一次状态变化都能追踪的情况下强制的 immutability 带来的收益很有限，为了同构而设计的 API 很繁琐，必须依赖第三方库才能相对高效率地获得状态树的局部状态，这些都是 Redux 不足的地方，所以也被 Vuex 舍掉了。

到这里，其实可以感觉到 Flux、Redux、Vuex 三个的思想都差不多，在具体细节上有一些差异，**总的来说都是让 View 通过某种方式触发 Store 的事件或方法，Store 的事件或方法对 State 进行修改或返回一个新的 State，State 改变之后，View 发生响应式改变。**

## Action

到这里又该处理**异步** 这块儿了。mutation 是必须同步的，这个很好理解，和之前的 reducer 类似，不同步修改的话，会很难调试，不知道改变什么时候发生，也很难确定先后顺序，A、B两个 mutation，调用顺序可能是 A -> B，但是最终改变 State 的结果可能是 B -> A。

对比Redux的中间件，Vuex 加入了 Action 这个东西来处理异步，Vuex的想法是把同步和异步拆分开，异步操作想咋搞咋搞，但是不要干扰了同步操作。View 通过 store.dispatch('increment') 来触发某个 Action，Action 里面不管执行多少异步操作，完事之后都通过 store.commit('increment') 来触发 mutation，一个 Action 里面可以触发多个 mutation。所以 Vuex 的Action 类似于一个灵活好用的中间件。

Vuex 把同步和异步操作通过 mutation 和 Action 来分开处理，是一种方式。但不代表是唯一的方式，还有很多方式，比如就不用 Action，而是在应用内部调用异步请求，请求完毕直接 commit mutation，当然也可以。

Vuex 还引入了 Getter，这个可有可无，只不过是方便计算属性的复用。

Vuex 单一状态树并不影响模块化，把 State 拆了，最后组合在一起就行。Vuex 引入了 Module 的概念，每个 Module 有自己的 state、mutation、action、getter，其实就是把一个大的 Store 拆开。

总的来看，Vuex 的方式比较清晰，适合 Vue 的思想，在实际开发中也比较方便。

## 对比Redux

Redux： view——>actions——>reducer——>state变化——>view变化（同步异步一样）

Vuex： view——>commit——>mutations——>state变化——>view变化（同步操作） view——>dispatch——>actions——>mutations——>state变化——>view变化（异步操作）

## React-redux

Redux 和 Flux 类似，只是一种思想或者规范，它和 React 之间没有关系。Redux 支持 React、Angular、Ember、jQuery 甚至纯 JavaScript。

但是因为 React 包含函数式的思想，也是单向数据流，和 Redux 很搭，所以一般都用 Redux 来进行状态管理。为了简单处理 Redux 和 React UI 的绑定，一般通过一个叫 react-redux 的库和 React 配合使用，这个是 react 官方出的（如果不用 react-redux，那么手动处理 Redux 和 UI 的绑定，需要写很多重复的代码，很容易出错，而且有很多 UI 渲染逻辑的优化不一定能处理好）。

Redux将React组件分为容器型组件和展示型组件，容器型组件一般通过connect函数生成，它订阅了全局状态的变化，通过mapStateToProps函数，可以对全局状态进行过滤，而展示型组件不直接从global state获取数据，其数据来源于父组件。

![](https://pic4.zhimg.com/v2-6c15a43f784be592052aff8e9f495643_1440w.jpg)

如果一个组件既需要UI呈现，又需要业务逻辑处理，那就得拆，拆成一个容器组件包着一个展示组件。

因为 react-redux 只是 redux 和 react 结合的一种实现，除了刚才说的组件拆分，并没有什么新奇的东西，所以只拿一个简单TODO项目的部分代码来举例：

入口文件 index.js，把 redux 的相关 store、reducer 通过 Provider 注册到 App 里面，这样子组件就可以拿到 store 了。

    import React from 'react'
    import { render } from 'react-dom'
    import { Provider } from 'react-redux'
    import { createStore } from 'redux'
    import rootReducer from './reducers'
    import App from './components/App'

    const store = createStore(rootReducer)

    render(
      <Provider store={store}>
        <App />
      </Provider>,
      document.getElementById('root')
    )

actions/index.js，创建 Action：

    let nextTodoId = 0
    export const addTodo = text => ({
      type: 'ADD_TODO',
      id: nextTodoId++,
      text
    })

    export const setVisibilityFilter = filter => ({
      type: 'SET_VISIBILITY_FILTER',
      filter
    })

    export const toggleTodo = id => ({
      type: 'TOGGLE_TODO',
      id
    })

    export const VisibilityFilters = {
      SHOW_ALL: 'SHOW_ALL',
      SHOW_COMPLETED: 'SHOW_COMPLETED',
      SHOW_ACTIVE: 'SHOW_ACTIVE'
    }

reducers/todos.js，创建 Reducers：

    const todos = (state = [], action) => {
      switch (action.type) {
        case 'ADD_TODO':
          return [
            ...state,
            {
              id: action.id,
              text: action.text,
              completed: false
            }
          ]
        case 'TOGGLE_TODO':
          return state.map(todo =>
            todo.id === action.id ? { ...todo, completed: !todo.completed } : todo
          )
        default:
          return state
      }
    }

    export default todos

reducers/index.js，把所有的 Reducers 绑定到一起：

    import { combineReducers } from 'redux'
    import todos from './todos'
    import visibilityFilter from './visibilityFilter'

    export default combineReducers({
      todos,
      visibilityFilter,
      ...
    })

containers/VisibleTodoList.js，容器组件，connect 负责连接React组件和Redux Store：

    import { connect } from 'react-redux'
    import { toggleTodo } from '../actions'
    import TodoList from '../components/TodoList'

    const getVisibleTodos = (todos, filter) => {
      switch (filter) {
        case 'SHOW_COMPLETED':
          return todos.filter(t => t.completed)
        case 'SHOW_ACTIVE':
          return todos.filter(t => !t.completed)
        case 'SHOW_ALL':
        default:
          return todos
      }
    }

    // mapStateToProps 函数指定如何把当前 Redux store state 映射到展示组件的 props 中
    const mapStateToProps = state => ({
      todos: getVisibleTodos(state.todos, state.visibilityFilter)
    })

    // mapDispatchToProps 方法接收 dispatch() 方法并返回期望注入到展示组件的 props 中的回调方法。
    const mapDispatchToProps = dispatch => ({
      toggleTodo: id => dispatch(toggleTodo(id))
    })

    export default connect(
      mapStateToProps,
      mapDispatchToProps
    )(TodoList)

简单来说，react-redux 就是多了个 connect 方法连接容器组件和UI组件，这里的“连接”就是一种映射： _mapStateToProps 把容器组件的 state 映射到 UI组件的 props _ mapDispatchToProps 把UI组件的事件映射到 dispatch 方法

## Redux-saga

刚才介绍了两个Redux 处理异步的中间件 redux-thunk 和 redux-promise，当然 redux 的异步中间件还有很多，他们可以处理大部分场景，这些中间件的思想基本上都是把异步请求部分放在了 action creator 中，理解起来比较简单。

redux-saga 采用了另外一种思路，它没有把异步操作放在 action creator 中，也没有去处理 reductor，而是把所有的异步操作看成“线程”，可以通过普通的action去触发它，当操作完成时也会触发action作为输出。saga 的意思本来就是一连串的事件。

redux-saga 把异步获取数据这类的操作都叫做副作用（Side Effect），它的目标就是把这些副作用管理好，让他们执行更高效，测试更简单，在处理故障时更容易。

在聊 redux-saga 之前，需要熟悉一些预备知识，那就是 ES6 的 [Generator](<https://link.zhihu.com/?target=http%3A//es6.ruanyifeng.com/%23docs/generator>)。

如果从没接触过 Generator 的话，看着下面的代码，给你个1分钟傻瓜式速成，函数加个星号就是 Generator 函数了，Generator 就是个骂街生成器，Generator 函数里可以写一堆 yield 关键字，可以记成“丫的”，Generator 函数执行的时候，啥都不干，就等着调用 next 方法，按照顺序把标记为“丫的”的地方一个一个拎出来骂（遍历执行），骂到最后没有“丫的”标记了，就返回最后的return值，然后标记为 done: true，也就是骂完了（上面只是帮助初学者记忆，别喷~）。

    function* helloWorldGenerator() {
      yield 'hello';
      yield 'world';
      return 'ending';
    }

    var hw = helloWorldGenerator();

    hw.next() // 先把 'hello' 拎出来，done: false 代表还没骂完
    // { value: 'hello', done: false } next() 方法有固定的格式，value 是返回值，done 代表是否遍历结束

    hw.next() // 再把 'world' 拎出来，done: false 代表还没骂完
    // { value: 'world', done: false }

    hw.next() // 没有 yield 了，就把最后的 return 'ending' 拎出来，done: true 代表骂完了
    // { value: 'ending', done: true }

    hw.next() // 没有 yield，也没有 return 了，真的骂完了，只能挤出来一个 undefined 了，done: true 代表骂完了
    // { value: undefined, done: true }

这样搞有啥好处呢？我们发现 Generator 函数的很多代码可以被延缓执行，也就是具备了暂停和记忆的功能：遇到yield表达式，就暂停执行后面的操作，并将紧跟在yield后面的那个表达式的值，作为返回的对象的value属性值，等着下一次调用next方法时，再继续往下执行。用 Generator 来写异步代码，大概长这样：

    function* gen(){
      var url = 'https://api.github.com/users/github';
      var jsonData = yield fetch(url);
      console.log(jsonData);
    }

    var g = gen();
    var result = g.next(); 
    // 这里的result是 { value: fetch('https://api.github.com/users/github'), done: true }

    // fetch(url) 是一个 Promise，所以需要 then 来执行下一步
    result.value.then(function(data){
      return data.json();
    }).then(function(data){
      // 获取到 json data，然后作为参数调用 next，相当于把 data 传给了 jsonData，然后执行 console.log(jsonData);
      g.next(data);
    });

再回到 redux-saga 来，可以把 saga 想象成开了一个以最快速度不断地调用 next 方法并尝试获取所有 yield 表达式值的线程。举个例子：

    // saga.js
    import { take, put } from 'redux-saga/effects'

    function* mySaga(){ 
        // 阻塞: take方法就是等待 USER_INTERACTED_WITH_UI_ACTION 这个 action 执行
        yield take(USER_INTERACTED_WITH_UI_ACTION);
        // 阻塞: put方法将同步发起一个 action
        yield put(SHOW_LOADING_ACTION, {isLoading: true});
        // 阻塞: 将等待 FetchFn 结束，等待返回的 Promise
        const data = yield call(FetchFn, 'https://my.server.com/getdata');
        // 阻塞: 将同步发起 action (使用刚才返回的 Promise.then)
        yield put(SHOW_DATA_ACTION, {data: data});
    }

这里用了好几个yield，简单理解，也就是每个 yield 都发起了阻塞，saga 会等待执行结果返回，再执行下一指令。也就是相当于take、put、call、put 这几个方法的调用变成了同步的，上面的全部完成返回了，才会执行下面的，类似于 await。

用了 saga，我们就可以很细粒度的控制各个副作用每一部的操作，可以把异步操作和同步发起 action 一起，随便的排列组合。saga 还提供 takeEvery、takeLatest 之类的辅助函数，来控制是否允许多个异步请求同时执行，尤其是 takeLatest，方便处理由于网络延迟造成的多次请求数据冲突或混乱的问题。

saga 看起来很复杂，主要原因可能是因为大家不熟悉 Generator 的语法，还有需要学习一堆新增的 API 。如果抛开这些记忆的东西，改造一下，再来看一下代码：

    function mySaga(){ 
        if (action.type === 'USER_INTERACTED_WITH_UI_ACTION') {
            store.dispatch({ type: 'SHOW_LOADING_ACTION', isLoading: true});
            const data = await Fetch('https://my.server.com/getdata');
            store.dispatch({ type: 'SHOW_DATA_ACTION', data: data});
        }
    }

上面的代码就很清晰了吧，全部都是同步的写法，无比顺畅，当然直接这样写是不支持的，所以那些 Generator 语法和API，无非就是做一些适配而已。

saga 还能很方便的并行执行异步任务，或者让两个异步任务竞争：

    // 并行执行，并等待所有的结果，类似 Promise.all 的行为
    const [users, repos] = yield [
      call(fetch, '/users'),
      call(fetch, '/repos')
    ]

    // 并行执行，哪个先完成返回哪个，剩下的就取消掉了
    const {posts, timeout} = yield race({
      posts: call(fetchApi, '/posts'),
      timeout: call(delay, 1000)
    })

saga 的每一步都可以做一些断言（assert）之类的，所以非常方便测试。而且很容易测试到不同的分支。

这里不讨论更多 saga 的细节，大家了解 saga 的思想就行，细节请看[文档](<https://link.zhihu.com/?target=https%3A//redux-saga-in-chinese.js.org/>)。

## 对比 Redux-thunk

![](https://pica.zhimg.com/v2-4ea53b364f195520bf7415e841e0c076_1440w.jpg)

比较一下 redux-thunk 和 redux-saga 的代码：

![](https://pic1.zhimg.com/v2-b41826e12eac0b6a812b49013fd7f140_1440w.jpg)

![](https://picx.zhimg.com/v2-f119e0001c4f680b93629a7f260149a5_1440w.jpg)

和 redux-thunk 等其他异步中间件对比来说，redux-saga 主要有下面几个特点： _异步数据获取的相关业务逻辑放在了单独的 saga.js 中，不再是掺杂在 action.js 或 component.js 中。_ dispatch 的参数是标准的 action，没有魔法。 _saga 代码采用类似同步的方式书写，代码变得更易读。_ 代码异常/请求失败 都可以直接通过 try/catch 语法直接捕获处理。 * 很容易测试，如果是 thunk 的 Promise，测试的话就需要不停的 mock 不同的数据。

其实 redux-saga 是用一些学习的复杂度，换来了代码的高可维护性，还是很值得在项目中使用的。

## Dva

[Dva](<https://link.zhihu.com/?target=https%3A//dvajs.com/>)是什么呢？官方的定义是：dva 首先是一个基于 redux 和 redux-saga 的数据流方案，然后为了简化开发体验，dva 还额外内置了 react-router 和 fetch，所以也可以理解为一个轻量级的应用框架。

简单理解，就是让使用 react-redux 和 redux-saga 编写的代码组织起来更合理，维护起来更方便。

之前我们聊了 redux、react-redux、redux-saga 之类的概念，大家肯定觉得头昏脑涨的，什么 action、reducer、saga 之类的，写一个功能要在这些js文件里面不停的切换。

dva 做的事情很简单，就是让这些东西可以写到一起，不用分开来写了。比如：

    app.model({
      // namespace - 对应 reducer 在 combine 到 rootReducer 时的 key 值
      namespace: 'products',
      // state - 对应 reducer 的 initialState
      state: {
        list: [],
        loading: false,
      },
      // subscription - 在 dom ready 后执行
      subscriptions: [
        function(dispatch) {
          dispatch({type: 'products/query'});
        },
      ],
      // effects - 对应 saga，并简化了使用
      effects: {
        ['products/query']: function*() {
          yield call(delay(800));
          yield put({
            type: 'products/query/success',
            payload: ['ant-tool', 'roof'],
          });
        },
      },
      // reducers - 就是传统的 reducers
      reducers: {
        ['products/query'](state) {
          return { ...state, loading: true, };
        },
        ['products/query/success'](state, { payload }) {
          return { ...state, loading: false, list: payload };
        },
      },
    });

以前书写的方式是创建 sagas/products.js, reducers/products.js 和 actions/products.js，然后把 saga、action、reducer 啥的分开来写，来回切换，现在写在一起就方便多了。

比如传统的 TODO 应用，用 redux + redux-saga 来表示结构，就是这样：

![](https://picx.zhimg.com/v2-65079a9bb232b8add7b452ca2411abd9_1440w.jpg)

saga 拦截 add 这个 action, 发起 http 请求, 如果请求成功, 则继续向 reducer 发一个 addTodoSuccess 的 action, 提示创建成功, 反之则发送 addTodoFail 的 action 即可。

如果使用 Dva，那么结构图如下：

![](https://pic4.zhimg.com/v2-b422760dc4344512045f08287e893591_1440w.jpg)

整个结构变化不大，最主要的就是把 store 及 saga 统一为一个 model 的概念（有点类似 Vuex 的 Module），写在了一个 js 文件里。增加了一个 Subscriptions, 用于收集其他来源的 action，比如快捷键操作。

    app.model({
      namespace: 'count',
      state: {
        record: 0,
        current: 0,
      },
      reducers: {
        add(state) {
          const newCurrent = state.current + 1;
          return { ...state,
            record: newCurrent > state.record ? newCurrent : state.record,
            current: newCurrent,
          };
        },
        minus(state) {
          return { ...state, current: state.current - 1};
        },
      },
      effects: {
        *add(action, { call, put }) {
          yield call(delay, 1000);
          yield put({ type: 'minus' });
        },
      },
      subscriptions: {
        keyboardWatcher({ dispatch }) {
          key('⌘+up, ctrl+up', () => { dispatch({type:'add'}) });
        },
      },
    });

之前我们说过约定优于配置的思想，Dva正式借鉴了这个思想。

## MobX

前面扯了这么多，其实还都是 Flux 体系的，都是单向数据流方案。接下来要说的 MobX，就和他们不太一样了。

我们先清空一下大脑，回到初心，什么是初心？就是**我们最初要解决的问题是什么？** 最初我们其实为了**解决应用状态管理的问题** ，不管是 Redux 还是 MobX，把状态管理好是前提。什么叫把状态管理好，简单来说就是：统一维护公共的应用状态，以统一并且可控的方式更新状态，状态更新后，View跟着更新。不管是什么思想，达成这个目标就ok。

Flux 体系的状态管理方式，只是一个选项，但并不代表是唯一的选项。MobX 就是另一个选项。

MobX背后的哲学很简单：**任何源自应用状态的东西都应该自动地获得。** 译成人话就是状态只要一变，其他用到状态的地方就都跟着自动变。

![](https://pic2.zhimg.com/v2-fe37245ce0be3d15fcc4afdbb6cc7e31_1440w.jpg)

看这篇文章的人，大概率会对面向对象的思想比较熟悉，而对函数式编程的思想略陌生。Flux 或者说 Redux 的思想主要就是函数式编程（FP）的思想，所以学习起来会觉得累一些。而 MobX 更接近于面向对象编程，它把 state 包装成可观察的对象，这个对象会驱动各种改变。什么是可观察？就是 MobX 老大哥在看着 state 呢。state 只要一改变，所有用到它的地方就都跟着改变了。这样整个 View 可以被 state 来驱动。

    const obj = observable({
        a: 1,
        b: 2
    })

    autoRun(() => {
        console.log(obj.a)
    })

    obj.b = 3 // 什么都没有发生
    obj.a = 2 // observe 函数的回调触发了，控制台输出：2

上面的obj，他的 obj.a 属性被使用了，那么只要 obj.a 属性一变，所有使用的地方都会被调用。autoRun 就是这个老大哥，他看着所有依赖 obj.a 的地方，也就是**收集** 所有对 obj.a 的**依赖** 。当 obj.a 改变时，老大哥就会触发所有依赖去更新。

MobX 允许有多个 store，而且这些 store 里的 state 可以直接修改，不用像 Redux 那样每次还返回个新的。这个有点像 Vuex，自由度更高，写的代码更少。不过它也会让代码不好维护。

MobX 和 Flux、Redux 一样，都是和具体的前端框架无关的，也就是说可以用于 React（mobx-react) 或者 Vue（mobx-vue)。一般来说，用到 React 比较常见，很少用于 Vue，因为 Vuex 本身就类似 MobX，很灵活。如果我们把 MobX 用于 React 或者 Vue，可以看到很多 setState() 和 [http://this.state.xxx](<https://link.zhihu.com/?target=http%3A//this.state.xxx>) = 这样的处理都可以省了。

还是和上面一样，只介绍思想。具体 MobX 的使用，可以看[这里](<https://link.zhihu.com/?target=https%3A//cn.mobx.js.org/>)。

## 对比 Redux

我们直观地上两坨实现计数器代码：

![](https://picx.zhimg.com/v2-d40d4dfcd279330c4ef49ef794f51f2f_1440w.gif)

Redux：

    import React, { Component } from 'react';
    import {
      createStore,
      bindActionCreators,
    } from 'redux';
    import { Provider, connect } from 'react-redux';

    // ①action types
    const COUNTER_ADD = 'counter_add';
    const COUNTER_DEC = 'counter_dec';

    const initialState = {a: 0};
    // ②reducers
    function reducers(state = initialState, action) {
      switch (action.type) {
      case COUNTER_ADD:
        return {...state, a: state.a+1};
      case COUNTER_DEC:
        return {...state, a: state.a-1};
      default:
        return state
      }
    }

    // ③action creator
    const incA = () => ({ type: COUNTER_ADD });
    const decA = () => ({ type: COUNTER_DEC });
    const Actions = {incA, decA};

    class Demo extends Component {
      render() {
        const { store, actions } = this.props;
        return (
          <div>
            <p>a = {store.a}</p>
            <p>
              <button className="ui-btn" onClick={actions.incA}>增加 a</button>
              <button className="ui-btn" onClick={actions.decA}>减少 a</button>
            </p>
          </div>
        );
      }
    }

    // ④将state、actions 映射到组件 props
    const mapStateToProps = state => ({store: state});
    const mapDispatchToProps = dispatch => ({
      // ⑤bindActionCreators 简化 dispatch
      actions: bindActionCreators(Actions, dispatch)
    })
    // ⑥connect产生容器组件
    const Root = connect(
      mapStateToProps,
      mapDispatchToProps
    )(Demo)

    const store = createStore(reducers)
    export default class App extends Component {
      render() {
        return (
          <Provider store={store}>
            <Root />
          </Provider>
        )
      }
    }

MobX：

    import React, { Component } from 'react';
    import { observable, action } from 'mobx';
    import { Provider, observer, inject } from 'mobx-react';

    // 定义数据结构
    class Store {
      // ① 使用 observable decorator 
      @observable a = 0;
    }

    // 定义对数据的操作
    class Actions {
      constructor({store}) {
        this.store = store;
      }
      // ② 使用 action decorator 
      @action
      incA = () => {
        this.store.a++;
      }
      @action
      decA = () => {
        this.store.a--;
      }
    }

    // ③实例化单一数据源
    const store = new Store();
    // ④实例化 actions，并且和 store 进行关联
    const actions = new Actions({store});

    // inject 向业务组件注入 store，actions，和 Provider 配合使用
    // ⑤ 使用 inject decorator 和 observer decorator
    @inject('store', 'actions')
    @observer
    class Demo extends Component {
      render() {
        const { store, actions } = this.props;
        return (
          <div>
            <p>a = {store.a}</p>
            <p>
              <button className="ui-btn" onClick={actions.incA}>增加 a</button>
              <button className="ui-btn" onClick={actions.decA}>减少 a</button>
            </p>
          </div>
        );
      }
    }

    class App extends Component {
      render() {
        // ⑥使用Provider 在被 inject 的子组件里，可以通过 props.store props.actions 访问
        return (
          <Provider store={store} actions={actions}>
            <Demo />
          </Provider>
        )
      }
    }

    export default App;

比较一下：

  * Redux 数据流流动很自然，可以充分利用时间回溯的特征，增强业务的可预测性；MobX 没有那么自然的数据流动，也没有时间回溯的能力，但是 View 更新很精确，粒度控制很细。
  * Redux 通过引入一些中间件来处理副作用；MobX 没有中间件，副作用的处理比较自由，比如依靠 autorunAsync 之类的方法。
  * Redux 的样板代码更多，看起来就像是我们要做顿饭，需要先买个调料盒装调料，再买个架子放刀叉。。。做一大堆准备工作，然后才开始炒菜；而 MobX 基本没啥多余代码，直接硬来，拿着炊具调料就开干，搞出来为止。

但其实 Redux 和 MobX 并没有孰优孰劣，Redux 比 Mobx 更多的样板代码，是因为特定的设计约束。如果项目比较小的话，使用 MobX 会比较灵活，但是大型项目，像 MobX 这样没有约束，没有最佳实践的方式，会造成代码很难维护，各有利弊。一般来说，小项目建议 MobX 就够了，大项目还是用 Redux 比较合适。

## 总结

时光荏苒，岁月如梭。每一个框架或者库只能陪你走一段路，最终都会逝去。留在你心中的，不是一条一条的语法规则，而是一个一个的思想，这些思想才是推动进步的源泉。

帅哥美女，如果你都看到这里了，那么不点个赞，你的良心过得去么？

## 参考链接
