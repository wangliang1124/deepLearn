/* 实现一个 EventEmitter(观察者模式) 类,拥有 on, off, once 和 emit 方法 */
const EventEmitter = function() {
    this.eventQueue = {};
};

EventEmitter.prototype = {
    constructor: EventEmitter,

    on: function(type, handler) {
        this.eventQueue[type] = this.eventQueue[type] || [];
        this.eventQueue[type].push(handler);
        return this;
    },

    off: function(type, handler) {
        const handlers = this.eventQueue[type];
        for (let i = handlers.length - 1; i >= 0; i--) {
            if (handlers[i] === handler) {
                handlers.splice(i, 1);
            }
        }

        return this;
    },

    emit: function(type, data) {
        const handlers = this.eventQueue[type];
        if (!handlers || handlers.length === 0) return;
        for (let i = 0; i < handlers.length; i++) {
            const handler = handlers[i];
            handler && handler(data);
        }
        return this;
    },

    once: function(type, handler) {
        this.on(type, data => {
            handler && handler(data);
            this.off(type, wrapper);
        });
        return this;
    },
};

export default new EventEmitter();
