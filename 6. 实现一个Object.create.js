// 6. 实现一个Object.create
function create(proto) {
    if (Object.create) {
        return Object.create(proto);
    }
    function F() {}
    F.prototype = proto;
    return new F();
}
