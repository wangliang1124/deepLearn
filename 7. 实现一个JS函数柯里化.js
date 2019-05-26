// 7. 实现一个JS函数柯里化
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
