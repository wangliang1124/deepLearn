// 2. 实现一个JSON.stringify
function stringify(obj) {
    const type = typeof obj;
    if (/undefined|function|symbol/.test(type)) {
        return undefined;
    }
    if (/number|boolean/.test(type) || obj === null) {
        return String(obj);
    }
    if (type === "string") {
        return `"${obj}"`;
    }
    let result = "";
    switch (Object.prototype.toString.call(obj)) {
        case "[object Array]":
            result += "[";
            for (let v of obj) {
                const val = stringify(v);
                result += `${val === undefined ? null : val},`;
            }
            // 去掉最后一个逗号
            if (result !== "[") {
                result = result.slice(0, -1);
            }
            return (result += "]");
        case "[object Object]":
            result += "{";
            for (let key in obj) {
                if (obj.hasOwnProperty(key)) {
                    const val = stringify(obj[key]);
                    if (val !== undefined) {
                        result += `"${key}": ${val},`;
                    }
                }
            }
            if (result !== "{") {
                result = result.slice(0, -1);
            }
            return (result += "}");
        case "[object Date]":
            return `"${obj.toJSON ? obj.toJSON() : obj.toString()}"`;
        default:
            return "{}";
    }
}

console.log(stringify(Object));
console.log(stringify(null));
console.log(stringify(2));
console.log(stringify(false));
console.log(stringify("false"));
console.log(stringify({ a: 1, b: 2 }));
console.log(
    stringify([
        false,
        Symbol(),
        Symbol,
        new Date(),
        new Error("测试"),
        undefined,
        "测试",
        null,
        /./,
        { a: 1, b: 2, c: null },
        [1, undefined],
        Number(1),
    ]),
);

 // JSON.stringify 和 JSON.parse 的实现 https://www.jianshu.com/p/f1c8bcd16f71