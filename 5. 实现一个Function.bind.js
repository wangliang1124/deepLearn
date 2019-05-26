// 5. 实现一个Function.bind
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

// 另一种写法，参考underscore
/* var bound = function() {
    var bindArgs = Array.prototype.slice.call(arguments);
    if (!(this instanceof bound)) {
        return source.apply(context, args.concat(bindArgs));
    }
    if (source.prototype) {
        fNOP.prototype = source.prototype;
    }
    var newObj = new fNOP();
    var ret = source.apply(newObj, args.concat(bindArgs));
    if (ret !== null && (typeof ret === 'object' || typeof ret === 'function')) {
        return ret
    }
    return newObj;
}; */
