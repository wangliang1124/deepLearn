# React 高效渲染策略

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/fi3ework/blog/issues/15>
> 对应题目：React 第 4 题 · React 怎么做数据的检查和变化
> 抓取时间：2026-09-22

---

## 前言

> 本文基于 react 16.3- 版本，所讨论的都是老版本的生命周期函数。

React 作为一个视图框架，速度已经很快了，并且在 React16 新推出的 Fiber 架构中，通过时间切片及高优先级任务中断来尽快相应用户的操作。尽管如此，React 也并不能揣测出开发者真正的意图，如果开发者的代码没有遵循最佳实践，就容易造成性能上的负担。

## 高效渲染

React 在内部维护了一套虚拟 DOM（VDOM），在内部维护着一颗 VDOM 树，这颗 VDOM 树映射到浏览器真实的 DOM 树，React 通过更新 VDOM 树来对真实 DOM 更新，VDOM 是 plain object 所以很明显操作 VDOM 的开销要比操作真实 DOM 快得多，再加上 React 内部的 reconciler，React 会在 reconsilation 之后最小化的进行 VDOM 的更新，再 patch 到真实 DOM 上最终完成用户看得到的更新。  
但是 React 不是万能的，当我们更新一个组件时，整个 reconciliation 会经过如下阶段（并不是完整的，但是会经过）

    组件的 props/state 更改(开发者控制) -> shouldComponentUpdate（开发者控制）-> 计算 VDOM 的更新（React 的 diff 算法会计算出最小化的更新）-> 更新真实 DOM (React 控制)

这几个箭头，每个箭头都是 YES or NO，返回 NO 就会中断后面的流程。每一步都会带来开销，所以对不需要更新的元素，我们一定要尽早中断这个流程，作为开发者能控制的就是第一个和第二个箭头。即是否传递新的 props/state，和 shouldComponentUpdate 的返回值控制。

### shouldComponentUpdate

#### 手动控制

你应该为每个使用 class 声明的组件添加 shouldComponentUpdate，否则一旦接受新的 props/state 就可能进行不必要的 re-render。

#### pureComponent

如果你很清楚每次的 props 或 state 的都是一个指向新引用的对象，那么可以直接使用 PureComponent，PureComponent 已经实现了一套浅比较的（shallowCompare）的 shouldComponentUpdate 的规则。

在React里，shouldComponentUpdate 源码为：

    if (this._compositeType === CompositeTypes.PureClass) {
      shouldUpdate = !shallowEqual(prevProps, nextProps) || ! shallowEqual(inst.state, nextState);
    }

来看下 shallowEqual 的源码

    'use strict';

    const hasOwnProperty = Object.prototype.hasOwnProperty;

    /**
     * inlined Object.is polyfill to avoid requiring consumers ship their own
     * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
     */
    function is(x: mixed, y: mixed): boolean {
      // SameValue algorithm
      if (x === y) { // Steps 1-5, 7-10
        // Steps 6.b-6.e: +0 != -0
        // Added the nonzero y check to make Flow happy, but it is redundant
        return x !== 0 || y !== 0 || 1 / x === 1 / y;
      } else {
        // Step 6.a: NaN == NaN
        return x !== x && y !== y;
      }
    }

    /**
     * Performs equality by iterating through keys on an object and returning false
     * when any key has values which are not strictly equal between the arguments.
     * Returns true when the values of all keys are strictly equal.
     */
    function shallowEqual(objA: mixed, objB: mixed): boolean {
      if (is(objA, objB)) { // 如果 ===，返回 true
        return true;
      }

      if (typeof objA !== 'object' || objA === null ||
          typeof objB !== 'object' || objB === null) {
        return false;
      }

      const keysA = Object.keys(objA);
      const keysB = Object.keys(objB);

      if (keysA.length !== keysB.length) {
        return false;
      }

      // Test for A's keys different from B.
      for (let i = 0; i < keysA.length; i++) {
        if (
          !hasOwnProperty.call(objB, keysA[i]) || // A B 中包含相同元素且相等，函数也是直接用 === 来比较
          !is(objA[keysA[i]], objB[keysA[i]])
        ) {
          return false;
        }
      }

      return true;
    }

`shallowEqual` 会对两个对象的每个属性进行比较，如果是非引用类型，那么可以直接比较判断是否相等。如果是引用类型，则通过比较引用的地址进行严格比较（`===`）。  
当 props 和 state 是不可突变数据的时候，可以直接使用 PureComponent，PureComponent 非常适合配合 immutablejs 来做优化。

### stateless function

官方推荐使用 stateless component（以下简称 sc），对它的定义是这么写的

> This simplified component API is intended for components that are pure functions of their props.

sc 的表达式是一个纯函数，完全符合 `UI = f(state)` 的公式，纯函数意味着可预测（给定输入可以获得可预测的输出），这样我们在写代码及调试的时候能对组有更好的把握，如果需要引入副作用则请使用 class。

sc 一般被用来当作展示组件，这样做的好处有：

  * 没有 state，没有 ref，没有生命周期，React 还可以避免不必要的内存申请及检查，这意味着更高效的渲染，React 会直接调用 createElement 返回 VDOM
  * 更短，更少的样本代码可以提高组件的可读性
  * 由于 sc 不支持 state，会迫使开发者将逻辑组件与展示组件进一步分离
  * 可以作为 render prop 的 prop，或者完成 callback render
  * 更方便进行测试
  * 和外层的 container 配合，分离数据逻辑与 UI
  * 更小的 bundler，Babel 转码后的 rc 只有 6 行（见 Babel 转义图）

[![img](https://camo.githubusercontent.com/670bcba82343f4cb8fa8ff25f053c35bbfa80f9dc7edc948797c6ac6b763f4e1/68747470733a2f2f63646e2d696d616765732d312e6d656469756d2e636f6d2f6d61782f323030302f312a4e6e44466d6c765362393965556c50436f716b3951672e706e67)](<https://camo.githubusercontent.com/670bcba82343f4cb8fa8ff25f053c35bbfa80f9dc7edc948797c6ac6b763f4e1/68747470733a2f2f63646e2d696d616765732d312e6d656469756d2e636f6d2f6d61782f323030302f312a4e6e44466d6c765362393965556c50436f716b3951672e706e67>)

但是要注意，这并不意味着滥用 sc：

> **state should be managed by higher-level “container” components, or via Flux/Redux/etc**.

不要让 sc 直接暴露在数据逻辑中，sc 的父组件要完成对 sc 以下行为的控制：

第二点一般来说没有问题，因为 sc 的渲染的数据是外层的逻辑组件传入的，sc 只负责 view。

第一点一定要控制好，因为 sc 没有生命周期，只要传入新的 props/state 就会 re-render，而且这意味着，一旦 sc 的父组件更新，sc 就会 re-render。re-render 就会带来 VDOM的 diff，这会带来一笔开销（这比开销也可能会是更好的选择，也可能不是，见下文）。

#### stateless component vs PureComponent

sc 和 PureComponent 各有优缺点。

sc 的缺点：

  * 当 props 更新或父组件重新渲染就会 re-render

PureComponent 的缺点

  * 如果 shouldComponentUpdate 为 true，那么相当于多做了两次检查（SCU 一次，re-render 时 diff 一次）

> **shallowCompare 比 diffing 算法需要耗费更多的时间**

所以一个组件如果经常变更的话，那么 PureComponent 多带来的两次检查会让他**通常更慢** 。

> 使用这个经验法则：pure component适用于复杂的表单和表格，但它们通常会减慢简单元素（按钮、图标）的效率。

一般来说，sc 适用于小的组件（就索性让它做 diff，diff 的开销小，反正不变就不会改变真实 DOM）。PureComponent 适用于稍大一点的组件，diff 的代价是随着组件的增大而提升，shallowCompare 与组件无关的复杂度无关而是与 props 的数量挂钩，不同的组件和 props 的要根据实际情况来判断。

### 避免props不必要的更改

#### 不要在 render 中重新定义函数

> 无论是编写哪个阶段的 `render` 函数，请牢记一点：保证它的“纯粹”（pure）。怎样才算纯粹？最基本的一点是不要尝试在render里改变组件的状态。

很多人喜欢在 render 函数中子组件通过构造一个箭头函数来传递给子组件，但是这样有一个问题就是，每次都会声明一个新的箭头函数，因而每次声明的函数**都肯定是不同的** ，所以就会导致如果你用了 PureComponent 也无法阻止 re-render，如下：

    class Parent extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          count: 0
        };
      }

      onClick() {
        this.setState({
          count: this.state.count + 1
        });
      }

      render() {
        return (
          <div>
            {this.state.count}
            <Child onClick={() => {
                this.onClick();
              }}
            />
          </div>
        );
      }
    }

    class Child extends React.PureComponent {
      render() {
        console.log("Child re-render");
        return <button onClick={this.props.onClick}>add</button>;
      }
    }

解决方案：在 constructor 中 bind，甚至或者是闭包引用一个 `self = this` ，或者在类声明中直接定义实例属性**（推荐）**，都可以做到绑定 this。

#### 使用稳定的 key

作为 key 的键应该符合以下条件

> **唯一的** ： 元素的 key 在它的兄弟元素中应该是唯一的。没有必要拥有全局唯一的 key。
> 
> **稳定的** ： 元素的 key 不应随着时间，页面刷新或是元素重新排序而变。
> 
> **可预测的** ： 你可以在需要时拿到同样的 key，意思是 key 不应是随机生成的。

在渲染一个列表时最好不要用每个项的 index 去当做他的 key，因为如果其中有一个项被删除或移动，则整个 key 就失去了与原项的对应关系，加大了 diff 的开销。

> 通常，你应该依赖于数据库生成的 ID 如关系数据库的主键，Mongo 中的对象 ID。如果数据库 ID 不可用，你可以生成内容的哈希值来作为 key。关于哈希值的更多内容可以在[这里](<https://link.juejin.im/?target=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FHash_function>)阅读。

#### store 的设计

##### 范式化

多数情况下我们的应用是要配合 Redux 或者 MobX 使用的。拿 Redux 举例，Redux store 的组织是一门大学问，Redux 官方推荐将 store 组织得**扁平化** 和**范式化** ，所谓扁平化，就是整个 store 的嵌套关系不要太深，实体之下不再挂载实体，扁平化带来的好处是

> 当某些数据需要在不同的地方出现时，就会**存在必然重复** 。例如，可能存在很多 state 部分都要存储同一份“用户评论列表”，这样需要花费很多心思去保障多处“用户评论列表”数据状态一致，否则就会造成页面数据不同步的 Bug;
> 
> 嵌套深层的数据结构，会直接**造成你 reducers 编写复杂** 。比如，你想更新一个很深层次的数据片段，很容易代码就变得丑陋。具体可以参考我的这篇文章：[如何优雅安全地在深层数据结构中取值](<https://zhuanlan.zhihu.com/p/27748589>);
> 
> **造成负面的性能影响。**即便你使用了类似 immutable.js 这样的不可变数据类库，最大限度的想保障深层数据带来的性能压力，那你是否知道 immutable.js 采用的 “[Persistent data structure](<https://link.zhihu.com/?target=https%3A//en.wikipedia.org/wiki/Persistent_data_structure>)” 思路，更新节点会造成同一条链儿上的祖先节点的更新。更恐怖的是，也许这些都会关联到众多 React 组件的 re-render;

范式化是指尽量去除数据的冗余，因为这样会给**维护数据的一致性带来困难** ，就像官方推荐 state 记录尽可能少的数据，不应该存放计算得到的数据和 props 的副本，而是将他们直接在 render 中使用，这也是避免了维护数据一致性的困难，并且避免了相同数据满天飞不知道源头数据是哪个的尴尬。

##### state vs store

首先要明确，不要将所有的状态全部放在 store 中，其实再延伸一下可以延伸出 `render(){}` 中的变量，也就是 `store vs state vs render`，store 中应该存放异步获取的数据或者多个组件需要访问的数据等等，redux 官方文档中也有写什么数据应该放入 store 中。

>   * 应用中的其他部分需要用到这部分数据吗？
>   * 是否需要根据这部分原始数据创建衍生数据？
>   * 这部分相同的数据是否用于驱动多个组件？
>   * 你是否需要能够将数据恢复到某个特定的时间点（比如：在时间旅行调试的时候）？
>   * 是否需要缓存数据？（比如：直接使用已经存在的数据，而不是重新请求）
> 

而 store 中不应该保存 UI 的状态（除非符合上面的某一点，比如回退时页面的滚动位置）。UI 的状态应该被限定在 UI 的 state 中，随着组件的卸载而销毁。而 state 也应该用最少的数据表示尽可能多的信息。在 render 函数中，根据 state 去衍生其他的信息而不是将这样冗余的信息都存在 state 中。store 和 state 都应该尽可能的做到**熵最小** ，具体的可以看 [redux store取代react state合理吗？](<https://www.zhihu.com/question/271693121>)。而 render 中的变量应该尽可以去承担一个衍生数据的责任，这个过程是无副作用的，可以减少在 state 中产生冗余数据的情况。

#### 最小化变动

下面来看一个例子，一个 list 有 10000 个未标记的 Item，点击某一 Item 该 Item 就会变为已标记，再点击就会变为未标记。很简单对不对，我们采用 redux + react-redux 来实现。

##### navie list

store 中存储的 state 为

    {
        [{id:0, marked: false}, {id:1, marked: false}, ...]
    }

然后 App 组件里直接用 map 去渲染

    class App extends Component {
      render() {
        const { items, markItem } = this.props;
        return (
          <div className="main" style={{overflow: 'scroll', height: '600px'}}>
            {items.map(item =>
              <Item key={item.id} id={item.id} marked={item.marked} onClick={markItem} />
            )}
          </div>
        );
      }
    };

    function mapStateToProps(state) {
      return state;
    }

    export default connect(mapStateToProps, {markItem})(App);

每个条目的 onClick 对应的回调函数

    function itemsReducer(state = initial_state, action) {
      switch (action.type) {
      case 'MARK':
        return state.map((item) =>
          action.id === item.id ? {...item, marked: !item.marked } : item
        );
      default:
        return state;
      }
    }

每次点击时派发一个 action

    const markItem = (id) => ({type: 'MARK', id});

很简单对不对，在数量少时看不出任何问题，但是到了 10000 时就会暴露出性能问题，点击一个 Item，UI 的反应可以说慢到爆炸。

[![image](https://user-images.githubusercontent.com/12322740/39393234-57506faa-4af5-11e8-8838-f9ed660f86f3.png)](<https://user-images.githubusercontent.com/12322740/39393234-57506faa-4af5-11e8-8838-f9ed660f86f3.png>)

慢的原因就是 App 组件被更新，触发了 re-render，也可以发现，App[update] 下面是密密麻麻的 Item 的 re-render 耗时，fiber 已经将整个更新的过程切片，这样不会导致在 re-render 的过程中失去对界面的操控，但是真正的渲染依旧耗时很长。

问题就是每次点击派发 action 之后，reducer 都会返回一个新的 state，这个新的 state 会触发 connect 的 App 的 re-render，App 又重新渲染每个 Item，Item 直接 render，导致不必要的 reconciliation。

##### 用 shouldComponentUpdate 来避免重渲染

基于上上面的改进，那就对每个 Item 增加一个 `shouldComponentUpdate`，在每次更新来临的时候拒绝掉这次更新。

      shouldComponentUpdate(nextProps) {
        if (this.props["marked"] === nextProps["marked"]) {
          return false;
        }
        return true;
      }

速度快了一些：

[![image](https://user-images.githubusercontent.com/12322740/39393241-64506480-4af5-11e8-891e-faac9bf86d63.png)](<https://user-images.githubusercontent.com/12322740/39393241-64506480-4af5-11e8-891e-faac9bf86d63.png>)

但是，shouldComponentUpdate 也是有开销的的，密密麻麻的 shouldComponentUpdate 即使返回 false 也拖慢了整体的时间，而且本例中的 shouldComponentUpdate 相对来说并不复杂，如果遇到更复杂的 model 耗时将会更久。

##### 让未被修改的组件对改变无感知

继续改进，想一下最优解，当我们在更新一个 Item 时，如果其他未被修改的 Item 的 props 和 state 没有任何的改变，那么就完全不会经过他们的生命周期。

所以，这里要将数据和组件重新组合。为了避免父组件的 re-render，我们将每个 Item 和 redux store 直接连接，将 store 拆分为 ids 和 items，用 ids 给父组件完成 Item 初始化提供一些必要的信息，用 items 对 Item 进行初始化和更新。每次点击的时候 ids 不变，所以父组件不会 re-render，只更新对应的子组件。子组件的 reducer：

    function items(state = initial_state, action) {
      switch (action.type) {
      case 'MARK':
        const item = state[action.id];
        return {
          ...state,
          [action.id]: {...item, marked: !item.marked}
        };
      default:
        return state;
      }
    }

当某个 Item 被 mark 时，虽然返回了一个新的对象，但是 `…` 解构函数是浅拷贝，所以 items 数组中对象的引用不变，只有发生更新的那个对象是新的。这样就做到了只改变需要改变的 Item 的 props。

[![image](https://user-images.githubusercontent.com/12322740/39393248-6e039ae2-4af5-11e8-97f0-60ff4d1bd410.png)](<https://user-images.githubusercontent.com/12322740/39393248-6e039ae2-4af5-11e8-97f0-60ff4d1bd410.png>)

除了真正要更新的 Item，其他所有 Item 对这次点击都是无感知的，性能好了很多。

##### 范式化 store

但是 ids 和 items 中的 id 冗余了，如果后面还要再加上添加和删除的功能就要同时修改两个属性，如果 ids 只是用来初始化 App 的话就会一直在 store 中残留，还容易引起误会。所以，还是将 store 变回如下的组织：

    store:{
        items:[
            {id: 0, marked: false},
            {id: 1, marked: false},
    		...
        ]
    }

其他的处理的方式类似 better list 2，每次进行局部更新

但是要补全 App 的 shouldComponentUpdate，因为虽然是局部更新，但是 reducer 是一个纯函数，纯函数每次不修改原 state，返回一个新 state，所以只要手动控制一个 App 的 shouldComponentUpdate 即可，根据业务需要写即可，这里只是做个演示，就直接返回了 false，相当于 App 只是完成初始化的功能。

    shouldComponentUpdate() {
      return false
    }

来看一下跑分（误）

[![image](https://user-images.githubusercontent.com/12322740/39393251-7808e416-4af5-11e8-8a31-7feb609900cb.png)](<https://user-images.githubusercontent.com/12322740/39393251-7808e416-4af5-11e8-8a31-7feb609900cb.png>)

跑分依旧不错。

##### react-redux

这里在说一下 react-redux 的 HOC 触发更新的条件：

这里有两个问题：1. 在 react-redux 中，connect 出来的 HOC 是怎么感知 store 的变化的？2. 什么的变化会触发 HOC 的更新？

先来解决第一个问题：

react-redux 通过 Provider 提供的 context 上的 store，在内部向 store subscribe 了 onStateChange 事件

      trySubscribe() {
        if (!this.unsubscribe) {
          this.unsubscribe = this.parentSub
            ? this.parentSub.addNestedSub(this.onStateChange)
            : this.store.subscribe(this.onStateChange)

          this.listeners = createListenerCollection()
        }
      }

只要派发了 action，就会触发一次 onStateChange 事件，HOC 就能感知 store 的更新再根据 onStateChange 的结果决定是否要 update。再来看 onStateChange 的源码：

    onStateChange() {
        this.selector.run(this.props)

        if (!this.selector.shouldComponentUpdate) {
            this.notifyNestedSubs()
        } else {
            this.componentDidUpdate = this.notifyNestedSubsOnComponentDidUpdate
            this.setState(dummyState)
        }
    }

是由 run 这个是个方法来每次决定每一次的 shouldComponentUpdate

    function makeSelectorStateful(sourceSelector, store) {
      // wrap the selector in an object that tracks its results between runs.
      const selector = {
        run: function runComponentSelector(props) {
          try {
            const nextProps = sourceSelector(store.getState(), props)
            if (nextProps !== selector.props || selector.error) {
              selector.shouldComponentUpdate = true
              selector.props = nextProps
              selector.error = null
            }
          } catch (error) {
            selector.shouldComponentUpdate = true
            selector.error = error
          }
        }
      }

      return selector
    }

在这里，sourceSelector 我们就知道它是一个 selector 就好，后面会再去研究。也就是说，当 store 更新的通知到来，就会调用 sourceSelector 重新计算一次结果，与上次缓存的结果进行 `===` 比较。如果发现比较不相等，即需要更新，shouldComponent 置为 true，同时本次新计算出来的结果作为缓存，用来与下次更新进行比较判断是否要 update。

OK，下面来看 sourceSelector 到底 select 了出个什么东西用来判断是否更新：

    export default function finalPropsSelectorFactory(dispatch, {
      initMapStateToProps,
      initMapDispatchToProps,
      initMergeProps,
      ...options
    }) {
      const mapStateToProps = initMapStateToProps(dispatch, options)
      const mapDispatchToProps = initMapDispatchToProps(dispatch, options)
      const mergeProps = initMergeProps(dispatch, options)

      if (process.env.NODE_ENV !== 'production') {
        verifySubselectors(mapStateToProps, mapDispatchToProps, mergeProps, options.displayName)
      }

      const selectorFactory = options.pure
        ? pureFinalPropsSelectorFactory
        : impureFinalPropsSelectorFactory

      return selectorFactory(
        mapStateToProps,
        mapDispatchToProps,
        mergeProps,
        dispatch,
        options
      )
    }

函数中的 mapStateToProps 和 mapDispatchToProps 是通过两个 initxxxx 函数来生成的，options 中包含了用户传入的 mapXXXXToProps，我们拿 mapStateToProps 来说，在 connect 中

    const initMapStateToProps = match(mapStateToProps, mapStateToPropsFactories, 'mapStateToProps')

match 的作用就是将第一个参数依次放入第二个参数的每一项中（第二个参数是一个数组），返回第一个不为 undefined 的结果。

正常情况下是返回这个函数的结果：

    export function wrapMapToPropsFunc(mapToProps, methodName) {
      return function initProxySelector(dispatch, { displayName }) {
        const proxy = function mapToPropsProxy(stateOrDispatch, ownProps) {
          return proxy.dependsOnOwnProps
            ? proxy.mapToProps(stateOrDispatch, ownProps)
            : proxy.mapToProps(stateOrDispatch)
        }

        // allow detectFactoryAndVerify to get ownProps
        proxy.dependsOnOwnProps = true

        proxy.mapToProps = function detectFactoryAndVerify(stateOrDispatch, ownProps) {
          proxy.mapToProps = mapToProps
          proxy.dependsOnOwnProps = getDependsOnOwnProps(mapToProps)
          let props = proxy(stateOrDispatch, ownProps)

          if (typeof props === 'function') {
            proxy.mapToProps = props
            proxy.dependsOnOwnProps = getDependsOnOwnProps(props)
            props = proxy(stateOrDispatch, ownProps)
          }

          if (process.env.NODE_ENV !== 'production') 
            verifyPlainObject(props, displayName, methodName)

          return props
        }

        return proxy
      }
    }

这个函数其实作用不大，返回一个 initProxy，proxy 其实还是调用了用户定义的 mapStateToProps，但是对初始化有作用。我们可以把它理解成一个健全版本的 mapStateToProps。回到 finalPropsSelectorFactory，我们拿到了一个初始化过的 mapStateToProps，mapDispatchToProps 和 mergeProps，等下，mergeProps是什么？这个函数可以看做是我们合并的策略，新的 props 或者 mapXXX 传入时，通过这个策略去合并出要传给包裹的组件的 props。

这三个参数会一并传入 pureFinalPropsSelectorFactory

    export function pureFinalPropsSelectorFactory(
      mapStateToProps,
      mapDispatchToProps,
      mergeProps,
      dispatch,
      { areStatesEqual, areOwnPropsEqual, areStatePropsEqual }
    ) {
      let hasRunAtLeastOnce = false
      // 以下为缓存
      let state
      let ownProps
      let stateProps
      let dispatchProps
      let mergedProps

      // 界面初始化时的入口
      // 缓存 state, ownProps, stateProps, dispatchProps，mergedProps(同时也是我们要的结果)
      function handleFirstCall(firstState, firstOwnProps) {
        state = firstState
        ownProps = firstOwnProps
        stateProps = mapStateToProps(state, ownProps)
        dispatchProps = mapDispatchToProps(dispatch, ownProps)
        mergedProps = mergeProps(stateProps, dispatchProps, ownProps)
        hasRunAtLeastOnce = true
        return mergedProps
      }

      // 如果 store 和 props 都更新了
      function handleNewPropsAndNewState() {
        stateProps = mapStateToProps(state, ownProps)

        if (mapDispatchToProps.dependsOnOwnProps)
          dispatchProps = mapDispatchToProps(dispatch, ownProps)

        mergedProps = mergeProps(stateProps, dispatchProps, ownProps)
        return mergedProps
      }

      // 如果 props 更新了
      function handleNewProps() {
        if (mapStateToProps.dependsOnOwnProps)
          stateProps = mapStateToProps(state, ownProps)

        if (mapDispatchToProps.dependsOnOwnProps)
          dispatchProps = mapDispatchToProps(dispatch, ownProps)

        mergedProps = mergeProps(stateProps, dispatchProps, ownProps)
        return mergedProps
      }

      // 如果 store 更新了
      function handleNewState() {
        const nextStateProps = mapStateToProps(state, ownProps)
        const statePropsChanged = !areStatePropsEqual(nextStateProps, stateProps)
        stateProps = nextStateProps

        if (statePropsChanged)
          mergedProps = mergeProps(stateProps, dispatchProps, ownProps)

        return mergedProps
      }

      // 界面非初始化时的入口
      function handleSubsequentCalls(nextState, nextOwnProps) {
        const propsChanged = !areOwnPropsEqual(nextOwnProps, ownProps) // 被赋值为 shallowEqual
        const stateChanged = !areStatesEqual(nextState, state) // 被赋值为 shallowEqual
        state = nextState
        ownProps = nextOwnProps

        if (propsChanged && stateChanged) return handleNewPropsAndNewState() // props & store 都更新
        if (propsChanged) return handleNewProps() // props 更新
        if (stateChanged) return handleNewState() // store 更新
        return mergedProps // 如果 store 和 props 都没改变直接返回缓存
      }

      return function pureFinalPropsSelector(nextState, nextOwnProps) {
        return hasRunAtLeastOnce
          ? handleSubsequentCalls(nextState, nextOwnProps)
          : handleFirstCall(nextState, nextOwnProps)
      }
    }

这个函数根据不同的更新来计算新的需要 merge 的状态（在 connect 中我们一般是不传入 mergeProps 这个参数的，会调用默认的 mergeProps 充当）。

然后传入 mergeProps 来进行合并，来看 mergeProps 的合并策略：

    export function defaultMergeProps(stateProps, dispatchProps, ownProps) {
      return { ...ownProps, ...stateProps, ...dispatchProps }
    }

就是用解构操作符返回一个新对象。再返回上面的 pureFinalPropsSelectorFactory，这个函数中缓存了 state, ownProps, stateProps, dispatchProps，mergedProps，如果 store 和 props 都不更新的话，那么直接返回上次计算的 mergedProps，如果 props 改变了，那么重新计算 props 的部分，其他的部分用之前的缓存，（store 更新同理，哪部分不变就用之前的缓存，变的再重新计算）再通过解构操作符返回一个浅拷贝的新对象用来表明已更新。

所以到这里就已经清楚了：**当 store 更新到来时，会调用 mergeProps 将新的参数直接 shallowMerge，重新将 ownProps， mapDispatchToProps，mapStateToProps 经过缓存优化（1. 不计算没改变的值 2. 如果都没改变那么直接返回缓存的结果，什么都不计算）。之后作为 selector 的结果传出去，再通过一次缓存进行比较（上层的函数也要再判断一次 selector 的结果变没变），如果不相同那么再更新被包裹的组件。**

##### reselect

本次优化中并没有使用 reselect。reselect 的作用就是缓存上一次 selector 的结果，和下一次 selector 的结果进行对比，如果相同就直接拿出之前缓存的 state。一般是为了防止其他无关状态的修改影响影响当前界面对应的 state，导致重渲染。在本例中，state 逻辑较简单，不存在其他的业务逻辑修改的情况。但是使用 reselect 优化的思路是一样，reselect 在 data -> view 之间添加了一层缓存来避免不必要的 re-render，我们可以使用它来进行 selector 的定义，很适合配合 react-redux 的 connect 之后生成的监听 store 的 HOC 使用。

##### immutable

immutablejs 拥有持久化数据结构 + 结构共享的特点。immutable 能带来颇多好处：

  1. 相比普通深拷贝和浅拷贝，immutable 的“拷贝”不会造成 CPU 和内存的浪费

  2. 由于对象创建之后具有不可变性，我们不用担心它在其他地方被修改，足够安全。

  3. 便于 undo/redo，copy/paste。试想，不用 immutable 做时间旅行，那么需要将涉及回溯部分的 state 深拷贝下来然后用一个栈保存起来。

  4. 能够对深层嵌套的数据准确的修改而不修改任何其他任何对象。比如 [JS Bin1](<https://link.zhihu.com/?target=http%3A//jsbin.com/woroha/5/edit%3Fjs%2Coutput>) 中，

[![](https://camo.githubusercontent.com/b956a3e2e3ad69943198de934c8e268dde3d3543e381523aa75e9e8998300f76/68747470733a2f2f706963322e7a68696d672e636f6d2f38302f38613730376166663737623837346161633165303631616130623763363337325f68642e6a7067)](<https://camo.githubusercontent.com/b956a3e2e3ad69943198de934c8e268dde3d3543e381523aa75e9e8998300f76/68747470733a2f2f706963322e7a68696d672e636f6d2f38302f38613730376166663737623837346161633165303631616130623763363337325f68642e6a7067>)

由于 setState 是 shallowMerge（相当于解构操作符或者 `Object.assgn`），所以每次 setState 触发时 middle 会消失掉，如果要用原生 JS 来解决这个问题，可以这样：

         this.setState({
             user: {
                 school: [...this.state.user.school, high: test]
             }
         })

如果使用 immutable 的话，就：

         handleChangeSchool(e) {
             var v = e.target.value;
             this.setImmState(d => d.updateIn(['user','school', 'high'], ()=>v));
         }

安全的修改，不用担心修改了不该修改的对象的部分。

在性能方面来说，刚才的例子中我们使用解构操作符来完成新的 state 的生成：

    function items(state = initial_state, action) {
      switch (action.type) {
      case 'MARK':
        const item = state[action.id];
        return {
          ...state,
          [action.id]: {...item, marked: !item.marked}
        };
      default:
        return state;
      }
    }

解构操作符是浅拷贝，和 `Ojbect.assign` 类似，通过 `window.performance.now()` 来测试每次生成新的 state 的时间大约是 ~5ms，如果state 使用 immutable 来填充，经过测试一次不到 1ms。看似收益很小，但是 state 中的数据数量更多或者嵌套的结构更加复杂时性能的问题就会凸显出来，而且在结构更加复杂的时候，原生的操作也会变得更加复杂（一层一层的解构还要判断是否为 undefined 才能进入下一层），使用 immutable 会大大简化操作。还有，在使用 immutable 时对象的比较一般是 shallowCompare ，相比 deepCompare 要快得多。

但是 immutable 也不是没有代价的，immutable 由于共享解构，所以对某一项的修改会非常快，但是与原生 JS 的转化会花费较多时间（`fromJS` 和 `toJS`，因为要访问原生对象的每个节点并且生成字典树）。这就导致如果使用 immutable，那么最好都在 immutable 的数据结构中处理数据，如果非要转化为原生 JS，一定要找一个开销更少的出口。

但是 connect 出来的 HOC 的 shouldComponent 已近实现了，所以配合 immutable 时还需要 reselect 的缓存利用 `Immutable.is` 进行比较。

##### 反思

即使是 better list 3，页面更新也需要 200ms，在每个 Event(click) 的右上角都有一个小红三角，代表造成了帧率过低，性能低下的原因就是在浏览器及 React 中维护了过多的真实 DOM 和 VDOM，但实际上用户可见的视窗是有限的，只需要渲染视窗可见的 Item 即可，这就是长列表的问题范畴了，大家可以去了解一下，有各种不同的解决方案，比如 [react-virtualized](<https://github.com/bvaughn/react-virtualized>)。

## 性能检测

### ?rect_perf

React 官方文档里推荐的性能检测方法，是对 Chrome Devtool 的加强，可以将 Devtool 中 JS 部分的火焰图细分为组件各个声明周期的时间，在目前的开发模式下，不用输入 `?rect_perf` 也已经开启了这个功能，生产模式下的页面仍然需要加上这个命令。

官方已经介绍了使用方法，方法也很简单：

> Chrome浏览器内：
> 
>   1. 在项目地址栏内添加查询字符串 `?react_perf`（例如， `http://localhost:3000/?react_perf`）。
>   2. 打开Chrome开发工具**Performance** 标签页点击**Record**.
>   3. 执行你想要分析的动作。不要记录超过20s，不然Chrome可能会挂起。
>   4. 停止记录。
>   5. React事件将会被归类在 **User Timing** 标签下。
> 

还有额外的几点

  1. 一般来说移动设备的 CPU 性能是要弱于 PC 的，所以为了模拟移动设备，需要将 PC 的性能手动节流，在 Performance 的 CPU 那里，官方说如果用开了 4X 的节流那么你手上的 Macbook 就会弱的像摩托罗拉 G4，但是这年代还去哪找摩托罗拉 G4 啊…，而且现在手机的单核 CPU 性能都已经很高了，所以我做的以下测试均未节流。
  2. 启用 DevTool 的 Performance 进行性能分析会导致页面的执行速度变慢。

放上一个用来测试的页面：[TODOMVC](<https://building.calibreapp.com/debugging-react-performance-with-react-16-and-chrome-devtools-c90698a522ad>)，这个页面故意加入了会导致性能问题的代码，我们来通过 Devtool 找出是哪段代码的问题。

按照上面的步骤，记录一个 Todo Item 被执行的过程的性能，如下：

[![image](https://user-images.githubusercontent.com/12322740/39393327-b9bc9c12-4af6-11e8-8d97-70905a12a9ad.png)](<https://user-images.githubusercontent.com/12322740/39393327-b9bc9c12-4af6-11e8-8d97-70905a12a9ad.png>)

可以看到，有一点很长的 JS 持续运行时间，而 JS 线程和 UI 线程是互斥的，也就是说这在 JS 疯狂执行的这 467ms 中，用户完全无法操作页面，接下来再分析是怎样的代码造成了如此长时间的执行。

[![image](https://user-images.githubusercontent.com/12322740/39393403-625c48e0-4af7-11e8-9ce4-2368b4a2ad64.png)](<https://user-images.githubusercontent.com/12322740/39393403-625c48e0-4af7-11e8-9ce4-2368b4a2ad64.png>)

  1. 选中长时间执行的组件的生命周期，这里就是 TodoTextInput 的 render 周期，还有 TodoItem 的 constructor 周期，还有 TodoItem 的 render 周期，我们选中第一个。
  2. 点击 Bottom-Up。
  3. 选择 Self Time 按照从大到小排序。
  4. 一层一层展开箭头，然后找到我们想要关注的代码，因为我们想找到自己写的代码的问题，所以在这里可以通过文件区分出自己的代码与 React 源代码的区别。
  5. 问题代码就是 TodoTextInput 的第38行，点进去。

[![image](https://user-images.githubusercontent.com/12322740/39393407-7bdc8b18-4af7-11e8-9ae2-5f49b1f8bf47.png)](<https://user-images.githubusercontent.com/12322740/39393407-7bdc8b18-4af7-11e8-9ae2-5f49b1f8bf47.png>)

原来是被加了一个 200ms 的循环，以此类推，就可以找到 React 渲染的瓶颈组件。

### **why-did-you-update**

这个库可以在控制台上打印出**可能的** 可以避免多次 re-render 的操作。查看源码，原理也很简单，通过比较每次 render 时组件的 prevProps 和 this.props，这里的比较是**深比较** ，对 plain object 递归比较，对同为函数的相同属性只通过比较函数名来判断是否相同。

配置也非常简单。

[![img](https://camo.githubusercontent.com/7e36c77c0189e3de74c986611d51111c6d96585d/68747470733a2f2f692e696d6775722e636f6d2f4e6a49345059742e706e67)](<https://camo.githubusercontent.com/7e36c77c0189e3de74c986611d51111c6d96585d/68747470733a2f2f692e696d6775722e636f6d2f4e6a49345059742e706e67>)

    import React from 'react';

    if (process.env.NODE_ENV !== 'production') {
      const {whyDidYouUpdate} = require('why-did-you-update');
      whyDidYouUpdate(React);
    }

### Highlight updates with the React Developer Tools

通过官方的 DevTools 我们可以手动修改 state 和 prop 的属性

[![image](https://user-images.githubusercontent.com/12322740/39393423-a2ca02aa-4af7-11e8-90cd-54f1755dc970.png)](<https://user-images.githubusercontent.com/12322740/39393423-a2ca02aa-4af7-11e8-90cd-54f1755dc970.png>)

还可以高亮出正在 re-render 的代码，蓝色框代表很少 re-render 的组件，随着 re-render 次数的增长依次是绿色，黄色，红色，这里要注意 highlight 对 React15 和 16 的处理不同。

> With React 15 and earlier, "Highlight Updates" had false positives and highlighted more components than were actually re-rendering.
> 
> Since React 16, it correctly highlights only components that were re-rendered.

[![img](https://camo.githubusercontent.com/951fb3e3375d65185d5cb8f85f81bf5c5814c60f690d1bbd9b0f3af5cc0b99e0/68747470733a2f2f63646e2d696d616765732d312e6d656469756d2e636f6d2f6d61782f313630302f312a4750347658765733574f3076546267674466757334512e706e67)](<https://camo.githubusercontent.com/951fb3e3375d65185d5cb8f85f81bf5c5814c60f690d1bbd9b0f3af5cc0b99e0/68747470733a2f2f63646e2d696d616765732d312e6d656469756d2e636f6d2f6d61782f313630302f312a4750347658765733574f3076546267674466757334512e706e67>)

还可以

  * 通过选中在 Elements Tab 上的真实节点，自动匹配 React 的 VDOM
  * Tree 中对应的节点。
  * 还可以在 React Tab 中右键点击，然后选择"Find the DOM node"，找到真实的节点。
  * 可以显示源代码中对应的 render 的函数。
  * 也可以在控制台通过 `$r` 获得元素的引用，比如可以选中 `Provider`，然后 `$r.store.getState()` 获得 Redux store。

更多的信息可以查看[官方文档](<https://github.com/facebook/react-devtools>)。

### 调试线上版本

[LogRocket](<https://logrocket.com/>)

## 总结

  1. 上面的那些方法只是方法，不是规范，并不是每个组件的设计都能按照最优解来完成，也要考虑必要性和优化的成本。有一句话大概是这么说的：“80%的性能问题集中在20%的代码上“（也可能是90%和10%），没必要纠结一个页脚是用 stateless component 来写或是用 PureComponent 来写，而是关注更容易引起性能问题的长列表、动画组件等。
  2. React 的性能优化最终也会落地在页面渲染的性能优化上，React 已经为我们屏蔽了很多直接操纵 DOM 时容易引起的细节问题，但比如写一个侧边栏你非要用 position 而不是 transfrom 然后去想怎么从 React 方面去优化就是隔靴搔痒了。
  3. 过早的优化是万恶之源，过早的优化是万恶之源，过早的优化是万恶之源。

## 参考

[Make React Fast Again Part 1: Performance Timeline](<https://hackernoon.com/make-react-fast-again-part-1-performance-timeline-b70176a1df5f>)

[Make React Fast Again Part 2: why-did-you-update](<https://hackernoon.com/make-react-fast-again-part-2-why-did-you-update-43a89dc96b10>)

[Make React Fast Again Part 3: Highlighting Component Updates](<https://hackernoon.com/make-react-fast-again-part-3-highlighting-component-updates-798e77dd08d9>)

[High Performance React: 3 New Tools to Speed Up Your Apps](<https://medium.freecodecamp.org/make-react-fast-again-tools-and-techniques-for-speeding-up-your-react-app-7ad39d3c1b82>)

[Chrome Profiler: Self-Time vs. Total-Time](<http://www.bambielli.com/til/2016-02-24-self-time-total-time/>)

[React Stateless Functional Components: Nine Wins You Might Have Overlooked](<https://hackernoon.com/react-stateless-functional-components-nine-wins-you-might-have-overlooked-997b0d933dbc>)

[React: Component Class vs Stateless Component](<https://itnext.io/react-component-class-vs-stateless-component-e3797c7d23ab>)

[How to greatly improve your React app performance](<https://medium.com/myheritage-engineering/how-to-greatly-improve-your-react-app-performance-e70f7cbbb5f6>)

[Understanding the trade-offs between stateless functional components and PureComponent](<https://withcomponents.com/understanding-the-trade-offs-between-stateless-functional-components-and-purecomponent-be1c17180115>)

[React, Inline Functions, and Performance](<https://cdb.reacttraining.com/react-inline-functions-and-performance-bdff784f5578>)

[React + Redux 性能优化（一）：理论篇](<http://qingbob.com/redux-performance-01-basic/>)

[facebook immutable.js 意义何在，使用场景？](<https://www.zhihu.com/question/28016223>)

[[译] React性能优化-虚拟Dom原理浅析](<http://wuyuying.com/blog/archives/optimizing-react-virtual-dom-explained/>)
