 /* 2. 实现一个JSON.stringify */
 function stringify(obj) {
    const type = typeof obj;
    if (/undefined|function|symbol/.test(type)) {
        return undefined
    }
    if (/string|number|boolean/.test(type) || obj === null) {
        return `"${obj}"`
    }
    const arr = Array.isArray(obj) ? obj : Object.values(obj)
    let json = []
    for (let i = 0, len = arr.length; i < len; i++) {
        let v = arr[i]
        let type = typeof v;
        if (/undefined|function|symbol/.test(type) || obj === null) {
            json.push(null)
        } else {
            json.push(v)
        }
    }
    console.log(json)

    return '"[' + String(json) + ']"';
}

console.log(stringify(Object))
console.log(stringify(null))
console.log(stringify(2))
console.log(stringify(false)