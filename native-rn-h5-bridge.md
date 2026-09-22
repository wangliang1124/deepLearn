## iOS 与 H5 通信

iOS 有两种 webview，ios8 以上推出了 WKWebView，低于 ios8 用的是 UIWebView，WKWebView 性能上优于 UIWebView

### iOS 调用 H5

-   stringByEvaluatingJavaScriptFromString
    Native 调用 Javascript 语言，是通过 UIWebView 组件的 stringByEvaluatingJavaScriptFromString 方法来实现的，该方法返回 js 脚本的执行结果。

```js
// Swift
webview.stringByEvaluatingJavaScriptFromString("Math.random()")
// OC
[webView stringByEvaluatingJavaScriptFromString:@"Math.random();"];
```

### H5 调用 iOS

-   拦截 iframe 请求

```js
// JS 端关键代码
var url = 'jsbridge://doAction?title=分享标题&desc=分享描述&link=http%3A%2F%2Fwww.baidu.com';
var iframe = document.createElement('iframe');
iframe.style.width = '1px';
iframe.style.height = '1px';
iframe.style.display = 'none';
iframe.src = url;
document.body.appendChild(iframe);
setTimeout(function() {
    iframe.remove();
}, 100);

// OC端关键代码
func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("shouldStartLoadWithRequest")
        let url = request.URL
        let scheme = url?.scheme
        let method = url?.host
        let query = url?.query

        if url != nil && scheme == "jsbridge" {
            print("scheme == \(scheme)")
            print("method == \(method)")
            print("query == \(query)")

            switch method! {
                case "getData":
                    self.getData()
                case "putData":
                    self.putData()
                case "gotoWebview":
                    self.gotoWebview()
                case "gotoNative":
                    self.gotoNative()
                case "doAction":
                    self.doAction()
                case "configNative":
                    self.configNative()
                default:
                    print("default")
            }

            return false
        } else {
            return true
        }
    }
```

## Android 与 H5 通信

### Android 调用 H5

-   loadUrl
    在 android 里是使用 webview 的 loadUrl 进行调用的，如：
```js
// 调用js中的JSBridge.trigger方法
webView.loadUrl("javascript:JSBridge.trigger('webviewReady')");
```
4.4之前Native通过loadUrl来调用JS方法,只能让某个JS方法执行,但是无法获取该方法的返回值

-   evaluateJavascript
4.4之后,通过evaluateJavascript异步调用JS方法,并且能在onReceiveValue中拿到返回值

### H5 调用 Android

-   shouldOverrideUrlLoading 拦截 iframe 请求
    和 iOS 一样，通过 iframe（Android 端通过 shouldOverrideUrlLoading 方法对 url 协议进行解析

*   addJavascriptInterface
    通过在 webview 页面里直接注入原生 js 代码方式，使用 addJavascriptInterface 方法来实现。

```js
class JSInterface {
    @JavascriptInterface //注意这个代码一定要加上
    public String getUserData() {
        return "UserData";
    }
}
webView.addJavascriptInterface(new JSInterface(), "AndroidJS");  //window对象里注入了AndroidJS对象
``` 

上面的代码就是在页面的 window 对象里注入了 AndroidJS 对象。在 js 里可以直接调用

```js
alert(AndroidJS.getUserData()); //UserDate
```

-   拦截 prompt

使用 prompt,console.log,alert 方式，这三个方法对 js 里是属性原生的，在 android webview 这一层是可以重写这三个方法的。一般我们使用 prompt，因为这个在 js 里使用的不多，用来和 native 通讯副作用比较少。

> H5 与 Native 交互之 JSBridge 技术 https://segmentfault.com/a/1190000010356403

> http://zjutkz.net/2016/04/17/%E5%A5%BD%E5%A5%BD%E5%92%8Ch5%E6%B2%9F%E9%80%9A%EF%BC%81%E5%87%A0%E7%A7%8D%E5%B8%B8%E8%A7%81%E7%9A%84hybrid%E9%80%9A%E4%BF%A1%E6%96%B9%E5%BC%8F/