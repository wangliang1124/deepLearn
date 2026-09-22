## Provider
React通过Context属性，可以将属性(props)直接给子孙component，无须通过props层层传递，Provider 的作用就是把 store 传递到子孙组件

```js
export default class Provider extends Component {
    getChildContext() {
        // 将其声明为 context 的属性之一
        return { store: this.store };
    }

    constructor(props, context) {
        super(props, context);
        // 接收 redux 的 store 作为 props
        this.store = props.store;
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

## connect

函数签名: connect([mapStateToProps], [mapDispatchToProps], [mergeProps], [options])。

### mapStateToProps(state, ownProps) : stateProps

这个函数允许我们将 store 中的数据作为 props 绑定到组件上。

```js
const mapStateToProps = state => {
    return {
        count: state.count,
    };
};
```

你不必将 state 中的数据原封不动地传入组件，可以根据 state 中的数据，动态地输出组件需要的（最小）属性

```js
const mapStateToProps = state => {
    return {
        greaterThanFive: state.count > 5,
    };
};
```

函数的第二个参数 ownProps ，是 MyComp 自己的 props 。有的时候， ownProps 也会对其产生影响。比如，当你在 store 中维护了一个用户列表，而你的组件 MyComp 只关心一个用户（通过 props 中的 userId 体现）。

```js
const mapStateToProps = (state, ownProps) => {
    // state 是 {userList: [{id: 0, name: '王二'}]}
    return {
        user: _.find(state.userList, { id: ownProps.userId }),
    };
};
```

### mapDispatchToProps(dispatch, ownProps): dispatchProps

connect 的第二个参数是 mapDispatchToProps ，它的功能是，将 action 作为 props 绑定到 MyComp 上。
为了不让 MyComp 组件感知到 dispatch 的存在，我们需要将 increase 和 decrease 两个函数包装一下，使之成为直接可被调用的函数。

```js
const mapDispatchToProps = (dispatch, ownProps) => {
  return {
    increase: (...args) => dispatch(actions.increase(...args)),
    decrease: (...args) => dispatch(actions.decrease(...args))
  }
}

class MyComp extends Component {
  render(){
    const {count, increase, decrease} = this.props;
    return (<div>
      <div>计数：{this.props.count}次</div>
      <button onClick={increase}>增加</button>
      <button onClick={decrease}>减少</button>
    </div>)
  }
}

const Comp = connect(mapStateToProps， mapDispatchToProps)(MyComp);

```

Redux 本身提供了 bindActionCreators 函数，来将 action 包装成直接可被调用的函数。

```js
import { bindActionCreators } from "redux";

const mapDispatchToProps = (dispatch, ownProps) => {
    return bindActionCreators({
        increase: action.increase,
        decrease: action.decrease,
    });
};
```

不管是 stateProps 还是 dispatchProps ，都需要和 ownProps merge 之后才会被赋给 MyComp 。 connect 的第三个参数就是用来做这件事。通常情况下，你可以不传这个参数， connect 就会使用 Object.assign 替代该方法。

### connect源码

```js
export default function connect(mapStateToProps, mapDispatchToProps, mergeProps, options = {}) {
  return function wrapWithConnect(WrappedComponent) {
    class Connect extends Component {
      constructor(props, context) {
        // 从祖先Component处获得store
        this.store = props.store || context.store
        this.stateProps = computeStateProps(this.store, props)
        this.dispatchProps = computeDispatchProps(this.store, props)
        this.state = { storeState: null }
        // 对stateProps、dispatchProps、parentProps进行合并
        this.updateState()
      }
      shouldComponentUpdate(nextProps, nextState) {
        // 进行判断，当数据发生改变时，Component重新渲染
        if (propsChanged || mapStateProducedChange || dispatchPropsChanged) {
          this.updateState(nextProps)
            return true
          }
        }
        componentDidMount() {
          // 改变Component的state
          this.store.subscribe(() = {
            this.setState({
              storeState: this.store.getState()
            })
          })
        }
        render() {
          // 生成包裹组件Connect
          return (
            <WrappedComponent {...this.nextState} />
          )
        }
      }
      Connect.contextTypes = {
        store: storeShape
      }
      return Connect;
    }
  }
```
