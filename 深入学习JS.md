## 1.实现一个 new 操作符

```js
function New() {
    var obj = {};
    var constructor = Array.prototype.shift.call(arguments);
    if (typeof constructor !== "function") {
        return console.warn(`${constructor} is not a constructor`);
    }
    obj.__proto__ = constructor.prototype;
    var ret = constructor.apply(obj, arguments);
    if (typeof ret === "function" || (typeof ret === "object" && ret !== null)) {
        return ret;
    }
    return obj;
}

console.log("============== 测试 ===============");
function A() {
    console.log(...arguments);
}
const instance = New(A, "测试", 23233);
console.log(instance, instance instanceof A);
```

## 2.实现一个 JSON.stringify

```js
function stringify(obj) {
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
    let result = "";
    switch (Object.prototype.toString.call(obj)) {
        case "[object Array]":
            result += "[";
            for (let v of obj) {
                const val = stringify(v);
                result += `${val === undefined ? null : val},`;
            }
            // 去掉最后一个逗号
            if (result !== "[") {
                result = result.slice(0, -1);
            }
            return (result += "]");
        case "[object Object]":
            result += "{";
            for (let key in obj) {
                if (obj.hasOwnProperty(key)) {
                    const val = stringify(obj[key]);
                    if (val !== undefined) {
                        result += `"${key}": ${val},`;
                    }
                }
            }
            if (result !== "{") {
                result = result.slice(0, -1);
            }
            return (result += "}");
        case "[object Date]":
            return `"${obj.toJSON ? obj.toJSON() : obj.toString()}"`;
        default:
            return "{}";
    }
}

console.log(stringify(Object));
console.log(stringify(null));
console.log(stringify(2));
console.log(stringify(false));
console.log(stringify("false"));
console.log(stringify({ a: 1, b: 2 }));
console.log(
    stringify([
        false,
        Symbol(),
        Symbol,
        new Date(),
        new Error("测试"),
        undefined,
        "测试",
        null,
        /./,
        { a: 1, b: 2, c: null },
        [1, undefined],
        Number(1),
    ]),
);
```

## 3.实现 JSON.parse

```js
function jsonParse(json) {
    return eval("(" + json + ")");
}
function jsonParse2(json) {
    return new Function("return " + json)();
}
console.log(
    JSON.stringify([
        false,
        Symbol(),
        Symbol,
        new Date(),
        new Error("测试"),
        undefined,
        "测试",
        null,
        /./,
        { a: 1, b: 2, c: null },
        [1, undefined],
        Number(1),
    ]),
);
```

> JSON.parse 三种实现方式 https://github.com/youngwind/blog/issues/115

## 4.实现一个 call 或 apply

### 实现 call

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

// 测试 1
let foo = {
    value: 1,
};
function bar(name, age) {
    console.log(name);
    console.log(age);
    console.log(this.value);
    return "aaaa";
}
bar._call(foo, "black", "18");

// 测试 2
function test(str, fn, obj, arr) {
    console.log(this.name);
    console.log(str);
    fn();
    console.log(obj);
    console.log(arr);
}

var obj = {
    name: "我是 obj 的 name",
};

test._call(
    obj,
    "string",
    function() {
        var fnStr = "this is a string in function";
        console.log(fnStr);
    },
    { color: "red" },
    [1, 2, 3],
);
```

### 用 ES6 实现 call

```js
Function.prototype._call = function(context = window, ...args) {
    context.fn = this;
    let result = context.fn(...args);
    delete context.fn;
    return result;
};
```

### 实现 apply

```js
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

test._apply(obj, [
    "哈哈哈",
    function() {
        var fnStr = "this is a string in function";
        console.log(fnStr);
    },
    { color: "red" },
    [1, 2, 3],
]);
```

## 5.实现一个 Function.bind

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
        return source.apply(this instanceof fNOP ? this : context, args.concat(bindArgs));
    };

    // Function.prototype doesn't have a prototype property
    if (source.prototype) {
        fNOP.prototype = source.prototype;
    }
    bound.prototype = new fNOP();

    return bound;
};
console.log("============== bind ==================");
// 测试
function testBind(name) {
    this.name = name;
}
var obj = {};
var bar = testBind._bind(obj);
bar("Jack");
console.log(obj.name); // Jack
var alice = new bar("Alice");
console.log(obj.name); // Jack
console.log(alice.name); // Alice
```

### 另一种写法，参考 underscore

```js
var bound = function() {
    var bindArgs = Array.prototype.slice.call(arguments);
    if (!(this instanceof bound)) {
        return source.apply(context, args.concat(bindArgs));
    }
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

## 6.实现一个 Object.create

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

## 7.实现一个 JS 函数柯里化

```js
function currying(fn, args) {
    var len = fn.length;
    var args = args || [];
    return function() {
        var newArgs = args.concat([].slice.call(arguments));
        if (newArgs.length === len) {
            return fn.apply(this, newArgs);
        }
        return currying.call(this, fn, newArgs);
    };
}

console.log("============== currying ==================");
function multiFn(a, b, c) {
    return a * b * c;
}

var multi = currying(multiFn);
console.log(multi(2)(3)(4), multi(2, 3, 4), multi(2)(3, 4), multi(2, 3)(4));
```

## 8.实现 Promise

```js
```

## 9.实现防抖和节流

### 防抖 debounce

```js
```

### 节流 throttle

```js
```

## 10.实现一个 JS 深拷贝

```js
```

## 11.实现一个 instanceOf

```js
function instanceOf(source, target) {
    var proto = source.__proto__;
    let prototype = target.prototype;
    while (true) {
        if (proto === null) return false;
        if (proto === prototype) return true;
        proto = proto.__proto__;
    }
}
```
