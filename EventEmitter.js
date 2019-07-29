/* 实现一个 EventEmitter(观察者模式) 类,拥有 on, off, once 和 emit 方法 */
function EventEmitter() {
    this.eventQueue = {};
}

EventEmitter.prototype = {
    constructor: EventEmitter,

    on: function(type, handler) {
        this.eventQueue[type] = this.eventQueue[type] || [];
        this.eventQueue[type].push(handler);
        return this;
    },

    off: function(type, handler) {
        let handlers = this.eventQueue[type];
        for (let i = 0; i < handlers.length; i++) {
            if (handler === handlers[i]) {
                this.eventQueue[type].splice(i, 1);
            }
        }
        return this;
    },

    once: function(type, handler) {
        const self = this;
        const wrapper = function(...args) {
            handler && handler.call(null, ...args);
            self.off(type, wrapper);
        };
        this.on(type, wrapper);
        return this;
    },

    emit: function(type, ...args) {
        let handlers = this.eventQueue[type];
        if (!handlers || handlers.length === 0) return;
        for (let i = 0; i < handlers.length; i++) {
            let handler = handlers[i];
            handler && handler.call(null, ...args);
        }
        return this;
    },
};
export default new EventEmitter();
