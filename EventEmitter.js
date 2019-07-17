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
        const eventHandlers = this.eventQueue[type];
        for (let i = eventHandlers.length - 1; i >= 0; i--) {
            if (eventHandlers[i] === handler) {
                eventHandlers.splice(i, 1);
            }
        }

        return this;
    },

    emit: function(type, data) {
        const eventHandlers = this.eventQueue[type];
        for (let i = 0; i < eventHandlers.length; i++) {
            const handler = eventHandlers[i];
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
