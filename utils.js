export default (utils = {
    isEmpty: function(obj) {
        var type = Object.prototype.toString.call(obj);
        if (type === "[object Object]") {
            return Object.keys().length === 0;
        }
        if (type == "[object Array]") {
            return obj.length === 0;
        }
        return true;
    },
});
