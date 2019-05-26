// 1. 实现一个new操作符
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

function A() {
    console.log(...arguments);
}
const instance = New(A, "测试", 23233);
console.log(instance, instance instanceof A);
