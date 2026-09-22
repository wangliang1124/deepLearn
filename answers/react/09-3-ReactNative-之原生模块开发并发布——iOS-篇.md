# ReactNative 之原生模块开发并发布——iOS 篇

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<http://www.liuchungui.com/blog/2016/05/02/reactnativezhi-yuan-sheng-mo-kuai-kai-fa-bing-fa-bu-iospian/>
> 对应题目：React 第 9 题 · RN 如何实现一个原生的组件
> 抓取时间：2026-09-22

---

前段时间做了个ReactNative的App，发现ReactNative中不少组件并不存在，所以还是需要自己对原生模块进行编写让JS调用，正是因为在这个编写过程中遇到不少问题，发觉了官网文档中许多的不足。所以产生了写一个实践教程的想法，最终有了这么一篇文章。

整篇文章主要以编写一个原生模块为例子，来讲述了我们在编写原生模块所用到的一些知识，并且在整个例子中，配有了完整的实践代码，方便大家理解并调试。除了这些内容，文章还讲述了我们如何将自己编写的原生模块发布到npm上分享给别人使用。希望能够给大家带来帮助，也希望大家将自己编写的原生模块分享出来。

示例代码github地址：<https://github.com/liuchungui/react-native-BGNativeModuleExample>

编写android原生模块，请看[ReactNative之原生模块开发并发布——android篇](<http://www.liuchungui.com/blog/2016/05/08/reactnativezhi-yuan-sheng-mo-kuai-kai-fa-bing-fa-bu-androidpian/>)

## 准备工作：

#### 创建ReactNative工程

我们需要先创建一个ReactNative工程，使用如下命令创建。

    1

| 

    react native init TestProject  

---|---  

创建好工程之后，我们使用xcode打开`TestProject/ios/`下的iOS工程。

#### 创建静态库，并将这个静态库手动链接到工程中

首先，我们在前面创建的ReactNative工程下的`node_modules`创建一个文件夹`react-native-BGNativeModuleExample`，然后我们在新创建的文件夹下再创建一个ios文件夹。

    1234

| 

    $ cd TestProject/node_modules$ mkdir react-native-BGNativeModuleExample$ cd react-native-BGNativeModuleExample$ mkdir ios  

---|---  

然后，由于ReactNative的组件都是一个个静态库，我们发布到npm给别人使用的话，也需要建立静态库。我们使用xcode建立静态库，取名为`BGNativeModuleExample`。建立之后，我们将创建的静态库中的文件全部copy到`node_modules/react-native-BGNativeModuleExample/ios`目录下。  
ios文件目录如下：

    1234

| 

    |____BGNativeModuleExample| |____BGNativeModuleExample.h| |____BGNativeModuleExample.m|____BGNativeModuleExample.xcodeproj  

---|---  

最后，我们需要手动将这个静态库链接到工程中。

1、使用xcode打开创建的静态库，添加一行`Header Search Paths`，值为`$(SRCROOT)/../../react-native/React`，并设置为`recursive`。

![](http://ww2.sinaimg.cn/large/7746cd07jw1f3h69rwj3oj212s0r7dm6.jpg)

2、将`BGNativeModuleExample`静态库工程拖动到工程中的Library中。  
![](http://ww1.sinaimg.cn/large/7746cd07jw1f3o30vl8wjj20xq0fawi3.jpg)

3、选中 TARGETS => TestProject => Build Settings => Link Binary With Libraries，添加`libBGNativeModuleExample.a`这个静态库  
![](http://ww3.sinaimg.cn/large/7746cd07jw1f3o2v5wrgyj212r0hgq72.jpg)

到此，我们准备工作完成了。我们这里这么准备是有用意的，那就是模拟npm链接的过程，建立好了环境，避免了发布到npm上后别人使用找不到静态库的问题。

## 一、编写原生模块代码

#### 1、创建原生模块

选中我们创建的`BGNativeModuleExample`静态库，然后在`BGNativeModuleExample.h`文件中导入`RCTBridgeModule.h`，让`BGNativeModuleExample`类遵循`RCTBridgeModule`协议。

    12345

| 

    //BGNativeModuleExample.h文件的内容如下#import <Foundation/Foundation.h>#import "RCTBridgeModule.h"@interface BGNativeModuleExample : NSObject <RCTBridgeModule>@end  

---|---  

在`BGNativeModuleExample.m`文件中，我们需要实现`RCTBridgeModule`协议。为了实现`RCTBridgeModule`协议，我们的类需要包含RCT_EXPORT_MODULE()宏。这个宏也可以添加一个参数用来指定在Javascript中访问这个模块的名字。如果不指定，默认会使用这个类的名字。

在这里，我们指定了模块的名字为`BGNativeModuleExample`。

    1

| 

    RCT_EXPORT_MODULE(BGNativeModuleExample);  

---|---  

实现了RCTBridgeModule协议之后，我们就可以在js中如下获取到我们创建的原生模块。

    12

| 

    import { NativeModules } from 'react-native';var BGNativeModuleExample = NativeModules.BGNativeModuleExample;  

---|---  

需要注意的是，RCT_EXPORT_MODULE宏传递的参数不能是OC中的字符串。如果传递@”BGNativeModuleExample”，那么我们导出给JS的模块名字其实是@”BGNativeModuleExample”，使用BGNativeModuleExample就找不到了。在这里，我们其实可以通过打印`NativeModules`来查找到我们创建的原生模块。

#### 2、为原生模块添加方法

我们需要明确的声明要给JS导出的方法，否则ReactNative不会导出任何方法。声明通过RCT_EXPORT_METHOD()宏来实现：

    123

| 

    RCT_EXPORT_METHOD(testPrint:(NSString *)name info:(NSDictionary *)info) {  RCTLogInfo(@"%@: %@", name, info);}  

---|---  

在JS中，我们可以这样调用这个方法：

    1234

| 

    BGNativeModuleExample.testPrint("Jack", {  height: '1.78m',  weight: '7kg'});  

---|---  

#### 3、参数类型

RCT_EXPORT_METHOD()支持所有标准的JSON类型，包括：

  * string (NSString)
  * number (NSInteger, float, double, CGFloat, NSNumber)
  * boolean (BOOL, NSNumber)
  * array (NSArray) 包含本列表中任意类型
  * map (NSDictionary) 包含string类型的键和本列表中任意类型的值
  * function (RCTResponseSenderBlock)

除此以外，任何RCTConvert类支持的的类型也都可以使用(参见[RCTConvert](<https://github.com/facebook/react-native/blob/master/React/Base/RCTConvert.h>)了解更多信息)。RCTConvert还提供了一系列辅助函数，用来接收一个JSON值并转换到原生Objective-C类型或类。

了解更多请点击[原生模块](<http://reactnative.cn/docs/0.25/native-modules-ios.html#content>)

#### 4、回调函数

> 警告  
> 本章节内容目前还处在实验阶段，因为我们还并没有太多的实践经验来处理回调函数。

回调函数，在官方的文档中是有上面的一个警告，不过在使用过程暂时未发现问题。在OC中，我们添加一个`getNativeClass`方法，将当前模块的类名回调给JS。

    123

| 

    RCT_EXPORT_METHOD(getNativeClass:(RCTResponseSenderBlock)callback) {  callback(@[NSStringFromClass([self class])]);}  

---|---  

在JS中，我们通过以下方式获取到原生模块的类名

    123

| 

    BGNativeModuleExample.getNativeClass(name => {  console.log("nativeClass: ", name);});  

---|---  

**原生模块通常只应调用回调函数一次。但是，它们可以保存callback并在将来调用。** 这在封装那些通过“委托函数”来获得返回值的iOS API时最常见。

#### 5、Promises

> 原生模块还可以使用promise来简化代码，搭配ES2016(ES7)标准的async/await语法则效果更佳。如果桥接原生方法的最后两个参数是RCTPromiseResolveBlock和RCTPromiseRejectBlock，则对应的JS方法就会返回一个Promise对象。

我们通过Promises来实现原生模块是否会响应方法，响应则返回YES，不响应则返回一个错误信息，代码如下：

    1234567891011

| 

    RCT_REMAP_METHOD(testRespondMethod,                 name:(NSString *)name                 resolver:(RCTPromiseResolveBlock)resolve                 rejecter:(RCTPromiseRejectBlock)reject) {  if([self respondsToSelector:NSSelectorFromString(name)]) {    resolve(@YES);  }  else {    reject(@"-1001", @"not respond this method", nil);  }}  

---|---  

在JS中，我们有两种方式调用，第一种是通过`then....catch`的方式：

    1234567

| 

    BGNativeModuleExample.testRespondMethod("dealloc")    .then(result => {      console.log("result is ", result);    })    .catch(error => {      console.log(error);    });  

---|---  

第二种是通过`try...catch`来调用，与第一种相比，第二种会报警告”Possible Unhandled Promiss Rejection (id:0)“。

    12345678910

| 

      async testRespond() {  try {    var result = BGNativeModuleExample.testRespondMethod("hell");    if(result) {      console.log("respond this method");    }  } catch (e) {    console.log(e);  }}  

---|---  

**注意: 如果使用Promiss我们不需要参数，则在OC去掉name那一行就行了；如果需要多个参数，在name下面多加一行就行了，注意它们之间不需要添加逗号。**

#### 6、多线程

我们这里操作的模块没有涉及到UI，所以专门建立一个串行的队列给它使用，如下：

    1

| 

    return dispatch_queue_create("com.liuchungui.demo", DISPATCH_QUEUE_SERIAL);  

---|---  

> 注意: 在模块之间共享分发队列  
> methodQueue方法会在模块被初始化的时候被执行一次，然后会被React Native的桥接机制保存下来，所以你不需要自己保存队列的引用，除非你希望在模块的其它地方使用它。但是，如果你希望在若干个模块中共享同一个队列，则需要自己保存并返回相同的队列实例；仅仅是返回相同名字的队列是不行的。

更多线程的操作细节可以参考<http://reactnative.cn/docs/0.24/native-modules-ios.html#content>

#### 7、导出常量

原生模块可以导出一些常量，这些常量在JavaScript端随时都可以访问。用这种方法来传递一些静态数据，可以避免通过bridge进行一次来回交互。

OC中，我们实现`constantsToExport`方法，如下：

    12345

| 

    - (NSDictionary *)constantsToExport {  return @{ @"BGModuleName" : @"BGNativeModuleExample",            TestEventName: TestEventName            };}  

---|---  

JS中，我们打印一下这个常量

    1

| 

    console.log("BGModuleName value is ", BGNativeModuleExample.BGModuleName);  

---|---  

但是注意这个常量仅仅在初始化的时候导出了一次，所以即使你在运行期间改变constantToExport返回的值，也不会影响到JavaScript环境下所得到的结果。

#### 8、给JS发送事件

即使没有被JS调用，本地模块也可以给JS发送事件通知。最直接的方式是使用`eventDispatcher`。

在这里，我们为了能够接收到事件，我们开一个定时器，每一秒发送一次事件。

    123456789101112131415

| 

    #import "BGNativeModuleExample.h"#import "RCTEventDispatcher.h"@implementation BGNativeModuleExample@synthesize bridge = _bridge;- (instancetype)init {  if(self = [super init]) {    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendEventToJS) userInfo:nil repeats:YES];  }  return self;}- (void)receiveNotification:(NSNotification *)notification {  [self.bridge.eventDispatcher sendAppEventWithName:TestEventName body:@{@"name": @"Jack"}];}@end  

---|---  

在JS中，我们这样接收事件

    123

| 

    NativeAppEventEmitter.addListener(BGNativeModuleExample.TestEventName, info => {      console.log(info);    });  

---|---  

**注意： 编写OC代码时，需要添加`@synthesize bridge = _bridge;`，否则接收事件的时候就会报`Exception -[BGNativeModuleExample brige]; unrecognized selector sent to instance`的错误。**

上面原生代码就编写好了，主要以代码实践为主，弥补官方文档中的一些不足，如果要需要了解更多的原生模块封装的知识，可以参考[原生模块](<http://reactnative.cn/docs/0.22/native-modules-ios.html#content>)，也可以参考官方的源代码。

## 二、发布上线

我们按照上面步骤编写好原生模块之后，接下来将我们写的原生模块发布到npm。

#### 1、我们需要创建github仓库

在github上创建一个仓库`react-native-BGNativeModuleExample`，然后关联到我们前面创建的`react-native-BGNativeModuleExample`目录

    123

| 

    $ cd TestProject/node_modules/react-native-BGNativeModuleExample$ git init .$ git remote add origin https://github.com/liuchungui/react-native-BGNativeModuleExample.git  

---|---  

#### 2、我们需要创建原生模块的入口文件

我们需要在react-native-BGNativeModuleExample目录下创建一个index.js，它是整个原生模块的入口，我们这里只是将原生进行导出。

    123

| 

    //index.jsimport React, { NativeModules } from 'react-native';module.exports = NativeModules.BGNativeModuleExample;  

---|---  

#### 3、发布到npm

在发布到npm之前，我们需要创建一个`package.json`文件，这个文件包含了module的所有信息，比如名称、版本、描述、依赖、作者、license等。  
我们在react-native-BGNativeModuleExample根目录下使用`npm init`命令来创建`package.json`，系统会提示我们输入所需的信息，不想输入的直接按下`Enter`跳过。

    123456789101112

| 

    $ npm initThis utility will walk you through creating a package.json file.It only covers the most common items, and tries to guess sensible defaults.See `npm help json` for definitive documentation on these fieldsand exactly what they do.Use `npm install <pkg> --save` afterwards to install a package andsave it as a dependency in the package.json file.Press ^C at any time to quit.name: (react-native-BGNativeModuleExample)  

---|---  

输入完成之后，系统会要我们确认文件的内容是否有误，如果没有问题直接输入`yes`，那么`package.json`就创建好了。  
我这里创建的package.json文件如下：

    12345678910111213141516171819

| 

    {  "name": "react-native-nativemodule-example",  "version": "1.0.0",  "description": "",  "main": "index.js",  "scripts": {    "test": "echo \"Error: no test specified\" && exit 1"  },  "repository": {    "type": "git",    "url": "git+https://github.com/liuchungui/react-native-BGNativeModuleExample.git"  },  "author": "",  "license": "ISC",  "bugs": {    "url": "https://github.com/liuchungui/react-native-BGNativeModuleExample/issues"  },  "homepage": "https://github.com/liuchungui/react-native-BGNativeModuleExample#readme"}  

---|---  

如果我们编写的原生模块依赖于其他的原生模块，我们需要在`package.json`添加依赖关系，我们这里由于没有相关依赖，所以不需要添加：  

**初始化完package.json，我们就可以发布到npm上面了。**

如果没有npm的账号，我们需要注册一个账号，这个账号会被添加到npm本地的配置中，用来发布module用。

成功之后，npm会把认证信息存储在~/.npmrc中，并且可以通过以下命令查看npm当前使用的用户：

以上完成之后，我们就可以进行发布了。

到这里，我们已经成功把module发布到了[npmjs.org](<http://www.liuchungui.com/blog/2016/05/02/reactnativezhi-yuan-sheng-mo-kuai-kai-fa-bing-fa-bu-iospian/npmjs.org>)。当然，我们也别忘记将我们的代码发布到github。

    1234

| 

    $ git pull origin master$ git add .$ git commit -m 'add Project'$ git push origin master  

---|---  

有时候，有些文件没必要发布，例如Example文件，我们就可以通过`.npmignore`忽略它。例如我这里`.npmignore`文件内容如下：

    1234

| 

    Example/.git.gitignore.idea  

---|---  

这样的话，我们npm进行发布的时候，就不会将Example发布到npm上了。

#### 4、添加Example，测试是否可用，添加README

我们在`react-native-BGNativeModuleExample`目录下创建一个Example的ReactNative工程，并且通过`rnpm install react-native-nativemodule-example`命令安装我们发布的`react-native-nativemodule-example`模块。

    1234567

| 

    $ rnpm install react-native-nativemodule-example[[email protected]](<http://www.liuchungui.com/cdn-cgi/l/email-protection>) /Users/user/github/TestProject└── [[email protected]](<http://www.liuchungui.com/cdn-cgi/l/email-protection>) rnpm-link info Linking react-native-nativemodule-example ios dependency rnpm-link info iOS module react-native-nativemodule-example has been successfully linked rnpm-link info Module react-native-nativemodule-example has been successfully installed & linked  

---|---  

上面提示安装并且link成功，我们就可以在js中进行使用了。

    123456

| 

    import BGNativeModuleExample from 'react-native-nativemodule-example';BGNativeModuleExample.testPrint("Jack", {    height: '1.78m',    weight: '7kg'});  

---|---  

#### 5、我们在发布上线之后还需要编写README文件。

README文件是非常重要的，如果没有README文件，别人看到我们的原生组件，根本就不知道我们这个组件是用来干啥的。所以，我们很有必要添加一个README文件，这个文件需要告诉别人我们这个原生组件是干什么的、如何安装、API、使用手册等等。

#### 6、原生模块升级，发布新版本

当我们添加新代码或者修复bug后，需要发布新的版本，我们只需要修改package.json文件中的`version`的值就行了，然后使用`npm publish`进行发布。

## 总结

本篇文章主要分成两个部分，一是讲述了编写原生模块的知识，二是将我们编写的内容发布到npm上。

## 参考

[如何发布Node模块到NPM社区](<http://weizhifeng.net/how-to-publish-a-node-module.html>)

[原生模块](<http://reactnative.cn/docs/0.22/native-modules-ios.html#content>)
