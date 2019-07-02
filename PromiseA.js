/**
 * 2.1. Promise States
 *      A promise must be in one of three states:
 *      pending, fulfilled, or rejected.
 */
const STATE_PENDING = "pending";
const STATE_FULFILLED = "fulfilled";
const STATE_REJECTED = "rejected";

function PromiseA(fn) {
    this._state = STATE_PENDING;
    this._value = undefined;
    this._callbacks = [];
    this._errorbacks = [];

    /**
     * 2.3. The Promise Resolution Procedure
     *      The promise resolution procedure is an abstract operation
     *      taking as input a promise and a value, which we denote as
     *      [[Resolve]](promise, x)
     */
    var executed = false; // 用于保证resolve接口只有第一次被触发时有效；
    function resolve(promise, x) {
        if (executed) {
            return;
        }
        executed = true;

        var innerResolve = (promise, x) => {
            if (promise === x) {
                // 2.3.1. If promise and x refer to the same object,
                //        reject promise with a TypeError as the reason.
                this._reject(new TypeError("出错了, promise === x, 会造成死循环!"));
            } else if (x instanceof PromiseA) {
                // 2.3.2. If x is a promise, adopt its state [3.4]:
                //      2.3.2.1. If x is pending, promise must remain pending until x is fulfilled or rejected.
                //       2.3.2.2. If/when x is fulfilled, fulfill promise with the same value.
                //      2.3.2.3. If/when x is rejected, reject promise with the same reason.
                if (x._state == STATE_PENDING) {
                    x.then(
                        value => {
                            innerResolve(promise, value);
                        },
                        reason => {
                            this._reject(reason);
                        },
                    );
                } else if (x._state == STATE_FULFILLED) {
                    this._fulfill(x._value);
                } else if (x._state == STATE_REJECTED) {
                    this._reject(x._value);
                }
            } else if (x && (typeof x == "function" || typeof x == "object")) {
                // 2.3.3. Otherwise, if x is an object or function,
                try {
                    // 2.3.3.1. Let then be x.then.
                    let then = x.then;

                    if (typeof then === "function") {
                        //thenable
                        var executed = false;
                        try {
                            // 2.3.3.3. If then is a function, call it with x as this,
                            //          first argument resolvePromise, and
                            //          second argument rejectPromise,
                            //          where:
                            then.call(
                                x,
                                value => {
                                    // 2.3.3.3.3. If both resolvePromise and rejectPromise are called,
                                    //            or multiple calls to the same argument are made,
                                    //            the first call takes precedence, and any further calls are ignored.
                                    if (executed) {
                                        return;
                                    }
                                    executed = true;
                                    // 2.3.3.3.1. If/when resolvePromise is called with a value y,
                                    //            run [[Resolve]](promise, y).
                                    innerResolve(promise, value);
                                },
                                reason => {
                                    // 2.3.3.3.3. If both resolvePromise and rejectPromise are called,
                                    //            or multiple calls to the same argument are made,
                                    //            the first call takes precedence, and any further calls are ignored.
                                    if (executed) {
                                        return;
                                    }
                                    executed = true;
                                    // 2.3.3.3.2. If/when rejectPromise is called with a reason r,
                                    //            reject promise with r.
                                    this._reject(reason);
                                },
                            );
                        } catch (e) {
                            // 2.3.3.3.4. If calling then throws an exception e,
                            //          2.3.3.3.4.1. If resolvePromise or rejectPromise have been called, ignore it.
                            if (executed) {
                                return;
                            }
                            //          2.3.3.3.4.2. Otherwise, reject promise with e as the reason.
                            throw e;
                        }
                    } else {
                        // 2.3.3.4. If then is not a function, fulfill promise with x.
                        this._fulfill(x);
                    }
                } catch (ex) {
                    // 2.3.3.2. If retrieving the property x.then results in a thrown exception e,
                    //          reject promise with e as the reason.
                    this._reject(ex);
                }
            } else {
                // 2.3.4. If x is not an object or function, fulfill promise with x.
                this._fulfill(x);
            }
        };
        innerResolve(promise, x);
    }

    function reject(promise, reason) {
        this._reject(reason);
    }

    resolve = resolve.bind(this, this); // 通过bind模拟规范中的 [[Resolve]](promise, x) 行为
    reject = reject.bind(this, this);

    fn(resolve, reject); // new PromiseA((resolve, reject) => { ... })
}

/**
 * 2.1. Promise States
 *
 * A promise must be in one of three states: pending, fulfilled, or rejected.
 *
 * 2.1.1. When pending, a promise:
 *      2.1.1.1 may transition to either the fulfilled or rejected state.
 * 2.1.2. When fulfilled, a promise:
 *      2.1.2.1 must not transition to any other state.
 *      2.1.2.2 must have a value, which must not change.
 * 2.1.3. When rejected, a promise:
 *      2.1.3.1 must not transition to any other state.
 *      2.1.3.2 must have a reason, which must not change.
 *
 * Here, “must not change” means immutable identity (i.e. ===),
 * but does not imply deep immutability.
 */
PromiseA.prototype._fulfill = function(value) {
    if (this._state == STATE_PENDING) {
        this._state = STATE_FULFILLED;
        this._value = value;

        this._notify(this._callbacks, this._value);

        this._errorbacks = [];
        this._callbacks = [];
    }
};
PromiseA.prototype._reject = function(reason) {
    if (this._state == STATE_PENDING) {
        this._state = STATE_REJECTED;
        this._value = reason;

        this._notify(this._errorbacks, this._value);

        this._errorbacks = [];
        this._callbacks = [];
    }
};
PromiseA.prototype._notify = function(fns, param) {
    setTimeout(() => {
        for (var i = 0; i < fns.length; i++) {
            fns[i](param);
        }
    }, 0);
};

/**
 * 2.2. The then Method
 *      A promise’s then method accepts two arguments:
 *           promise.then(onFulfilled, onRejected)
 */
PromiseA.prototype.then = function(onFulFilled, onRejected) {
    // 2.2.7. then must return a promise [3.3].
    //            promise2 = promise1.then(onFulFilled, onRejected);
    //
    return new PromiseA((resolve, reject) => {
        // 2.2.1. Both onFulfilled and onRejected are optional arguments:
        //      2.2.1.1. If onFulfilled is not a function, it must be ignored.
        //      2.2.1.2. If onRejected is not a function, it must be ignored.
        if (typeof onFulFilled == "function") {
            this._callbacks.push(function(value) {
                try {
                    // 2.2.5. onFulfilled and onRejected must be called as functions (i.e. with no this value)
                    var value = onFulFilled(value);
                    resolve(value);
                } catch (ex) {
                    // 2.2.7.2. If either onFulfilled or onRejected throws an exception e,
                    //          promise2 must be rejected with e as the reason.
                    reject(ex);
                }
            });
        } else {
            // 2.2.7.3. If onFulfilled is not a function and promise1 is fulfilled,
            //          promise2 must be fulfilled with the same value as promise1.
            this._callbacks.push(resolve); // 值穿透
        }

        if (typeof onRejected == "function") {
            this._errorbacks.push(function(reason) {
                try {
                    // 2.2.5. onFulfilled and onRejected must be called as functions (i.e. with no this value)
                    var value = onRejected(reason);
                    resolve(value);
                } catch (ex) {
                    // 2.2.7.2. If either onFulfilled or onRejected throws an exception e,
                    //          promise2 must be rejected with e as the reason.
                    reject(ex);
                }
            });
        } else {
            // 2.2.7.4. If onRejected is not a function and promise1 is rejected,
            //          promise2 must be rejected with the same reason as promise1.
            this._errorbacks.push(reject); // 值穿透
        }

        // 2.2.6. then may be called multiple times on the same promise.
        //      2.2.6.1. If/when promise is fulfilled, all respective onFulfilled callbacks must
        //               execute in the order of their originating calls to then.
        //      2.2.6.2. If/when promise is rejected, all respective onRejected callbacks must
        //               execute in the order of their originating calls to then.
        if (this._state == STATE_REJECTED) {
            // 2.2.4. onFulfilled or onRejected must not be called until the
            //        execution context stack contains only platform code.
            this._notify(this._errorbacks, this._value);
            this._errorbacks = [];
            this._callbacks = [];
        } else if (this._state == STATE_FULFILLED) {
            // 2.2.4. onFulfilled or onRejected must not be called until the
            //        execution context stack contains only platform code.
            this._notify(this._callbacks, this._value);
            this._errorbacks = [];
            this._callbacks = [];
        }
    });
};

PromiseA.prototype.catch = function(onRejected) {
    return this.then(null, onRejected);
};
PromiseA.resolve = function(value) {
    return new PromiseA((resolve, reject) => resolve(value));
};
PromiseA.reject = function(reason) {
    return new PromiseA((resolve, reject) => reject(reason));
};
PromiseA.all = function(values) {
    return new Promise((resolve, reject) => {
        var result = [],
            remaining = values.length;
        function resolveOne(index) {
            return function(value) {
                result[index] = value;
                remaining--;
                if (!remaining) {
                    resolve(result);
                }
            };
        }
        for (var i = 0; i < values.length; i++) {
            PromiseA.resolve(values[i]).then(resolveOne(i), reject);
        }
    });
};
PromiseA.race = function(values) {
    return new Promise((resolve, reject) => {
        for (var i = 0; i < values.length; i++) {
            PromiseA.resolve(values[i]).then(resolve, reject);
        }
    });
};

module.exports = PromiseA;
