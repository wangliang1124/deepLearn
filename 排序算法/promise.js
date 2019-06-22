// 定义Promise的三种状态常量
const PENDING = 'pending'
const FULFILLED = 'fulfilled'
const REJECTED = 'rejected'

class Promise {
    static resolve() { }
    static reject() { }
    static all() { }
    static race() { }
    constructor(executor) {
        this.status = PENDING
        this.value = undefined
        this.reason = undefined
        this.onFulfilledCallbacks = []
        this.onRejectedCallbacks = []
        // const resolve = (value) => {
        //     if (this.status === PENDING) {
        //         this.status = FULFILLED
        //         this.value = value
        //         this.onFulfilledCallbacks.forEach(fn => fn())
        //     }
        // }
        function resolve(value) {
            setTimeout((value) => {
                if (this.status === PENDING) {
                    this.status = FULFILLED
                    this.value = value
                    this.onFulfilledCallbacks.forEach(fn => fn())
                }
            }, 0)
        }
        // const reject = (reason) => {
        //     if (this.status === PENDING) {
        //         this.status = REJECTED
        //         this.reason = reason
        //         this.onRejectedCallbacks.forEach(fn => fn())
        //     }
        // }
        function reject(reason) {
            setTimeout((reason) => {
                if (this.status === PENDING) {
                    this.status = REJECTED
                    this.reason = reason
                    this.onRejectedCallbacks.forEach(fn => fn())
                }
            }, 0)
        }

        try {
            executor(resolve, reject)
        } catch (error) {
            reject(error)
        }
    }
    then(onFulfilled, onRejected) {
        onFulfilled = typeof onFulfilled === 'function' ? onFulfilled : value => value
        onRejected = typeof onRejected === 'function' ? onRejected : reason => { throw reason }

        const self = this;
        const promiseThen = new Promise((resolve, reject) => {
            switch (self.status) {
                case FULFILLED:
                    try {
                        let x = onFulfilled(self.value)
                        resolvePromise(promiseThen, x, resolve, reject);
                    } catch (error) {
                        reject(error)
                    }
                    break;
                case REJECTED:
                    try {
                        let x = onRejected(self.reason)
                        resolvePromise(promiseThen, x, resolve, reject);
                    } catch (error) {
                        reject(error)
                    }
                    break;
                case PENDING:
                    this.onFulfilledCallbacks.push(() => {
                        try {
                            let x = onFulfilled(self.value);
                            resolvePromise(promiseThen, x, resolve, reject);
                        } catch (error) {

                        }
                    })
                    this.onRejectedCallbacks.push(() => {
                        try {
                            let x = onRejected(self.reason);
                            resolvePromise(promiseThen, x, resolve, reject);
                        } catch (error) {
                            reject(error)
                        }
                    })
                    break;
            }
        })
        return promiseThen;
    }
    catch() { }
    finally() { }
}

function resolvePromise(promise, x, resolve, reject) {
    let self = this;
    if (promise === x) { reject(new TypeError('循环引用')) }
    if (x && typeof x === 'object' || typeof x === 'function') {
        let resolved = false;
        try {
            let then = x.then;
            if (typeof then === 'function') {
                then.call(x, (y) => {
                    if (resolved) return;
                    resolvePromise(promise, y, resolve, reject);
                    resolved = true;
                }, (err) => {
                    if (resolved) return;
                    reject(err)
                    resolved = true;
                })
            } else {
                if (resolved) return;
                resolve(x)
                resolved = true;
            }

        } catch (error) {
            if (resolved) return;
            reject(error)
            resolved = true;
        }
    } else {
        resolve(x)
    }

}
Promise.defer = Promise.deferred = function () {
    let dfd = {};
    dfd.promise = new Promise((resolve, reject) => {
        dfd.resolve = resolve;
        dfd.reject = reject;
    });
    return dfd;
}


export default Promise;