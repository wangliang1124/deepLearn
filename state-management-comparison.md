## 1. Flux

Flux 的最大特点就是数据都是单向流动的

!['flux'](./assets/img/flux.png)

-   Dispatcher: 分发中心, 管理所有数据流向, 将 Action 派发到 Store
-   Store：存储状态、处理数据相关逻辑
-   Action: 动作，只是一个简单的对象，包含 actionType 和 payload
-   View: 页面/组件, 接收到 change 事件后，更新页面

### Dispatcher

```js
var Dispatcher = require("flux").Dispatcher;
var AppDispatcher = new Dispatcher();
var ListStore = require("../stores/ListStore");
// 注册回调函数
AppDispatcher.register(function(action) {
    switch (action.actionType) {
        case "ADD_NEW_ITEM":
            // Store 接收 payload， 处理数据
            ListStore.addNewItemHandler(action.text);
            // 同时发布事件
            ListStore.emitChange();
            break;
        default:
        // no op
    }
});
```

### Action

```js
// 引入 Dispatcher
var AppDispatcher = require("../dispatcher/AppDispatcher");
var ButtonActions = {
    addNewItem: function(text) {
        // 分发动作 payload 给所有注册回调
        AppDispatcher.dispatch({
            actionType: "ADD_NEW_ITEM",
            text: text,
        });
    },
};
```

### Store

```js
var EventEmitter = require("events").EventEmitter;

var ListStore = Object.assign({}, EventEmitter.prototype, {
    items: [],

    getAll: function() {
        return this.items;
    },

    addNewItemHandler: function(text) {
        this.items.push(text);
    },

    emitChange: function() {
        this.emit("change");
    },

    addChangeListener: function(callback) {
        this.on("change", callback);
    },

    removeChangeListener: function(callback) {
        this.removeListener("change", callback);
    },
});
```

### View

```js
    class MyButtonController {
        // ...
        createNewItem: function (event) {
            ButtonActions.addNewItem('new item');
        },
        render() {
            return <MyButton
                items={this.state.items}
                onClick={this.createNewItem}
            />
      }
    }
```

## Redux

Redux 是超越 Flux 的一次进化。

### 三个基本原则

-   整个应用只有唯一一个可信数据源，也就是只有一个 Store
-   State 只能通过触发 Action 来更改
-   State 的更改必须是纯函数，也就是每次更改总是返回一个新的 State，在 Redux 里这种函数称为 Reducer

### Store

Redux 没有 Dispatcher 的概念，但是 Store 里面集成了 dispatch 方法。store.dispatch()是 View 发出 Action 的唯一方法。

```js
import { createStore } from "redux";
import cartReducer from "./reducers/cart";

let store = createStore(cartReducer);
```

createStore 原理

```js
const createStore = reducer => {
    let state;
    let listeners = [];

    const getState = () => state;

    const dispatch = action => {
        state = reducer(state, action);
        listeners.forEach(listener => listener());
    };

    const subscribe = listener => {
        listeners.push(listener);
        return () => {
            listeners = listeners.filter(l => l !== listener);
        };
    };

    dispatch({});

    return { getState, dispatch, subscribe };
};
```

### View

```js
import store from "./store.js";

class App(){
    handleAdd = () => {
        store.dispatch(addToCart("Coffee 500gm", 1, 250));
    };

    render(){
        // ...
        <button onClick={this.handleAdd}>加入购入车</button>
    }
}
```

### Action

和 Flux 一样，Redux 里面也有 Action，Action 就是在 View 层触发的动作，告诉 Store State 要改变。

-   只是一个单纯的的对象

```js
const action = {
    type: "ADD_TO_CART",
    payload: {
        product: "milk 500ml",
        quantity: 1,
        unitCost: 47,
    },
};
```

-   一般来说，会使用纯函数 Action Creators 来生成 action，这样会有更大的灵活性

```js
export const ADD_TO_CART = "ADD_TO_CART";

function addToCart(product, quantity, unitCost) {
    return {
        type: ADD_TO_CART,
        payload: { product, quantity, unitCost },
    };
}
```

### Reducer

Reducer 是 pure function，不要在 reducer 里面做一些引入 side-effects 的事情，比如：

-   直接修改 state 参数对象
-   请求 API
-   调用不纯的函数，比如 Data.now() Math.random()

```js
const initialState = {
    cart: [
        {
            product: "bread 700g",
            quantity: 2,
            unitCost: 90,
        },
    ],
};

function(state = initialState, action) {
    switch (action.type) {
        case ADD_TO_CART: {
            return {
                ...state,
                cart: [...state.cart, action.payload],
            };
        }

        case UPDATE_CART: {
            return {
                ...state,
                cart: state.cart.map(item => (item.product === action.payload.product ? action.payload : item)),
            };
        }

        case DELETE_FROM_CART: {
            return {
                ...state,
                cart: state.cart.filter(item => item.product !== action.payload.product),
            };
        }

        default:
            return state;
    }
}
```

## Vuex

### Store

```js
const store = new Vuex.Store({
    state: {
        count: 0,
    },
    mutations: {
        increment(state) {
            state.count++;
        },
    },
    actions: {
        incrementAsync({ commit }) {
            setTimeout(() => {
                commit("increment");
            }, 1000);
        },
    },
});
```

### Mutation

-   更改 Vuex 的 store 中的状态的唯一方法是提交 mutation。
-   mutation 有些类似 Redux 的 Reducer，但是 Vuex 不要求每次都搞一个新的 State，可以直接修改 State

```js
store.commit({
    type: "increment",
    amount: 10,
});
```

### Action

-   Action 提交的是 mutation，而不是直接变更状态。
-   Action 可以包含任意异步操作。

```js
// 以对象形式分发
store.dispatch({
    type: "incrementAsync",
    amount: 10,
});
```

Vuex 把同步和异步操作通过 mutation 和 Action 来分开处理，是一种方式。但不代表是唯一的方式，还有很多方式，比如就不用 Action，而是在应用内部调用异步请求，请求完毕直接 commit mutation，当然也可以。

## MobX

### 对比 Redux

Redux
```js
import React, { Component } from "react";
import { createStore, bindActionCreators } from "redux";
import { Provider, connect } from "react-redux";

// ①action types
const COUNTER_ADD = "counter_add";
const COUNTER_DEC = "counter_dec";

const initialState = { a: 0 };
// ②reducers
function reducers(state = initialState, action) {
    switch (action.type) {
        case COUNTER_ADD:
            return { ...state, a: state.a + 1 };
        case COUNTER_DEC:
            return { ...state, a: state.a - 1 };
        default:
            return state;
    }
}

// ③action creator
const incA = () => ({ type: COUNTER_ADD });
const decA = () => ({ type: COUNTER_DEC });
const Actions = { incA, decA };

class Demo extends Component {
    render() {
        const { store, actions } = this.props;
        return (
            <div>
                <p>a = {store.a}</p>
                <p>
                    <button className="ui-btn" onClick={actions.incA}>
                        增加 a
                    </button>
                    <button className="ui-btn" onClick={actions.decA}>
                        减少 a
                    </button>
                </p>
            </div>
        );
    }
}

// ④将state、actions 映射到组件 props
const mapStateToProps = state => ({ store: state });
const mapDispatchToProps = dispatch => ({
    // ⑤bindActionCreators 简化 dispatch
    actions: bindActionCreators(Actions, dispatch),
});
// ⑥connect产生容器组件
const Root = connect(
    mapStateToProps,
    mapDispatchToProps,
)(Demo);

const store = createStore(reducers);
export default class App extends Component {
    render() {
        return (
            <Provider store={store}>
                <Root />
            </Provider>
        );
    }
}
```

Mobx
```js
import React, { Component } from "react";
import { observable, action } from "mobx";
import { Provider, observer, inject } from "mobx-react";

// 定义数据结构
class Store {
    // ① 使用 observable decorator
    @observable a = 0;
}

// 定义对数据的操作
class Actions {
    constructor({ store }) {
        this.store = store;
    }
    // ② 使用 action decorator
    @action
    incA = () => {
        this.store.a++;
    };
    @action
    decA = () => {
        this.store.a--;
    };
}

// ③实例化单一数据源
const store = new Store();
// ④实例化 actions，并且和 store 进行关联
const actions = new Actions({ store });

// inject 向业务组件注入 store，actions，和 Provider 配合使用
// ⑤ 使用 inject decorator 和 observer decorator
@inject("store", "actions")
@observer
class Demo extends Component {
    render() {
        const { store, actions } = this.props;
        return (
            <div>
                <p>a = {store.a}</p>
                <p>
                    <button className="ui-btn" onClick={actions.incA}>
                        增加 a
                    </button>
                    <button className="ui-btn" onClick={actions.decA}>
                        减少 a
                    </button>
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
        );
    }
}

export default App;
```

-   Redux 数据流流动很自然，可以充分利用时间回溯的特征，增强业务的可预测性；MobX 没有那么自然的数据流动，也没有时间回溯的能力，但是 View 更新很精确，粒度控制很细。
-   Redux 通过引入一些中间件来处理副作用；MobX 没有中间件，副作用的处理比较自由，比如依靠 autorunAsync 之类的方法。
-   Redux 的样板代码更多，看起来就像是我们要做顿饭，需要先买个调料盒装调料，再买个架子放刀叉。。。做一大堆准备工作，然后才开始炒菜；而 MobX 基本没啥多余代码，直接硬来，拿着炊具调料就开干，搞出来为止。
    但其实 Redux 和 MobX 并没有孰优孰劣，Redux 比 Mobx 更多的样板代码，是因为特定的设计约束。如果项目比较小的话，使用 MobX 会比较灵活，但是大型项目，像 MobX 这样没有约束，没有最佳实践的方式，会造成代码很难维护，各有利弊。一般来说，小项目建议 MobX 就够了，大项目还是用 Redux 比较合适。
