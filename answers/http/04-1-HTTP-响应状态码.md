# HTTP 响应状态码

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status>
> 对应题目：HTTP 协议 第 4 题 · http 状态码有哪些？分别代表是什么意思？
> 抓取时间：2026-09-22

---

[`400 Bad Request`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/400>)

由于被认为是客户端错误（例如，错误的请求语法、无效的请求消息帧或欺骗性的请求路由），服务器无法或不会处理请求。

[`401 Unauthorized`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/401>)

虽然 HTTP 标准指定了"unauthorized"，但从语义上来说，这个响应意味着"unauthenticated"。也就是说，客户端必须对自身进行身份验证才能获得请求的响应。

[`402 Payment Required`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/402>)

此响应代码保留供将来使用。创建此代码的最初目的是将其用于数字支付系统，但是此状态代码很少使用，并且不存在标准约定。

[`403 Forbidden`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/403>)

客户端没有访问内容的权限；也就是说，它是未经授权的，因此服务器拒绝提供请求的资源。与 `401 Unauthorized` 不同，服务器知道客户端的身份。

[`404 Not Found`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/404>)

服务器找不到请求的资源。在浏览器中，这意味着无法识别 URL。在 API 中，这也可能意味着端点有效，但资源本身不存在。服务器也可以发送此响应，而不是 `403 Forbidden`，以向未经授权的客户端隐藏资源的存在。这个响应代码可能是最广为人知的，因为它经常出现在网络上。

[`405 Method Not Allowed`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/405>)

服务器知道请求方法，但目标资源不支持该方法。例如，API 可能不允许调用`DELETE`来删除资源。

[`406 Not Acceptable`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/406>)

当 web 服务器在执行[服务端驱动型内容协商机制](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Guides/Content_negotiation#%E6%9C%8D%E5%8A%A1%E7%AB%AF%E9%A9%B1%E5%8A%A8%E5%9E%8B%E5%86%85%E5%AE%B9%E5%8D%8F%E5%95%86%E6%9C%BA%E5%88%B6>)后，没有发现任何符合用户代理给定标准的内容时，就会发送此响应。

[`407 Proxy Authentication Required`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/407>)

类似于 `401 Unauthorized` 但是认证需要由代理完成。

[`408 Request Timeout`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/408>)

此响应由一些服务器在空闲连接上发送，即使客户端之前没有任何请求。这意味着服务器想关闭这个未使用的连接。由于一些浏览器，如 Chrome、Firefox 27+ 或 IE9，使用 HTTP 预连接机制来加速冲浪，所以这种响应被使用得更多。还要注意的是，有些服务器只是关闭了连接而没有发送此消息。

[`409 Conflict`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/409>)

当请求与服务器的当前状态冲突时，将发送此响应。

[`410 Gone`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/410>)

当请求的内容已从服务器中永久删除且没有转发地址时，将发送此响应。客户端需要删除缓存和指向资源的链接。HTTP 规范打算将此状态代码用于“有限时间的促销服务”。API 不应被迫指出已使用此状态代码删除的资源。

[`411 Length Required`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/411>)

服务端拒绝该请求因为 `Content-Length` 头部字段未定义但是服务端需要它。

[`412 Precondition Failed`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/412>)

客户端在其头文件中指出了服务器不满足的先决条件。

[`413 Payload Too Large`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/413>)

请求实体大于服务器定义的限制。服务器可能会关闭连接，或在标头字段后返回重试 `Retry-After`。

[`414 URI Too Long`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/414>)

客户端请求的 URI 比服务器愿意接收的长度长。

[`415 Unsupported Media Type`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/415>)

服务器不支持请求数据的媒体格式，因此服务器拒绝请求。

[`416 Range Not Satisfiable`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/416>)

无法满足请求中 `Range` 标头字段指定的范围。该范围可能超出了目标 URI 数据的大小。

[`417 Expectation Failed`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/417>)

此响应代码表示服务器无法满足 `Expect` 请求标头字段所指示的期望。

[`418 I'm a teapot`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/418>)

服务端拒绝用茶壶煮咖啡。笑话，典故来源[茶壶冲泡咖啡](<https://zh.wikipedia.org/wiki/%E8%B6%85%E6%96%87%E6%9C%AC%E5%92%96%E5%95%A1%E5%A3%B6%E6%8E%A7%E5%88%B6%E5%8D%8F%E8%AE%AE> "外部链接（在新标签页中打开）")

[`421 Misdirected Request`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/421>)

请求被定向到无法生成响应的服务器。这可以由未配置为针对请求 URI 中包含的方案和权限组合生成响应的服务器发送。

[`422 Unprocessable Entity`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/422>) ([WebDAV](<https://developer.mozilla.org/zh-CN/docs/Glossary/WebDAV>))

请求格式正确，但由于语义错误而无法遵循。

[`423 Locked`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/423>) ([WebDAV](<https://developer.mozilla.org/zh-CN/docs/Glossary/WebDAV>))

正在访问的资源已锁定。

[`424 Failed Dependency`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/424>) ([WebDAV](<https://developer.mozilla.org/zh-CN/docs/Glossary/WebDAV>))

由于前一个请求失败，请求失败。

[`425 Too Early`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/425>)

表示服务器不愿意冒险处理可能被重播的请求。

[`426 Upgrade Required`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/426>)

服务器拒绝使用当前协议执行请求，但在客户端升级到其他协议后可能愿意这样做。 服务端发送带有[`Upgrade`](<https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Upgrade>) 字段的 426 响应 来表明它所需的协议（们）。

[`428 Precondition Required`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/428>)

源服务器要求请求是有条件的。此响应旨在防止'丢失更新'问题，即当第三方修改服务器上的状态时，客户端 `GET` 获取资源的状态，对其进行修改并将其 `PUT` 放回服务器，从而导致冲突。

[`429 Too Many Requests`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/429>)

用户在给定的时间内发送了太多请求（"限制请求速率"）

服务器不愿意处理请求，因为其头字段太大。在减小请求头字段的大小后，可以重新提交请求。

[`451 Unavailable For Legal Reasons`](<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Reference/Status/451>)

用户代理请求了无法合法提供的资源，例如政府审查的网页。
