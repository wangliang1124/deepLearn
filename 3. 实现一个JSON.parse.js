// 3. 实现 JSON.parse
function jsonParse(json) {
    return eval("(" + json + ")");
}
function jsonParse2(json) {
    return new Function("return " + json)();
}
console.log(
    JSON.stringify([
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

// JSON.parse 三种实现方式 https://github.com/youngwind/blog/issues/115