const utils = {
    isEmptyObject: function(obj) {
        var type = Object.prototype.toString.call(obj);
        if (type === "[object Object]") {
            return Object.keys(obj).length === 0;
        }
        if (type == "[object Array]") {
            return obj.length === 0;
        }
        return true;
    },
};
export default utils;
