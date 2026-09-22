# ReactNative 与原生代码的通信(iOS 篇)

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/99c32dc5cf29>
> 对应题目：React 第 12 题 · RN 和原生通信
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

从RN端发送消息到iOS端的过程:  
iOS端在想给RN端调用的类文件中使用宏定义`RCT_EXPORT_MODULE()`导出这个类,并且使用宏定义`RCT_EXPORT_METHOD()`导出想给RN端调用的类方法,再遵守`RCTBridgeModule`协议,方法的实现是写在iOS端的,这样RN端通过调用这个方法就可以将想传递的参数传到iOS端

    iOS端代码:
          @implementation ExampleInterface  
          RCT_EXPORT_MODULE(); //可以指定一个参数来访问这个模块,不指定就是这个类的名字(ExampleInterface)
          RCT_EXPORT_METHOD(sendMessage:(NSString *)msg){
                  NSLog(@"从RN端接收到的信息%@",msg);
          }

    RN端代码:
          //原生端RCT_EXPORT_MODULE()导出的类
          let ExampleInterface = require('react-native').NativeModules.ExampleInterface
          ExampleInterface.sendMessage('{\"msgType\":\"pickContact\"}')

从iOS端发送消息到RN端:  
iOS发送消息到RN端分为2种情况,一种是接收到RN端的消息,处理完毕后返回,另外一种是主动发送消息到RN端,对于第一种通常是使用Promise机制,第二种RN端使用的`NativeAppEventEmitter`接收器,iOS端通过`eventDispatcher`发送

    情况一 iOS端代码:
          @implementation ExampleInterface        
          RCT_EXPORT_MODULE(); //可以指定一个参数来访问这个模块,不指定就是这个类的名字(ExampleInterface)
          RCT_EXPORT_METHOD(sendMessage:(NSString *)msg,resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
                  NSLog(@"从RN端接收到的信息%@",msg);
                  NSString *msgAdd = [msg stringByAppendingString:@"123"];  //对接收到的信息进行处理
                  resolve(msgAdd); //通过此代码块回调到RN端
          }

    情况一 RN端代码:
          let ExampleInterface = require('react-native').NativeModules.ExampleInterface
          ExampleInterface.sendMessage('{\"msgType\":\"pickContact\"}').then(
              (result)=>{
                console.log('原生端结果')
                console.log(result)
              }
          ).catch(
              (error)=>{
                console.log('错误信息');
                console.log(error)
                console.log(error.message)
                console.log(error.code)
                console.log(error.nativeStackIOS);
                console.log(error.nativeStackIOS.length)
              }
          )

    情况二iOS端代码:
          @implementation ExampleInterface  
          @synthesize bridge = _bridge;
          RCT_EXPORT_MODULE(); //可以指定一个参数来访问这个模块,不指定就是这个类的名字(ExampleInterface)
          -(void)sendMessageToRN{
                [self.bridge.eventDispatcher sendAppEventWithName@"NativeModuleMsg" body:@"原生消息"];
          }

    情况二RN端代码:
          NativeAppEventEmitter.addListener('NativeModuleMsg', (reminder)=>{ //监听的事件的名称(NativeModuleMsg)和原生端发送的要一样
                console.log('原生端的消息'+reminder);
          })
