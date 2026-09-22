## 1. 实现 new 操作符

> ▶ 运行 demo：[handwritten-new.html](handwritten-new.html)

```js
function New(constructor, ...args) {
    // 创建一个新对象，该对象继承自构造函数的原型
    const obj = Object.create(constructor.prototype);

    // 调用构造函数，并将新对象作为 this 值传递进去
    const result = constructor.apply(obj, args);

    // 构造函数显式返回对象或函数时以其为结果，其余情况返回新创建的对象
    const isObject = typeof result === "object" && result !== null;
    return isObject || typeof result === "function" ? result : obj;
}
```

## 2. 实现 JSON.stringify

> ▶ 运行 demo：[handwritten-json-stringify-parse.html](handwritten-json-stringify-parse.html)

```js
function jsonStringify(obj) {
    const type = typeof obj;
    if (/undefined|function|symbol/.test(type)) {
        return undefined;
    }
    if (/number|boolean/.test(type) || obj === null) {
        return String(obj);
    }
    if (type === "string") {
        return `"${obj}"`;
    }
    let result = [];
    switch (Object.prototype.toString.call(obj)) {
        case "[object Array]":
            for (let v of obj) {
                let value = jsonStringify(v);
                value = value === undefined ? "null" : value;
                result.push(value);
            }
            return "[" + result.join() + "]";

        case "[object Object]":
            for (let [key, value] of Object.entries(obj)) {
                value = jsonStringify(value);
                if (value !== undefined) {
                    result.push(`"${key}":${value}`);
                }
            }
            return "{" + result.join() + "}";
        case "[object Date]":
            return `"${obj.toJSON ? obj.toJSON() : obj.toString()}"`;
        default:
            return "{}";
    }
}
```

## 3. 实现 JSON.parse

> ▶ 运行 demo：[handwritten-json-stringify-parse.html](handwritten-json-stringify-parse.html)

两种写法都依赖把字符串当代码执行，**只能用于可信数据**；解析用户输入会导致任意代码执行，生产环境一律用原生 `JSON.parse`。

**推荐**：`new Function`。它在独立的函数作用域里求值，拿不到调用处的局部变量，比 `eval` 泄露面小。

```js
function jsonParse(json) {
    return new Function("return " + json)();
}
```

`eval` 版本。`eval` 能访问并修改当前作用域，风险更大：

```js
function jsonParse2(json) {
    // 加括号把 {} 变成表达式而不是代码块
    return eval("(" + json + ")");
}
```

> JSON.parse 三种实现方式 https://github.com/youngwind/blog/issues/115

## 4. 实现 call & apply

> ▶ 运行 demo：[handwritten-call-apply.html](handwritten-call-apply.html)（用到 ES module，需起 http server）

核心思路都一样：把目标函数临时挂到 `context` 上，以 `context.fn()` 的形式调用，借此让 `this` 指向 `context`，调用完再删掉。

### 推荐：ES6 写法

用剩余参数和展开运算符，不需要 `eval`：

```js
Function.prototype._call = function(context = window, ...args) {
    const key = Symbol("fn"); // 用 Symbol 作键，避免覆盖 context 上已有的同名属性
    context[key] = this;
    const result = context[key](...args);
    delete context[key];
    return result;
};

Function.prototype._apply = function(context = window, argsArr = []) {
    const key = Symbol("fn");
    context[key] = this;
    const result = context[key](...argsArr); // 与 _call 的唯一区别：参数以数组传入
    delete context[key];
    return result;
};
```

原版用固定的 `context.fn` 作键，如果 `context` 本身就有 `fn` 属性会被覆盖，且调用后被 `delete` 掉。换成 `Symbol` 可以避开。

### ES5 写法（仅作原理参考）

ES5 没有展开运算符，只能拼出参数列表字符串再 `eval`：

```js
Function.prototype._call = function(context) {
    context = context || window;
    context.fn = this;
    var args = [];
    for (var i = 1, len = arguments.length; i < len; i++) {
        args.push("arguments[" + i + "]");
    }
    var result = eval("context.fn(" + args + ")");
    delete context.fn;
    return result;
};

Function.prototype._apply = function(context, argsArr) {
    context = context || window;
    argsArr = argsArr || [];
    context.fn = this;

    var args = [];
    for (var i = 0, len = argsArr.length; i < len; i++) {
        args.push("argsArr[" + i + "]");
    }

    var result = eval("context.fn(" + args + ")");
    delete context.fn;
    return result;
};
```

### 用 call 实现一个简版 bind

```js
Function.prototype.bind2 = function(context, ...args) {
    const fn = this;
    return function(...rest) {
        return fn.call(context, ...args, ...rest); // 必须 return，否则绑定后的函数拿不到返回值
    };
};
```

这个简版不支持 `new`（用 `new` 调用时 `this` 应指向新实例而非 `context`），完整实现见下一节。

## 5. 实现 bind

> ▶ 运行 demo：[handwritten-bind.html](handwritten-bind.html)

`bind` 比 `call`/`apply` 难的地方在于：返回的函数既可以直接调用（`this` 指向 `context`），也可以被 `new` 调用（此时 `this` 应指向新实例，绑定的 `context` 要失效）。两种写法都靠 `this instanceof bound` 来区分这两种调用方式。

### 推荐：通过原型链继承处理 new

```js
Function.prototype._bind = function(context) {
    if (typeof this !== "function") {
        throw Error("bind must be called on a function");
    }
    var source = this;
    var args = Array.prototype.slice.call(arguments, 1);
    var fNOP = function() {};

    var bound = function() {
        var bindArgs = Array.prototype.slice.call(arguments);
        return source.apply(this instanceof bound ? this : context, args.concat(bindArgs));
    };

    // Function.prototype doesn't have a prototype property
    if (source.prototype) {
        fNOP.prototype = source.prototype;
    }
    bound.prototype = new fNOP();

    return bound;
};
```

让 `bound.prototype` 继承 `source.prototype`，这样 `new bound()` 产生的实例仍然 `instanceof source`，且实例的原型链完整。中间垫一个空函数 `fNOP`，是为了避免直接 `bound.prototype = source.prototype` 时修改实例原型会污染原函数的原型。

### 另一种写法：参考 underscore，在函数体内处理

不动 `bound.prototype`，而是在被 `new` 调用时现场创建实例。多了一步「构造函数返回对象则以其为准」的判断，逻辑更贴近 `new` 的真实语义，但每次 `new` 都要新建一个 `fNOP`：

```js
var bound = function() {
    var bindArgs = Array.prototype.slice.call(arguments);
    if (!(this instanceof bound)) {
        return source.apply(context, args.concat(bindArgs));
    }
    var fNOP = function() {};
    if (source.prototype) {
        fNOP.prototype = source.prototype;
    }
    var newObj = new fNOP();
    var ret = source.apply(newObj, args.concat(bindArgs));
    if (ret !== null && (typeof ret === "object" || typeof ret === "function")) {
        return ret;
    }
    return newObj;
};
```

> bind 方法的兼容实现 https://github.com/lessfish/underscore-analysis/issues/19

## 6. 实现一个 Object.create

> ▶ 运行 demo：[handwritten-object-create.html](handwritten-object-create.html)

```js
function create(proto) {
    if (Object.create) {
        return Object.create(proto);
    }
    function F() {}
    F.prototype = proto;
    return new F();
}
```

## 7. 实现函数柯里化

> ▶ 运行 demo：[handwritten-currying.html](handwritten-currying.html)

### 推荐：剩余参数写法

```js
function curry(func) {
    return function curried(...args) {
        // 参数够了就直接执行
        if (args.length >= func.length) {
            return func.apply(this, args);
        }
        // 否则返回新函数继续收集剩余参数
        return function (...args2) {
            return curried.apply(this, args.concat(args2));
        };
    };
}

const curriedSum = curry((a, b, c) => a + b + c);
curriedSum(1, 2, 3); // 6
curriedSum(1)(2, 3); // 6
curriedSum(1)(2)(3); // 6
```

### ES5 写法

用 `arguments` 拼接参数并递归。注意判断条件是 `>=` 而不是 `===`，否则传入多于形参个数的实参时会一直返回函数而不执行：

```js
function currying(func) {
    var args = Array.prototype.slice.call(arguments, 1);
    return function() {
        var newArgs = args.concat([].slice.call(arguments));
        if (newArgs.length >= func.length) {
            return func.apply(this, newArgs);
        }
        newArgs.unshift(func);
        return currying.apply(this, newArgs);
    };
}
```

## 8. 实现 Promise

> ▶ 运行 demo：[handwritten-promise.html](handwritten-promise.html)

```js
/**
 * 1. new Promise时，需要传递一个 executor 执行器，执行器立刻执行
 * 2. executor 接受两个参数，分别是 resolve 和 reject
 * 3. promise 只能从 pending 到 rejected, 或者从 pending 到 fulfilled
 * 4. promise 的状态一旦确认，就不会再改变
 * 5. promise 都有 then 方法，then 接收两个参数，分别是 promise 成功的回调 onFulfilled,
 *      和 promise 失败的回调 onRejected
 * 6. 如果调用 then 时，promise已经成功，则执行 onFulfilled，并将promise的值作为参数传递进去。
 *      如果promise已经失败，那么执行 onRejected, 并将 promise 失败的原因作为参数传递进去。
 *      如果promise的状态是pending，需要将onFulfilled和onRejected函数存放起来，等待状态确定后，再依次将对应的函数执行(发布订阅)
 * 7. then 的参数 onFulfilled 和 onRejected 可以缺省
 * 8. promise 可以then多次，promise 的then 方法返回一个 promise
 * 9. 如果 then 返回的是一个结果，那么就会把这个结果作为参数，传递给下一个then的成功的回调(onFulfilled)
 * 10. 如果 then 中抛出了异常，那么就会把这个异常作为参数，传递给下一个then的失败的回调(onRejected)
 * 11.如果 then 返回的是一个promise,那么需要等这个promise，那么会等这个promise执行完，promise如果成功，
 *   就走下一个then的成功，如果失败，就走下一个then的失败
 */

// promise 三个状态
const PENDING = "Pending";
const FULFILLED = "Fulfilled";
const REJECTED = "Rejected";

function Promise(excutor) {
    this.status = PENDING; // 初始状态
    this.value = undefined; // fulfilled状态时 返回的信息
    this.reason = undefined; // rejected状态时 拒绝的原因
    this.onFulfilledCallbacks = []; // 存储fulfilled状态对应的onFulfilled函数
    this.onRejectedCallbacks = []; // 存储rejected状态对应的onRejected函数

    let self = this; // 缓存当前promise实例对象
    function resolve(value) {
        // 只能由pending状态 => fulfilled状态 (避免调用多次resolve reject)
        if (self.status === PENDING) {
            self.status = FULFILLED;
            self.value = value;
            self.onFulfilledCallbacks.forEach(cb => cb(self.value));
        }
    }

    function reject(reason) {
        // 只能由pending状态 => rejected状态 (避免调用多次resolve reject)
        if (self.status === PENDING) {
            self.status = REJECTED;
            self.reason = reason;
            self.onRejectedCallbacks.forEach(cb => cb(self.reason));
        }
    }

    try {
        excutor(resolve, reject);
    } catch (e) {
        reject(e);
    }
}

/**
 * resolve中的值几种情况：
 * 1.普通值
 * 2.promise对象
 * 3.thenable对象/函数
 */

/**
 * 对resolve 进行改造增强 针对resolve中不同值情况 进行处理
 * @param  {promise} promise2 promise1.then方法返回的新的promise对象
 * @param  {[type]} x         promise1中onFulfilled的返回值
 * @param  {[type]} resolve   promise2的resolve方法
 * @param  {[type]} reject    promise2的reject方法
 */
function resolvePromise(promise2, x, resolve, reject) {
    if (promise2 === x) {
        // 如果从onFulfilled中返回的x 就是promise2 就会导致循环引用报错
        return reject(new TypeError("循环引用"));
    }

    // 判断 x 是否是 promise 对象
    if (x != null && (typeof x === "object" || typeof x === "function")) {
        let called = false; // 避免多次调用
        try {
            let then = x.then;
            if (typeof then === "function") {
                then.call(
                    x,
                    y => {
                        if (called) return;
                        called = true;
                        resolvePromise(promise2, y, resolve, reject);
                    },
                    reason => {
                        if (called) return;
                        called = true;
                        reject(reason);
                    },
                );
            } else {
                // 说明是一个普通对象/函数
                resolve(x);
            }
        } catch (e) {
            if (called) return;
            called = true;
            reject(e);
        }
    } else {
        resolve(x);
    }
}

/**
 * [注册fulfilled状态/rejected状态对应的回调函数]
 * @param  {function} onFulfilled fulfilled状态时 执行的函数
 * @param  {function} onRejected  rejected状态时 执行的函数
 * @return {function} newPromsie  返回一个新的promise对象
 */
Promise.prototype.then = function(onFulfilled, onRejected) {
    let self = this;
    let promise2;
    // 处理参数默认值 保证参数后续能够继续执行
    onFulfilled =
        typeof onFulfilled === "function"
            ? onFulfilled
            : value => {
                  return value;
              };
    onRejected =
        typeof onRejected === "function"
            ? onRejected
            : reason => {
                  throw reason;
              };

    // then里面的FULFILLED/REJECTED状态时 为什么要加setTimeout ?
    // 原因:
    // 其一 2.2.4规范 要确保 onFulfilled 和 onRejected 方法异步执行(且应该在 then 方法被调用的那一轮事件循环之后的新执行栈中执行) 所以要在resolve里加上setTimeout
    // 其二 2.2.6规范 对于一个promise，它的then方法可以调用多次.（当在其他程序中多次调用同一个promise的then时 由于之前状态已经为FULFILLED/REJECTED状态，则会走的下面逻辑),所以要确保为FULFILLED/REJECTED状态后 也要异步执行onFulfilled/onRejected

    // 其二 2.2.6规范 也是resolve函数里加setTimeout的原因
    // 总之都是 让then方法异步执行 也就是确保onFulfilled/onRejected异步执行

    // 如下面这种情景 多次调用p1.then
    // p1.then((value) => { // 此时p1.status 由pending状态 => fulfilled状态
    //     console.log(value); // resolve
    //     // console.log(p1.status); // fulfilled
    //     p1.then(value => { // 再次p1.then 这时已经为fulfilled状态 走的是fulfilled状态判断里的逻辑 所以我们也要确保判断里面onFuilled异步执行
    //         console.log(value); // 'resolve'
    //     });
    //     console.log('当前执行栈中同步代码');
    // })
    // console.log('全局执行栈中同步代码');
    //

    if (self.status === FULFILLED) {
        // 成功态
        promise2 = new Promise((resolve, reject) => {
            setTimeout(() => {
                try {
                    let x = onFulfilled(self.value);
                    resolvePromise(promise2, x, resolve, reject); // 新的promise resolve 上一个onFulfilled的返回值
                } catch (e) {
                    reject(e); // 捕获前面onFulfilled中抛出的异常 then(onFulfilled, onRejected);
                }
            });
        });
        return promise2;
    }

    if (self.status === REJECTED) {
        // 失败态
        promise2 = new Promise((resolve, reject) => {
            setTimeout(() => {
                try {
                    let x = onRejected(self.reason);
                    resolvePromise(promise2, x, resolve, reject);
                } catch (e) {
                    reject(e);
                }
            });
        });
        return promise2;
    }

    if (self.status === PENDING) {
        // 当异步调用resolve/rejected时 将onFulfilled/onRejected收集暂存到集合中
        // 为什么加setTimeout?
        // 2.2.4规范 onFulfilled 和 onRejected 只允许在 execution context 栈仅包含平台代码时运行.
        // 注1 这里的平台代码指的是引擎、环境以及 promise 的实施代码。实践中要确保 onFulfilled 和 onRejected 方法异步执行，且应该在 then 方法被调用的那一轮事件循环之后的新执行栈中执行。

        promise2 = new Promise((resolve, reject) => {
            self.onFulfilledCallbacks.push(value => {
                setTimeout(() => {
                    try {
                        let x = onFulfilled(value);
                        resolvePromise(promise2, x, resolve, reject);
                    } catch (e) {
                        reject(e);
                    }
                });
            });
            self.onRejectedCallbacks.push(reason => {
                setTimeout(() => {
                    try {
                        let x = onRejected(reason);
                        resolvePromise(promise2, x, resolve, reject);
                    } catch (e) {
                        reject(e);
                    }
                });
            });
        });
        return promise2;
    }
};
```

### Promise.resolve

```js
Promise.resolve = function(value) {
    if (value instanceof Promise) {
        return value;
    }
    return new Promise((resolve, reject) => {
        if (value && value.then && typeof value.then === "function") {
            setTimeout(() => {
                value.then(resolve, reject);
            });
        } else {
            resolve(value);
        }
    });
};
```

### Promise.reject

```js
Promise.reject = function(reason) {
    return new Promise((resolve, reject) => reject(reason));
};
```

### Promise.prototype.catch

```js
Promise.prototype.catch = function(onRejected) {
    return this.then(null, onRejected);
};
```

### Promise.prototype.finally

```js
Promise.prototype.finally = function(callback) {
    return this.then(
        value => {
            return Promise.resolve(callback()).then(() => {
                return value;
            });
        },
        err => {
            return Promise.resolve(callback()).then(() => {
                throw err;
            });
        },
    );
};
```

### Promise.race

```js
Promise.race = function(promises) {
    if (promises.length === 0) {
        return;
    }
    return new Promise((resolve, reject) => {
        promises.forEach((promise, index) => {
            Promise.resolve(promise).then(resolve, reject);
        });
    });
};
```

### Promise.all

```js
Promise.all = function(promises) {
    return new Promise((resolve, reject) => {
        let count = 0;
        let result = [];
        if (promises.length === 0) {
            resolve(result);
        } else {
            for (let i = 0; i < promises.length; i++) {
                // promises[i] 可能是普通值
                Promise.resolve(promises[i]).then(data => {
                    result[i] = data;
                    if (++count === promises.length) {
                        resolve(result);
                    }
                }, reject);
            }
        }
    });
};
```

## 9. 防抖和节流

> ▶ 运行 demo：[handwritten-debounce.html](handwritten-debounce.html) · [handwritten-throttle.html](handwritten-throttle.html)

### 防抖 debounce

```js
function debounce(func, wait) {
    var timer = null;
    return function() {
        var context = this;
        var args = arguments;
        if (timer !== null) {
            clearTimeout(timer);
        }
        timer = setTimeout(function() {
            func.apply(context, args);
        }, wait);
    };
}
```

### 节流 throttle

```js
function throttle(func, wait) {
    var timer = null;
    var previous = 0;
    return function() {
        var now = Date.now();
        var remaining = wait - (now - previous);
        var context = this;
        var args = arguments;
        if (remaining <= 0 || remaining > wait) {
            if (timer) {
                clearTimeout(timer);
                timer = null;
            }
            previous = now;
            func.apply(context, args);
        } else if (!timer) {
            timer = setTimeout(function() {
                previous = Date.now();
                func.apply(context, args);
                timer = null;
            }, remaining);
        }
    };
}
```

## 10. 实现一个 JS 深拷贝

> ▶ 运行 demo：[handwritten-deep-clone.html](handwritten-deep-clone.html)

用一个 `Map` 缓存「原对象 → 克隆对象」的映射来处理循环引用：再次遇到同一个对象时返回**已创建的克隆**，而不是原对象，否则克隆结果里会混进源对象的引用。

```js
function deepClone(obj, map = new Map()) {
    if (!obj || typeof obj !== "object") {
        return obj;
    }

    if (obj.nodeType && "cloneNode" in obj) {
        return obj.cloneNode(true);
    }

    // 命中缓存说明是循环引用，返回此前创建的克隆
    if (map.has(obj)) {
        return map.get(obj);
    }

    var result;
    switch (Object.prototype.toString.call(obj)) {
        case "[object Array]":
            result = [];
            map.set(obj, result);
            for (let v of obj) {
                result.push(deepClone(v, map));
            }
            return result;

        case "[object Object]":
            result = obj.constructor ? new obj.constructor() : {};
            map.set(obj, result);
            for (let [k, v] of Object.entries(obj)) {
                result[k] = deepClone(v, map);
            }
            return result;

        case "[object Date]":
            return new Date(obj.getTime());

        case "[object RegExp]":
            var flags = "";
            if (obj.global) flags += "g";
            if (obj.multiline) flags += "m";
            if (obj.ignoreCase) flags += "i";
            return new RegExp(obj.source, flags);

        default:
            return obj;
    }
}
```

## 11. 实现一个 instanceOf

> ▶ 运行 demo：[handwritten-instanceof.html](handwritten-instanceof.html)

```js
function instanceOf(source, target) {
    let proto = source.__proto__;
    let prototype = target.prototype;
    while (proto) {
        if (proto === prototype) return true;
        proto = proto.__proto__;
    }
    return false;
}
```

> 浅谈 instanceof 和 typeof 的实现原理 https://juejin.cn/post/6844903613584654344

## 12. 简单实现 async/await 中的 async 函数

> ▶ 运行 demo：[handwritten-async.html](handwritten-async.html)

```js
function async(generator) {
    return new Promise(function(resolve, reject) {
        const it = generator();
        function step(next) {
            let result;
            try {
                result = next();
            } catch (e) {
                return reject(e);
            }
            if (result.done) {
                return resolve(result.value);
            }
            Promise.resolve(result.value).then(
                function(v) {
                    step(function() {
                        return it.next(v);
                    });
                },
                function(e) {
                    step(function() {
                        return it.throw(e);
                    });
                },
            );
        }
        step(function() {
            return it.next(undefined);
        });
    });
}
```

## 13. 基于 Promise 的 ajax 封装

> ▶ 运行 demo：[ajax-wrapper.html](ajax-wrapper.html)（需后端接口）

```js
function ajax(
    options = {
        url: "",
        method: "GET",
        data: {},
        timeout: 60,
    },
) {
    options.method = (options.method || "GET").toUpperCase();
    const paramString = formatParams(options.data);

    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.timeout = (options.timeout || 60) * 1000;

        if (options.method === "GET") {
            let url = options.url + (options.url.indexOf("?") > -1 ? "&" : "?") + paramString;
            xhr.open("GET", url);
            // xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (Linux; X11)");
            xhr.send(null);
        }

        if (options.method === "POST") {
            xhr.open("POST", options.url);
            // 设置请求头
            xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            // 跨域携带cookie
            // xhr.withCredentials = true;
            xhr.send(paramString);
        }

        xhr.onload = function() {
            const result = {
                status: xhr.status,
                statusText: xhr.statusText,
                headers: xhr.getAllResponseHeaders(),
                data: xhr.response || xhr.responseText,
            };
            if ((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304) {
                resolve(result);
            } else {
                reject(result);
            }
        };
        // 错误处理
        xhr.onerror = function() {
            reject(new TypeError("请求出错"));
        };
        xhr.ontimeout = function() {
            reject(new TypeError("请求超时"));
        };
        xhr.onabort = function() {
            reject(new TypeError("请求被终止"));
        };
    });
}

function formatParams(data) {
    let arr = [];
    for (var key in data) {
        if (data.hasOwnProperty(key)) arr.push(encodeURIComponent(key) + "=" + encodeURIComponent(data[key]));
    }
    return arr.join("&");
}
```

## 14. JSONP 的原理是什么？

> ▶ 运行 demo：[jsonp.html](jsonp.html)（需后端接口）

```js
function jsonp(url, data) {
    return new Promise((resolve, reject) => {
        // 1.将传入的data数据转化为url字符串形式
        var queryString = url.indexOf("?") == -1 ? "?" : "&";
        var arr = [];
        for (var key in data) {
            arr.push(key + "=" + encodeURIComponent(data[key]));
        }
        queryString += arr.join("&");
        // 2.处理url中的回调函数
        var callbackName =
            "jsonp_callback_" +
            Math.random()
                .toString(16)
                .replace(".", "");
        queryString += "&callback=" + callbackName;

        // 3.创建一个script标签并插入到页面中
        var script = document.createElement("script");
        script.src = url + queryString;

        // 4.挂载回调函数
        window[callbackName] = function(data) {
            resolve(data);
            // 处理完回调函数的数据之后，删除jsonp的script标签
            document.body.removeChild(script);
        };

        document.body.appendChild(script);
    });
}
```

## 15. 如何实现数组的随机排序？

> ▶ 运行 demo：[shuffle.html](shuffle.html)

用 Fisher–Yates Shuffle。核心是从后往前遍历，每次在「还没处理的区间」里随机取一个元素与当前位置交换，这样每种排列的概率均等。

不要用 `arr.sort(() => Math.random() - 0.5)`：比较函数返回值不一致会让排序结果偏向原始顺序，各排列的概率并不均等，而且不同引擎的排序算法不同，结果不可预期。

### 推荐：倒序遍历 + 解构交换

写法最短，且用解构交换省掉临时变量：

```js
function shuffle(arr) {
    let len = arr.length,
        random;
    while (len) {
        random = (Math.random() * len--) >>> 0; // 无符号右移运算符用于向下取整
        [arr[len], arr[random]] = [arr[random], arr[len]];
    }
    return arr;
}
```

### 等价写法：显式临时变量

同样是倒序 Fisher–Yates，只是用 `temp` 交换、下标算得更直白：

```js
function shuffle(arr) {
    var len = arr.length;
    for (var i = 0; i < len - 1; i++) {
        var random = Math.floor(Math.random() * (len - i));
        var temp = arr[random];
        arr[random] = arr[len - i - 1];
        arr[len - i - 1] = temp;
    }
    return arr;
}
```

### 正序遍历，返回新数组

上面两种都会原地修改入参。这种从前往后遍历、写入新数组，不改动原数组——需要保留原数组时用它：

```js
function shuffle(a) {
    var length = a.length;
    var shuffled = Array(length);

    for (var index = 0, rand; index < length; index++) {
        rand = ~~(Math.random() * (index + 1));
        if (rand !== index) shuffled[index] = shuffled[rand];
        shuffled[rand] = a[index];
    }

    return shuffled;
}
```

> 数组乱序 https://github.com/lessfish/underscore-analysis/issues/15

## 16. 实现异步循环打印

```js
var sleep = function(time, value) {
    return new Promise(function(resolve, reject) {
        setTimeout(function() {
            resolve(value);
        }, time);
    });
};

var start = async function() {
    for (let i = 0; i < 6; i++) {
        let result = await sleep(1000, i);
        console.log(result);
    }
};

start();
```

## 17. 深度优先遍历

### 推荐：非递归，用栈显式模拟

不受调用栈深度限制，DOM 层级很深时也不会爆栈。子节点要**倒序**入栈，弹出时才是从左到右的顺序：

```js
function deepTraversal(node) {
    let stack = [];
    let nodes = [];
    if (node) {
        stack.push(node);
        while (stack.length) {
            let item = stack.pop(); // 栈：后进先出
            let children = item.children;
            nodes.push(item);
            // 倒序入栈，保证先处理最左边的子节点
            for (let i = children.length - 1; i >= 0; i--) {
                stack.push(children[i]);
            }
        }
    }
    return nodes;
}
```

### 递归写法：传入数组累积结果

递归版更短，但层级过深会栈溢出。这一版把结果数组一路传下去，只有一个数组，没有额外分配：

```js
function deepTraversal1(node, nodeList = []) {
    if (node !== null) {
        nodeList.push(node);
        let children = node.children;
        for (let i = 0; i < children.length; i++) {
            deepTraversal1(children[i], nodeList);
        }
    }
    return nodeList;
}
```

### 递归写法：靠返回值拼接

逻辑上更「纯」，但每层递归都要 `concat` 出一个新数组，节点多时开销明显高于上一版：

```js
function deepTraversal2(node) {
    let nodes = [];
    if (node !== null) {
        nodes.push(node);
        let children = node.children;
        for (let i = 0; i < children.length; i++) {
            nodes = nodes.concat(deepTraversal2(children[i]));
        }
    }
    return nodes;
}
```

## 18. 广度优先遍历

和深度优先的非递归版只差一个数据结构：把**栈**换成**队列**（`pop` 换成 `shift`），就从「一路走到底」变成「逐层展开」。子节点正序入队即可。

```js
function BFS(node) {
    let nodes = [];
    let queue = []; // 队列：先进先出
    if (node) {
        queue.push(node);
        while (queue.length) {
            let item = queue.shift();
            let children = item.children;
            nodes.push(item);
            for (let i = 0; i < children.length; i++) {
                queue.push(children[i]);
            }
        }
    }
    return nodes;
}
```

## 19. 解析 url 参数

> ▶ 运行 demo：[parse-url-params.html](parse-url-params.html)

```js
var q = function(url) {
    let result = {};
    const query = url.split("?")[1];
    if (!query) return result;
    const pairs = query.split("&");
    pairs.forEach(pair => {
        let [key, value] = pair.split("=");
        try {
            value = value ? decodeURIComponent(value).replace(/\+/g, " ") : "";
        } catch (e) {
            return;
        }
        if (/^\d+(\.\d+)?$/.test(value)) {
            value = Number(value);
        }
        if (typeof result[key] === "undefined") {
            result[key] = value;
        } else {
            result[key] = [].concat(result[key], value);
        }
    });
    return result;
};
```

## 数组 flatten

原生已有 `Array.prototype.flat(depth)`，`arr.flat(Infinity)` 即可完全展开。下面是手写实现。

### 推荐：reduce 递归

```js
function flatten(array) {
    return array.reduce((result, current) => {
        return Array.isArray(current) ? result.concat(flatten(current)) : result.concat(current);
    }, []);
}

console.log(flatten([1, [2, [[3, 4], 5], 6]])); // [1, 2, 3, 4, 5, 6]
console.log(flatten(["abc", ["a", [[3, "a"], { a: "a" }], null, false]]));
```

### 等价写法：显式循环

逻辑与上面完全一致，只是把 `reduce` 展开成 `for`：

```js
var flatten = function(array) {
    var result = [];
    for (var i = 0, length = array.length; i < length; i++) {
        var value = array[i];
        if (Array.isArray(value)) {
            result = result.concat(flatten(value));
        } else {
            result.push(value);
        }
    }
    return result;
};
```

## 解析 url

> ▶ 运行 demo：[parse-url-params.html](parse-url-params.html)

### 推荐：交给浏览器解析

不要自己写正则去拆 URL，边界情况太多（IPv6 地址、编码字符、相对路径、默认端口）。浏览器和 Node 都内置了 `URL`：

```js
function parseURL(url) {
    const u = new URL(url); // Node 与浏览器均支持
    return {
        href: u.href,
        origin: u.origin,
        protocol: u.protocol,
        host: u.host, // 含端口
        hostname: u.hostname, // 不含端口
        port: u.port,
        pathname: u.pathname,
        search: u.search,
        hash: u.hash,
        params: Object.fromEntries(u.searchParams), // 顺带拿到解析好的查询参数
    };
}

console.log(parseURL("https://www.cnblogs.com:8080/speeding/p/5097790.html?xxx=9999#test"));
```

早期常用的 `a` 标签技巧，原理是让浏览器的 URL 解析器做事，效果和 `new URL` 一样，但依赖 DOM，Node 环境用不了：

```js
function URLParser(url) {
    const a = document.createElement("a");
    a.href = url;
    return {
        protocol: a.protocol,
        hostname: a.hostname,
        port: a.port,
        pathname: a.pathname,
        search: a.search,
        hash: a.hash,
    };
}
```

### 手写正则（面试题写法）

只覆盖常见的 `协议://主机:端口/路径?查询#片段` 形式，不要用在生产代码里：

```js
var parseURLByRegExp = function(url) {
    var result = {};
    var keys = ["href", "origin", "protocol", "host", "hostname", "port", "pathname", "search", "hash"];
    var regexp = /(((?:https?|ftp|file):)\/\/(([^:\/\?#]+)(:\d+)?))(\/[^?#]*)?(\?[^#]*)?(#.*)?/;

    var match = regexp.exec(url);
    if (match) {
        for (var i = keys.length - 1; i >= 0; i--) {
            result[keys[i]] = match[i] ? match[i] : "";
        }
    }
    return result;
};
```

## 数组去重

### 推荐：Set

```js
const unique = arr => [...new Set(arr)];

console.log(unique([1, 2, 3, 3, 4, 4, 5, 5, 6, 1, 9, 3, 25, 4])); // [1, 2, 3, 4, 5, 6, 9, 25]
```

### 不依赖 Set 的写法

`indexOf` 逐个回查，时间复杂度 O(n²)，数据量大时明显慢于 `Set`：

```js
var unique = function(arr) {
    const result = [];
    arr.forEach(item => {
        if (result.indexOf(item) === -1) result.push(item);
    });
    return result;
};
```

两者对 `NaN` 的行为不同：`Set` 认为 `NaN` 等于自身，能正确去重；`indexOf` 内部用 `===` 比较，`NaN === NaN` 为 `false`，重复的 `NaN` 会被全部保留。

## 转义函数 escapeHtml

```js
var escapeMap = {
    "<": "&lt;",
    ">": "&gt;",
    "&": "&amp;",
    '"': "&quot;",
    "'": "&#x27;",
    "`": "&#x60;",
};

var escapeHtml = function(htmlStr) {
    var source = "(?:" + Object.keys(escapeMap).join("|") + ")";
    var reg = RegExp(source, "g");
    return htmlStr.replace(reg, function(match) {
        return escapeMap[match];
    });
};
```

## 千位分隔

> ▶ 运行 demo：[thousands-separator-template-engine.html](thousands-separator-template-engine.html)

把浮点数小数点左边的部分每三位插一个逗号，如 `12000000.11` → `12,000,000.11`。

外层 `/\d+/` 不带 `g`，只匹配第一段连续数字（即整数部分），所以小数部分不会被插逗号，负号也会原样保留。内层 `(\d)(?=(\d{3})+$)` 用前向断言找「后面剩余位数正好是 3 的整数倍」的数字，在它后面补逗号。

```js
function milliFormat(num) {
    return (
        num &&
        num.toString().replace(/\d+/, function(s) {
            return s.replace(/(\d)(?=(\d{3})+$)/g, "$1,");
        })
    );
}

milliFormat(12000000.11); // "12,000,000.11"
milliFormat(-1200000123123.223); // "-1,200,000,123,123.223"
```

注意 `num &&` 这个短路：传入 `0` 时直接返回数字 `0` 而不是字符串 `"0"`，返回类型不一致。要修就把它换成 `num == null ? "" : ...`。

实际项目里直接用原生方法，不用手写：

```js
(12000000.11).toLocaleString("en-US", { maximumFractionDigits: 20 }); // "12,000,000.11"
new Intl.NumberFormat("en-US").format(12000000); // "12,000,000"
```

## 模板引擎

> ▶ 运行 demo：[thousands-separator-template-engine.html](thousands-separator-template-engine.html)

用正则匹配 `{{ key }}` 占位符，再用 `data` 里的同名字段替换掉。

```js
function render(template, data) {
    return template.replace(/{{\s*(\w+)\s*}}/g, function(match, key) {
        // 用 == null 判断，只把 undefined 和 null 当作缺失
        return data[key] == null ? "" : data[key];
    });
}

var t = '<p><a href="{{url}}">{{name}}</a><span>{{greeting}}</span></p>';
console.log(
    render(t, {
        url: "https://www.example.com",
        name: "Example",
        greeting: "Welcome",
    }),
);
```

原版写的是 `data[b] || ""`，会把 `0`、`false`、空字符串这些**合法但为假值**的数据一并替换成空串，比如 `render("{{count}}", { count: 0 })` 会得到空字符串而不是 `"0"`。改用 `== null` 判断只排除 `undefined` 和 `null`。

这个实现直接把数据拼进 HTML，**不做转义**，渲染用户输入会导致 XSS。配合上面的 `escapeHtml` 使用。

> Underscore \_.template 方法使用详解 https://github.com/lessfish/underscore-analysis/issues/26

## 数据结构与算法

> ▶ 运行 demo：[data-structures.js](data-structures.js) · [sort-algorithms.js](sort-algorithms.js)

> 窥探数据结构的世界- ES6 版 https://juejin.cn/post/6844903840681033742

> 在 JavaScript 中学习数据结构与算法 https://juejin.cn/post/6844903482432962573

> 十大经典排序算法 https://www.cnblogs.com/onepixel/p/7674659.html

> Data Structure Visualizations https://www.cs.usfca.edu/~galles/visualization/Algorithms.html

> 从斐波那契数列求值优化谈 \_.memoize 方法 https://github.com/lessfish/underscore-analysis/issues/23

## 请分别用深度优先思想和广度优先思想实现一个拷贝函数

两者拷贝出的结果完全一样，区别只在遍历顺序：深度优先靠递归一路钻到底，广度优先用队列逐层展开。都不处理循环引用，需要的话参考第 10 节的 `Map` 缓存做法。

```js
function DFClone(obj) {
    // 基本数据类型和 null 直接返回
    if (typeof obj !== "object" || obj === null) {
        return obj;
    }

    const result = Array.isArray(obj) ? [] : {};

    // 递归遍历每个属性，遇到引用类型就往下钻
    for (const key in obj) {
        result[key] = DFClone(obj[key]); // 递归调用自身，不是第 10 节的 deepClone
    }

    return result;
}

function BFClone(obj) {
    // 基本数据类型和 null 直接返回
    if (typeof obj !== "object" || obj === null) {
        return obj;
    }

    const result = Array.isArray(obj) ? [] : {};

    // 两个队列并行推进：queue 存待拷贝的源节点，resQueue 存对应的目标节点
    const queue = [obj];
    const resQueue = [result];

    while (queue.length > 0) {
        const curObj = queue.shift();
        const curRes = resQueue.shift();

        for (const key in curObj) {
            const val = curObj[key];
            if (typeof val === "object" && val !== null) {
                // 引用类型：先建好空壳挂上去，再连同源节点一起入队，下一轮再填内容
                const newVal = Array.isArray(val) ? [] : {};
                curRes[key] = newVal;
                queue.push(val);
                resQueue.push(newVal);
            } else {
                curRes[key] = val;
            }
        }
    }

    return result;
}
```