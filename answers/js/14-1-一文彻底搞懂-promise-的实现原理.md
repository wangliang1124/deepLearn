# 一文彻底搞懂 promise 的实现原理

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://juejin.cn/post/7122328833507885063>
> 对应题目：JS 深入 第 14 题 · Promise
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

# 前言

promise是我们日常工作中几乎都要用到的一个api，它的出现帮助我们解决了异步问题，至于回调地狱，如果层级多了，promise还是会产生回调地狱，不过我们可以借助async/await一起使用来解决回调地狱的问题。使用了这么久的promise，对于promise如何实现的也没有一窥全貌，所以这次跟大家一起分享它里面的实现。

# EventLoop执行机制

在讲解promise原理之前，我们先来了解eventLoop与宏微任务。

## 微任务

  * js自带api

  * 需要判断环境

    * process.nextTick(node)
    * MutationObserver(浏览器端)

## 宏任务

  * js代码
  * setTimeout
  * setIntervel
  * setImmediate

事件循环机制的执行过程简单提一点：js代码从上至下执行，遇到宏（微）任务，将宏（微）任务存在宏（微）任务事件队列中等待，等待js代码执行完后，再到微任务事件队列中查找是否还有任务在等待执行，如果微任务事件队列没有任务，同理，到宏任务事件队列执行。直到宏任务微任务执行完毕。 [本次分享的重点不在这，有兴趣想了解更多请查阅](<https://link.juejin.cn?target=https%3A%2F%2Fdeveloper.mozilla.org%2Fzh-CN%2Fdocs%2FWeb%2FJavaScript%2FEventLoop> "https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/EventLoop")

# 从一个问题来看promise

  1. 输出下面代码的打印顺序：

    Promise.resolve().then(() => {
        console.log(0);
        return Promise.resolve(4);
    }).then((res) => {
        console.log(res)
    })

    Promise.resolve().then(() => {
        console.log(1);
    }).then(() => {
        console.log(2);
    }).then(() => {
        console.log(3);
    }).then(() => {
        console.log(5);
    }).then(() =>{
        console.log(6);
    })

    输出结果是：0 1 2 3 4 5 6

输出结果为什么跟我们预想的 0 1 4 2 3 5 6不一样呢？

# promiseA+规范

new Promise().then()，如果then中返回一个promise(简称p0)，（V8源码中）则会执行()=>p0.then(完成p0的状态变化)，同时将() => p0.then(完成p0的状态变化) 添加到异步队列中。

# 题目的运行过程

以输出数字为p的标记

  1. p0（() => { console.log(0); return Promise.resolve(4)}）进入异步队列中，此时异步队列[p0]；
  2. p1进入异步队列中，此时异步队列[p0,p1]。
  3. 执行p0，输出0。return Promise.resolve(4)则是转换成 () => p4.then(完成p0的状态变化)添加到异步队列中，此时异步队列[p1, () => p4.then(完成p0的状态变化)]
  4. 输出1，由于p1状态变为fulfilled，p2进入异步队列，[() => p4.then(完成p0的状态变化), p2]
  5. 执行p4.then(完成p0的状态变化)，（完成p0的状态变化即pres = (res) => res）, pres进入异步队列，此时异步队列为[p2, pres]
  6. 输出2，p2状态变为fulfilled，p3进入异步队列，此时异步队列为[pres, p3]
  7. 执行pres，p0状态变为fulfilled，后续打印res的then回调进入异步队列中，此时[p3, () => console.log(res)]
  8. 输出3，p5进入异步队列中
  9. 输出4
  10. 输出5，p6进入异步队列中
  11. 输出6

# 实现一个promise

## 使用方式

先来了解日常工作中我们一般都是怎么使用promise，下面是总结的几个例子。

  1. 常规方式

    new Promise((resolve, reject) => {
        resolve(1)
    })
    .then(res => console.log(res))
    .catch(err => console.log(err))

  2. new Promise抛出异常

    new Promise((resolve, reject) => {
        throw new Error('test')
    })
    .then(res => console.log(res))
    .catch(err => console.log(err))

  3. 异步resolve

    new Promise((resolve, reject) => {
        setTimeout(() => resolve(1))
    })
    .then(res => console.log(res))
    .catch(err => console.log(err))

  4. then/catch链式调用

    new Promise((resolve, reject) => {
        resolve(1)
    })
    .then(res => console.log(`1-then`, res))
    .catch(err => console.log(`1-catch`, err))
    .then(res => console.log(`2-then`,res))
    .catch(err => console.log(`2-catch`,err))
    .then(res => console.log(`3-then`,res))
    .catch(err => console.log(`3-catch`,err))

  5. then/catch参数可选

    new Promise((resolve, reject) => {
        resolve(1)
    })
    .then()
    .then()
    .then(res => console.log(`3-then`,res))

## 实现一个简单的Promise

    new Promise((resolve, reject) => {})

    // 作为MyPromise的形参，这形参是一个函数，又有自己的形参，实参在函数执行的时候传入
    function executor(resolve, reject) {}
    const FULFILLED = 'fulfilled'
    const REJECTED = 'rejected'
    const PENDING = 'pending'
    function MyPromise(executor) {
        // 上下文共享状态
        const ctx = this.ctx = {
            value: '',
            reason: '',
            status: 'pending'
        }

        // resolve实现状态改变及保存数据到实例属性中
        const resolve = (value) => {
            // 状态变化只能从pending转变为fulfilled或者rejected，且更改后无法再次更改
            if(ctx.status === PENDING) {
                ctx.value = value
                ctx.status = FULFILLED
            }
        }

        // reject实现状态改变及保存数据到实例属性中
        const reject = (reason) => {
            // 状态变化只能从pending转变为fulfilled或者rejected，且更改后无法再次更改
            if(ctx.status === PENDING) {
                ctx.reason = reason
                ctx.status = REJECTED
            }
        }

        executor(resolve, reject)
    }
    MyPromise.prototype.then = function(res){
        if(this.ctx.status === PENDING) {
            console.log('then', res)
        }
    }

    MyPromise.prototype.catch = function(err){
        if(this.ctx.status === PENDING) {
            console.log('catch', err)
        }
    }

## 异常捕获（try-catch）

关于异常捕获，有很多方式，比较被我们大家熟知的是window.onerror，try-catch，这里我们用try-catch。

  1. new Promise()抛出异常

    new MyPromise((resolve, reject) => {
        throw new Error() 
    })

    function MyPromise(executor) {
        ...
        try {
            executor(resolve, reject)
        } catch(err) {
            reject(err)
        }

    }

  2. then中onFulfilled及onRejected执行抛出异常

    MyPromise.prototype.then = function(onFulfilled, onRejected) {
        if(this.ctx.status === FULFILLED) {
            try{
                onFulfilled(this.ctx.value)
            } catch(err) {
                console.log('catch error', err)
            }
        }
    }
    MyPromise.prototype.then = function(onFulfilled, onRejected) {
        // 实现链式调用，同时确保每次返回的都是一个新的promise。
        const _promise = new MyPromise((resolve, reject) => {
            if(this.ctx.status === PENDING) {
                try{
                    const result = onFulfilled(this.ctx.value)
                    resolvePromise(promise2, x, resolve, reject);
                } catch(err) {
                    reject(err)
                }

            } else if(this.ctx.status === FULFILLED) {
                onRejected(this.ctx.reason)
            } else if(this.ctx.status === REJECTED) {

            }
        })
        return _promise
    }

    P.then().catch()

## 异步resolve

我们在初始化Promise实例的时候，会遇到这种情况，我们不会立即resolve，而是等待一段时间的延迟或者等待接口请求完成后才resolve，而我们前面的实现都是同步的方式。

实例化时没有resolve()走到then函数中执行时，当前实例的状态是pending，这时then是不会执行onFulfilled函数的。

  * 框架的处理方式  
对于这种异步执行的场景，前端框架里面常用的方式是增加事件队列+异步处理来实现延迟，这些场景大多是同步的方式下加入宏微任务队列来达到延迟的目的。

  * 上下文共享状态（实例属性）  
但promise这里已经是异步，如果再加入异步，我们如何确保这两个异步的执行顺序？至于是否可以加入发布订阅模式来处理，这里不深入。回过头来看说明then在resolve前面执行，我们可以先将onFulfilled（onRejected）保存在this.ctx属性中到resolve中执行，在其前面加个判断条件执行。

    const p = new MyPromise((resolve, reject) => {
        setTimeout(() => {
            resolve(1)
        }, 1000)
    })
    p.then(res => {

    })

    ==========resolve改动===============
    const onFulfilledQueue = []

    const resolve = (value) => {
        if(ctx.status === PENGDING) {
            ctx.status = FULFILLED
            ctx.value = value
            if(onFulfilledQueue.length) {
                onFulfilledQueue.forEach(fn => fn())
            }
        }
    }

    ==========then改动===============
    MyPromise.prototype.then = function(onFulfilled, onRejected) {
        const _promise = new MyPromise((resolve, reject) => {
            if(this.ctx.status === PENDING) {
                onFulfilled && this.ctx.onFulfilledQueue.push(onFulfilled)
                onRejected && this.ctx.onRejectedQueue.push(onRejected)
            } else if(this.ctx.status === FULFILLED) {
                const res = onFulfilled(this.ctx.value)
                resolvePromise(x, resolve, reject)
            } else if(this.ctx.status === REJECTED) {
                onRejected(this.ctx.reason)
            }
        })
        return _promise
    }

    function resolvePromise(res, resolve, reject) {
        if(res instanceof MyPromise || (res?.then && type res.then === 'function')) {
            res.then(resolve)
        } else {
            resolve(res)
        }
    }

## then链式调用

  1. promiseA+规范中规定then返回一个新的promise实例

  * 关于链式调用，在js里面，我们的做法是在所有的方法中返回当前实例。但是在promise这里行不通；是因为返回当前promise实例，当前promise实例状态从pending->fulfilled，或者pending->rejected后无法再改变，后面将会一直走then的逻辑。

promise本身也不支持onFulfilled(onRejected)返回当前实例，返回则是会报错

    var p = new Promise((resolve, reject) => {resolve(1)}).then(res => {console.log(res); return p})

    // 报错信息
    Uncaught (in promise) TypeError: Chaining cycle detected for promise #<Promise>

  2. onFulfilled（onRejected）返回值

  * 返回一个promise实例
  * 返回一个类promise对象（拥有then属性）
  * 返回一个基本数据
  * 抛出一个异常

    // 例子
    new Promise((resolve, reject) => {
        resolve(1)
    }).then(res => console.log('then', res)).catch(err => {console.log('catch', err); return err}).then(res => console.log('then2', res)).catch(err => {console.log('catch2', err)})

    // then改版
    MyPromise.prototype.then = function(onFulfilled, onRejected){
        const _promise = new Promise((resolve, reject) => {
            const { status, value, onFulfilledQueue, onRejectedQueue } = this.ctx;

            if (status === FULFILLED) {
                try{
                    const x = onFulfilled(value)
                    resolvePromise(x, resolve, reject)
                } catch (err) {
                    reject(err)
                }
            } else if(status === REJECTED) {
                try{
                    const x = onRejected(value)
                    resolvePromise(x, resolve, reject)
                } catch (err) {
                    reject(err)
                }
            } else if(status === PENDING) {
                onFulfilled && onFulfilledQueue.push(onFulfilled)
                onRejected && onRejectedQueue.push(onRejected)
            }
        })

    }

## then参数可选

    // 例子
    new Promise((resolve, reject) => {
     resolve(1)   
    }).then().then().then().then().then(res => console.log('then5', res))

    // catch
    new Promise((resolve, reject) => {
        reject(1)
    }).then(res => console.log('then', res)).catch().then(res => {console.log('then2', res); return res}).catch(err => {console.log('catch2', err)})

    // then改动
    MyPromise.prototype.then = function(onFulfilled, onRejected){
        onFulfilled = onFulfilled && typeof onFulfilled === 'function' ? onFulfilled : (value) => value;
        onRejected = onRejected && typeof onRejected === 'function' ? onRejected : (reason) => { throw reason };

        const _promise = new Promise((resolve, reject) => {

            if (status === FULFILLED) {
                try{
                    const x = onFulfilled(value)
                    resolvePromise(x, resolve, reject)
                } catch (err) {
                    reject(err)
                }
            } else if(status === REJECTED) {
                try{
                    const x = onRejected(value)
                    resolvePromise(x, resolve, reject)
                } catch (err) {
                    reject(err)
                }
            } else if(status === PENDING) {
                onFulfilled && onFulfilledQueue.push(onFulfilled)
                onRejected && onRejectedQueue.push(onRejected)
            }
        })

    }

## Promise.resolve()

    MyPromise.prototype.resove = function(params) {
        const _promise = new MyPromise((resolve, reject) => {
            if(params instanceof MyPromise || typeof params?.then === 'function') {
                params.then(resolve)
            } else {
                resolve(params)
            }
        })
        return _promise
    }

# promiseA+测试

上面从Promise的使用方式来了解promise及实现，可以通过promises-aplus-tests包来测试我们手写的这个Promise代码是否符合PromiseA+规范。

    npm install promises-aplus-tests -D

在进行测试之前，需要在promise的代码中加入下图所示的代码。 ![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/caf7ebc4336b4cefbb8be59c440c3913~tplv-k3u1fbpfcp-zoom-in-crop-mark:1512:0:0:0.awebp?)

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c0fe2aff4cbe436887f48a1660ee0bc6~tplv-k3u1fbpfcp-zoom-in-crop-mark:1512:0:0:0.awebp?)

    npm run test

即可测试啦

在[V8源码补充篇](<https://juejin.cn/post/6953452438300917790#heading-1> "https://juejin.cn/post/6953452438300917790#heading-1")中提到，return Promise.resolve(4)，在V8源码中返回一个新的promise，导致创建了两次微任务，也就是说：

  * **第一次：** 在发现 Promise.resolve(4) 的时候，创建 NewPromiseResolveThenableJob，并将其送入微任务队列
  * **第二次：** 在处理 Promise.resolve(4) 的时候，调用 then 方法时，内部创建了微任务来处理回调函数

在解释上面例子执行结果之前，我们先记住一个点：then里面为了避免onFulfilled返回当前promise实例，将onFulfilled的执行加入了异步任务以等待promise完成实例化。

    1. MyPromise.resolve().then(() => {
        console.log(0);
        return MyPromise.resolve(4);
    })
    2. MyPromise.resolve().then(() => {
        console.log(1);
    })

**[1的回调, 2的回调]**  
then中的回调是异步任务，1先将回调存入异步任务队列中，根据EventLoop的执行过程，2紧随其后将回调存入异步任务队列中，此时js主线程没有代码在执行；所以此时会去异步任务队列中查询并按先入先出的顺序去执行任务；先执行1的回调，这个过程返回一个新的promise实例，在resolvePromise中返回的实例在这里执行为myPromise.then(resolve, reject)，这个过程产生了一个异步任务，又回到了任务挂起状态。 **[2的回调，MyPromise.resolve(4)的回调]**  
此时异步任务队列中存在两个回调: **[2的回调，MyPromise.resolve(4)的回调]** ，紧接着执行异步任务队列中2的回调，2的回调是输出1，后面的then又进入异步任务队列中。

**[MyPromise.resolve(4)的回调, 2的then(console.log(2))的回调]** return MyPromise.resolve(4)及resolvePromise的实现可知，MyPromise.resolve(4)在resolvePromise中执行then完成后才到1的console.log(res)的then回调。

    .then((res) => {
        console.log(res)
    })

**[2的then(console.log(2))的回调, MyPromise.resolve(4).then的回调]** 以此类推，按照这个执行顺序，我们得到的最终结果是**0 1 2 4 3 5 6** ，跟实际输出的**0 1 2 3 4 5 6** 还是有区别；结合V8 Chrome源码文章讲到的：

    原生 Promise 创建两次微任务的位置：

    第一次： 在发现 Promise.resolve(4) 的时候，创建 NewPromiseResolveThenableJob，并将其送入微任务队列

    第二次： 在处理 Promise.resolve(4) 的时候，调用 then 方法时，内部创建了微任务来处理回调函数

所以我们需要在resolvePromise中改一下逻辑，

    function resolvePromise(_promise, x, resolve, reject) {
        if(_promise === x) {
            throw new Error('')
            return 
        }
        // 如果then(onFulfilled)的onFulfilled返回的是一个promise实例，那么加入异步处理
        if(_promise instanceof MyPromise || (_promise && typeor _promise.then === 'function')) {
            queueMicrotask(() => x.then(resolve, rejct))
        } else {
            resolve(x)
        }
    }

# MyPromise如何改才能跟Promise一样输出？

resolvePromise中，当发现onFulfilled返回的是一个promise实例时，将其推进微任务事件队列中。这里使用queueMicrotask

    function resolvePromise(promise2, x, resolve, reject) {
      // 如果相等了，说明return的是自己，抛出类型错误并返回
      if (promise2 === x) {
        return reject(new TypeError('Chaining cycle detected for promise #<Promise>'))
      }
      // 判断x是不是 MyPromise 实例对象
      if(x instanceof MyPromise) {
        queueMicrotask(() => { x.then(resolve, reject)})
      } else{
        // 普通值
        resolve(x)
      }
    }

# refrence

[从一道让我失眠的 Promise 面试题开始，深入分析 Promise 实现细节](<https://juejin.cn/post/6945319439772434469#heading-15> "https://juejin.cn/post/6945319439772434469#heading-15")  
[V8源码补充篇](<https://juejin.cn/post/6953452438300917790#heading-1> "https://juejin.cn/post/6953452438300917790#heading-1")  
[Promise V8 源码分析(一)](<https://link.juejin.cn?target=https%3A%2F%2Fzhuanlan.zhihu.com%2Fp%2F264944183> "https://zhuanlan.zhihu.com/p/264944183")  
[chrome v8 promise源码](<https://link.juejin.cn?target=https%3A%2F%2Fchromium.googlesource.com%2Fv8%2Fv8.git%2F%2B%2Frefs%2Fheads%2F9.0-lkgr%2Fsrc%2Fbuiltins%2Fpromise-then.tq> "https://chromium.googlesource.com/v8/v8.git/+/refs/heads/9.0-lkgr/src/builtins/promise-then.tq")  
[promiseA+规范](<https://link.juejin.cn?target=https%3A%2F%2Fpromisesaplus.com%2F%23notes> "https://promisesaplus.com/#notes")
