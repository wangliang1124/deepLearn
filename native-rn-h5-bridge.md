# 原生、RN、H5 通信原理

## iOS 与 H5 通信

iOS 有两种 WebView：`UIWebView` 和 iOS 8 推出的 `WKWebView`。`WKWebView` 独立进程、性能更好、内存占用更低。

**（已过时）** `UIWebView` 自 iOS 12 起被废弃，且 App Store 从 2020 年起不再接受使用它的新应用与应用更新。下面保留 `UIWebView` 的写法是为了理解早期方案，**新项目一律用 `WKWebView`**。

### iOS 调用 H5

**推荐**：`WKWebView` 的 `evaluateJavaScript`。异步执行，通过 completion handler 拿结果：

```swift
webView.evaluateJavaScript("Math.random()") { result, error in
    print(result as Any, error as Any)
}
```

`UIWebView` 时代用的是 `stringByEvaluatingJavaScriptFromString`，同步返回 js 脚本的执行结果——同步执行会卡主线程，这也是它被淘汰的原因之一：

```objc
// Objective-C
[webView stringByEvaluatingJavaScriptFromString:@"Math.random();"];
```

### H5 调用 iOS

**推荐**：`WKScriptMessageHandler`。这是 `WKWebView` 提供的正式通道，不需要任何 hack。

原生侧注册一个消息处理器：

```swift
// 注册名为 "jsbridge" 的处理器
let controller = WKUserContentController()
controller.add(self, name: "jsbridge")

let config = WKWebViewConfiguration()
config.userContentController = controller
let webView = WKWebView(frame: .zero, configuration: config)

// 实现 WKScriptMessageHandler
func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
) {
    // message.name 是 "jsbridge"，message.body 是 JS 传来的数据
    print(message.name, message.body)
}
```

JS 侧直接调用，可以传结构化数据，不用拼字符串：

```js
window.webkit.messageHandlers.jsbridge.postMessage({
    method: "doAction",
    title: "分享标题",
    desc: "分享描述",
    link: "https://www.example.com",
});
```

**旧方案：拦截 iframe 请求。** 在没有正式通道的年代，H5 通过创建一个隐藏 iframe 发起一个自定义 scheme 的请求，原生侧在导航拦截回调里解析这个 URL。缺点很多：URL 长度有限制、参数要自己编码、无法拿返回值、连续调用可能丢消息。

JS 端：

```js
var url = "jsbridge://doAction?title=分享标题&desc=分享描述&link=https%3A%2F%2Fwww.example.com";
var iframe = document.createElement("iframe");
iframe.style.width = "1px";
iframe.style.height = "1px";
iframe.style.display = "none";
iframe.src = url;
document.body.appendChild(iframe);
setTimeout(function() {
    iframe.remove();
}, 100);
```

原生端（以下是 Swift，对应 `UIWebView` 的 `UIWebViewDelegate`）：

```swift
func webView(
    webView: UIWebView,
    shouldStartLoadWithRequest request: NSURLRequest,
    navigationType: UIWebViewNavigationType
) -> Bool {
    let url = request.URL
    let scheme = url?.scheme
    let method = url?.host
    let query = url?.query

    if url != nil && scheme == "jsbridge" {
        print("method == \(String(describing: method))")
        print("query == \(String(describing: query))")

        switch method! {
        case "getData":
            self.getData()
        case "putData":
            self.putData()
        case "gotoWebview":
            self.gotoWebview()
        case "gotoNative":
            self.gotoNative()
        case "configNative":
            self.configNative()
        default:
            print("default")
        }

        return false // 拦截掉这次导航
    } else {
        return true
    }
}
```

在 `WKWebView` 上，对应的拦截回调是 `WKNavigationDelegate` 的 `webView(_:decidePolicyFor:decisionHandler:)`，通过 `decisionHandler(.cancel)` 取消导航。但既然有 `WKScriptMessageHandler`，就没必要再用这套了。

## Android 与 H5 通信

### Android 调用 H5

**推荐**：`evaluateJavascript`。异步调用 JS 方法，并能在回调里拿到返回值。它需要 API 19（Android 4.4）以上，现在的项目 minSdk 早已远高于此：

```java
webView.evaluateJavascript("JSBridge.trigger('webviewReady')", new ValueCallback<String>() {
    @Override
    public void onReceiveValue(String value) {
        // 这里能拿到 JS 的返回值
    }
});
```

`loadUrl` 是 4.4 之前的做法，只能让某个 JS 方法执行，无法获取返回值：

```java
// 调用 js 中的 JSBridge.trigger 方法
webView.loadUrl("javascript:JSBridge.trigger('webviewReady')");
```

### H5 调用 Android

**推荐**：`addJavascriptInterface`。把一个 Java 对象注入到页面的 `window` 上，JS 直接当普通对象调用。

```java
class JSInterface {
    @JavascriptInterface // 这个注解一定要加
    public String getUserData() {
        return "UserData";
    }
}

// 在 window 对象上注入 AndroidJS
webView.addJavascriptInterface(new JSInterface(), "AndroidJS");
```

JS 里直接调用：

```js
alert(AndroidJS.getUserData()); // "UserData"
```

关于那个注解：API 17 以前，注入对象的**所有** public 方法都会暴露给 JS，页面可以通过反射拿到 `Runtime` 执行任意代码，是个远程代码执行漏洞。API 17 起只有标了 `@JavascriptInterface` 的方法才暴露——所以注解不是写着好看的，漏了它方法根本调不到。即便如此，只应该给可信页面注入接口。

**拦截 iframe 请求。** 和 iOS 旧方案一样，Android 端在 `shouldOverrideUrlLoading` 里解析自定义 scheme 的 URL。同样受 URL 长度限制、拿不到返回值。

**拦截 prompt。** JS 的 `prompt`、`console.log`、`alert` 这三个方法在 Android WebView 层（`WebChromeClient`）是可以重写的。一般选 `prompt`，因为业务里用得最少，拿来做通信副作用最小。这是个取巧方案，能用但不推荐。

## 参考

> **推荐** H5 与 Native 交互之 JSBridge 技术 https://segmentfault.com/a/1190000010356403

> 好好和 h5 沟通！几种常见的 hybrid 通信方式（链接已失效）

仓库内相关 demo：[async-iframe.html](async-iframe.html)、[cross-origin-a.html](cross-origin-a.html)
