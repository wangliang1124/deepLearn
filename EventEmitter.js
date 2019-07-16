// 观察者模式： 请实现一个 EventEmitter 类（） 继承自此类的对象都会拥有两个方法 on, off, once 和 trigger
var EventEmitter = function () {
    if (!this instanceof Event) {
        return new Event()
    }
    this._callbacks = {}
}
EventEmitter.prototype = {
    constructor: EventEmitter,
    on: function (type, handler) {
        this._callbacks = this._callbacks || {}
        this._callbacks[type] = this._callbacks[type] || []
        this._callbacks[type].push(handler)
        return this
    },
    off: function (type, handler) {
        var list = this._callbacks[type]
        if (list.length) {
            for (var i = list.length - 1; i >= 0; i--) {
                if (list[i] === handler) {
                    list.splice(i, 1)
                }
            }
        }
        return this
    },
    emit: function (type, data) {
        var list = this._callbacks[type]
        var len = list.length
        if (len) {
            for (var i = 0; i < len; i++) {
                list[i].call(this, data)
            }
        }
    },
    once: function (type, handler) {
        var self = this
        var wrapper = function () {
            handler.apply(self, arguments)
            self.off(type, wrapper)
        }
        this.on(type, wrapper)
        return this
    }
}