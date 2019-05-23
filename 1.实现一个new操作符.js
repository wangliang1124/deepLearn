// 1. 实现一个new操作符
function New() {
    let obj = {}
    const constructor = Array.prototype.shift.call(arguments)
    if (typeof constructor !== 'function') {
        return console.warn(`${constructor} is not a constructor`)
    }
    obj.__proto__ = constructor.prototype
    const ret = constructor.apply(obj, arguments)
    if (ret !== null && (typeof ret === 'object' || typeof ret === 'function')) {
        return ret
    }
    return obj
}

function A() {
    console.log(...arguments)
}
const instance = New(A, '测试', 23233)
console.log(instance, instance instanceof A)