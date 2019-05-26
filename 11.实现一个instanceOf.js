// 11.实现一个instanceOf
function instanceOf(source, target) {
    var proto = source.__proto__;
    let prototype = target.prototype;
    while (true) {
        if (proto === null) return false;
        if (proto === prototype) return true;
        proto = proto.__proto__;
    }
}
