# React-Redux 原理

**（已过时）** 本文讲的是 react-redux v5 时代的 `Provider` + `connect` 实现，用来理解「store 怎么传下去」「组件怎么按需重渲染」这两个机制。但里面用到的 legacy Context API（`getChildContext` / `childContextTypes`）已在 React 19 中移除，`PropTypes` 也早已从 React 包里剥离。

现在写业务代码用 Hooks，不需要 `connect`：

```jsx
import { useSelector, useDispatch } from "react-redux";

function Counter() {
    const count = useSelector(state => state.count);
    const dispatch = useDispatch();
    return <button onClick={() => dispatch(increment())}>{count}</button>;
}
```

> **推荐** Redux Essentials 官方教程 https://redux.js.org/tutorials/essentials/part-1-overview-concepts

> Redux Toolkit 快速上手 https://redux-toolkit.js.org/tutorials/quick-start

> react-redux 仓库 https://github.com/reduxjs/react-redux
>
> （官网 react-redux.js.org 目前 TLS 证书异常，浏览器会拦截，暂用以上入口）

下面是原理部分。

## Provider

React 通过 Context，可以把数据直接给到子孙组件，无须通过 props 层层传递。`Provider` 的作用就是把 store 放进 Context，让下面的组件都能取到。

v5 的实现用的是 legacy Context：

```js
export default class Provider extends Component {
    constructor(props, context) {
        super(props, context);
        // 接收 redux 的 store 作为 props
        this.store = props.store;
    }

    getChildContext() {
        // 将 store 声明为 context 的属性之一
        return { store: this.store };
    }

    render() {
        return Children.only(this.props.children);
    }
}

Provider.propTypes = {
    store: storeShape.isRequired,
    children: PropTypes.element.isRequired,
};
Provider.childContextTypes = {
    store: storeShape.isRequired,
};
```

现在的等价写法是 `React.createContext()` 配合 `<Context.Provider value={store}>`，子组件用 `useContext` 取。

## connect

函数签名：`connect([mapStateToProps], [mapDispatchToProps], [mergeProps], [options])`。

### mapStateToProps(state, ownProps) : stateProps

这个函数把 store 中的数据作为 props 绑定到组件上。

```js
const mapStateToProps = state => {
    return {
        count: state.count,
    };
};
```

不必把 state 原封不动传入组件，可以根据 state 动态算出组件需要的（最小）属性：

```js
const mapStateToProps = state => {
    return {
        greaterThanFive: state.count > 5,
    };
};
```

第二个参数 `ownProps` 是组件自己的 props。有时 `ownProps` 也会影响取值，比如 store 里维护了一个用户列表，而组件只关心其中一个用户（由 props 中的 `userId` 指定）：

```js
const mapStateToProps = (state, ownProps) => {
    // state 是 { userList: [{ id: 0, name: "王二" }] }
    return {
        user: state.userList.find(item => item.id === ownProps.userId),
    };
};
```

### mapDispatchToProps(dispatch, ownProps) : dispatchProps

第二个参数 `mapDispatchToProps` 的功能是把 action 作为 props 绑定到组件上。为了不让组件感知到 `dispatch` 的存在，需要把 action creator 包装成可直接调用的函数。

**推荐**：用 Redux 自带的 `bindActionCreators`，省掉手写包装。注意它需要两个参数，第二个是 `dispatch`：

```js
import { bindActionCreators } from "redux";
import * as actions from "./actions";

const mapDispatchToProps = dispatch => {
    return bindActionCreators(
        {
            increase: actions.increase,
            decrease: actions.decrease,
        },
        dispatch, // 漏掉这个参数会导致返回的函数无法真正派发
    );
};
```

手写包装的等价写法，用来理解 `bindActionCreators` 做了什么：

```js
const mapDispatchToProps = dispatch => {
    return {
        increase: (...args) => dispatch(actions.increase(...args)),
        decrease: (...args) => dispatch(actions.decrease(...args)),
    };
};
```

绑定之后组件里直接当普通回调用：

```jsx
class MyComp extends Component {
    render() {
        const { count, increase, decrease } = this.props;
        return (
            <div>
                <div>计数：{count} 次</div>
                <button onClick={increase}>增加</button>
                <button onClick={decrease}>减少</button>
            </div>
        );
    }
}

const Comp = connect(mapStateToProps, mapDispatchToProps)(MyComp);
```

### mergeProps

不管是 `stateProps` 还是 `dispatchProps`，都要和 `ownProps` 合并之后才会赋给组件。`connect` 的第三个参数就是做这件事的。通常不用传，`connect` 会默认用 `Object.assign` 的效果合并（后者覆盖前者：`ownProps` < `stateProps` < `dispatchProps`）。

### connect 源码

简化后的骨架。要点是：`connect` 是个高阶组件工厂，返回的 `Connect` 组件订阅 store，在 store 变化时更新自己的 state 触发重渲染，并把算好的 props 透传给被包裹组件。

```jsx
export default function connect(mapStateToProps, mapDispatchToProps, mergeProps, options = {}) {
    return function wrapWithConnect(WrappedComponent) {
        class Connect extends Component {
            constructor(props, context) {
                super(props, context);
                // 从祖先组件处获得 store
                this.store = props.store || context.store;
                this.state = { storeState: this.store.getState() };
                this.updateProps();
            }

            componentDidMount() {
                // 订阅 store，变化时改自己的 state 以触发重渲染
                this.unsubscribe = this.store.subscribe(() => {
                    this.setState({ storeState: this.store.getState() });
                });
            }

            componentWillUnmount() {
                // 必须退订，否则组件卸载后仍被 store 持有，造成内存泄漏
                if (this.unsubscribe) this.unsubscribe();
            }

            shouldComponentUpdate(nextProps, nextState) {
                // 只有 props 或映射结果真的变了才重渲染，这是 connect 的性能关键
                return this.propsChanged(nextProps) || this.stateChanged(nextState);
            }

            updateProps() {
                const stateProps = mapStateToProps(this.store.getState(), this.props);
                const dispatchProps = mapDispatchToProps(this.store.dispatch, this.props);
                this.mergedProps = mergeProps
                    ? mergeProps(stateProps, dispatchProps, this.props)
                    : { ...this.props, ...stateProps, ...dispatchProps };
            }

            render() {
                this.updateProps();
                return <WrappedComponent {...this.mergedProps} />;
            }
        }

        Connect.contextTypes = {
            store: storeShape,
        };

        return Connect;
    };
}
```

真实实现比这复杂得多：做了浅比较缓存、订阅顺序管理（保证父组件先于子组件更新）、`options.pure` 开关等。现在的 v8/v9 内部改用 `useSyncExternalStore`，不再手写订阅。
