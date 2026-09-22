# React setState 详解

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/PeterChen1997/Frontend-Repo/wiki/02-React-setState%E8%AF%A6%E8%A7%A3>
> 对应题目：React 第 15 题 · 调用 setState 之后发生了什么？
> 抓取时间：2026-09-22

---

// 官方定义
    this.setState(updater[,callback])

![img](https://camo.githubusercontent.com/906de2b65f0d5530b2ec4dd31af600aeee895b91fd02a28be11b480896d47b02/68747470733a2f2f706963332e7a68696d672e636f6d2f38302f34666431613135356661656466663030393130646661626535646531343366635f68642e6a7067)

  * 首先将newState存入pending队列
  * 根据isBatchingUpdates判断是否直接更新 
    * False:遍历dirtyComponents,调用updateComponent,更新pending state 和 props
    * True:保存组件到dirtyComponents

**解释：** 函数batchedUpdates,会将isbatchedUpdates设置为true,在React调用事件处理函数之前就会调用这个函数，造成的后果就是不会同步更新state

**原因：** 每次进行setState必然触发更新过程，所以一是可以通过shouldComponentUpdate进行一个筛选，二是可以将之前的setState进行一个merge统一render，保证render不是每次都执行，否则则十分消耗性能

  * shouldComponentUpdate
  * componentWillUpdate
  * render **(在render的时候才会更新state)**
  * componentDidUpdate

* * *

    // count : 0
    this.setState({ count: this.state.count + 1 })
    this.setState({ count: this.state.count + 1 })

> 在传统调用当中，执行完上面的两次setState后，count为1，不为2

在调用setState时，不是同步变化的，所以state并没有变化(参见上述生命周期)，所以setState只是在重复设置一个值

    function updater(preState, props) {
      return { count: preState.count + 1 }
    }

    ---
    // count : 0
    this.setState(updater) // count: 1
    this.setState(updater) // count: 2

  * updater可以是一个函数，函数返回setState需要更改的键值对对象
  * 函数有两个形参，一个是state,一个是props
  * 使用函数式调用的时候可以完成同步更新state(但是依然是在render的时候更新state)
