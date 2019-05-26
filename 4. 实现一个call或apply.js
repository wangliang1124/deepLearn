// 4. 实现一个call或apply
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

// 用ES6实现
// Function.prototype.call = function (context = window, ...args) {
//     context.fn = this;
//     let result = context.fn(...args);
//     delete context.fn;
//     return result;
// };

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
    name: "我是obj的name",
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


// 实现 apply
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
