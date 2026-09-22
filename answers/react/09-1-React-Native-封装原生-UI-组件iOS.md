# React Native 封装原生 UI 组件(iOS)

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/e16c91acce03>
> 对应题目：React 第 9 题 · RN 如何实现一个原生的组件
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

继上一篇文章的[React Native 与原生之间的通信(iOS)](<https://www.jianshu.com/p/9d7dbf17daa5>)，我们知道RN与原生通信主要通过属性、原生模块、封装原生UI组件三种方式，上篇文章主要讲了前面两种方式，这篇文章补充下第三种方式。  
由于刚入门React Native，知识水平有限，看了官方文档（一脸懵b），找了好多博客、源码去研究怎么封装iOS端的原生控件，结果尝试了几天依旧只能对原生UI有简单的封装，使得js能调用其属性以及事件（不完整），所以这篇文章并不完整，希望RN的高手能给些意见或者博客引导，写得不对的地方欢迎留言和讨论。。。  

* * *

原生开发，发展到今天已经非常成熟完善，已有组件成千上万，极大的提高了开发效率。而React Native 在Facebook的React.js conf 2015上提出，至今一年多，组件数目肯定没得和原生的相比。  
因此，在使用React Native开发App的过程中，我们可能需要调用RN没有实现的原生视图组件或第三方组件。甚至，我们可以把本地模块构造成一个React Native组件，提供给别人使用。

本文的demo基于SDCycleScrollView，即banner，因为想不到什么好的例子，所以就把在做的项目用到的SDCycleScrollView封装下，直接给js调用。

> SDCycleScrollView为github开源的无限循环自动图片轮播器。  
>  地址为：[https://github.com/gsdios/SDCycleScrollView](<https://link.jianshu.com?t=https://github.com/gsdios/SDCycleScrollView>)  
>  里面会用SDWebImage，如果项目已用到SDWebImage，则建议直接把SDCycleScrollView相关代码拉进项目就OK了。

## 一、对原生视图进行进一步封装

参考其他人对原生视图的封装，大多都会新建一个视图，继承（或者子视图包含）原生视图，里面可能含有事件的调用（这里简单demo，就没用到）。  
#import "UIView+React.h"，对原生视图进行扩展（这里有个重要的属性reactTag，后面会用到，作为区分用途）。

### TestScrollView.h

    #import "SDCycleScrollView.h"

    #import "RCTComponent.h"
    #import "UIView+React.h"

    @interface TestScrollView : SDCycleScrollView

    @property (nonatomic, copy) RCTBubblingEventBlock onClickBanner;

    @end

> 在封装的UIView中声明RCTBubblingEventBlock或RCTBubblingEventBlock类型的block属性，才可以被当做事件导出。（新的事件导出方式，后面会用到哦）  
>  **注意：声明block属性名称要以on开头** （不确定为什么，在不做其它配置的情况下，只有on开头能成功）

### TestScrollView.m

    #import "TestScrollView.h"

    @implementation TestScrollView

    /**
     *  挺多封装原生的第三方组件都会这么写，这里还没研究透彻，就没按着去实现
    - (instancetype)initWithBridge:(RCTBridge *)bridge {
        if ((self = [super initWithFrame:CGRectZero])) {
            _eventDispatcher = bridge.eventDispatcher;
            _bridge = bridge;
            ......
        }
        return self;
    }
     */
    @end

## 二、创建RCTViewManager子类来创建和管理原生视图

原生视图都需要被一个RCTViewManager的子类来创建和管理。  
这些管理器在功能上有些类似“视图控制器”，但它们**本质上都是单例 - React Native只会为每个管理器创建一个实例。**  
它们创建原生的视图并提供给RCTUIManager，RCTUIManager则会反过来委托它们在需要的时候去设置和更新视图的属性。RCTViewManager还会代理视图的所有委托，并给JavaScript发回对应的事件。

提供原生视图步骤如下：

  * **首先创建一个子类** —— 命名规范为“视图名称+Manager”. 视图名称可以加上自己的前缀，这里最好避免使用RCT前缀，除非你想给官方pull request
  * **添加RCT_EXPORT_MODULE()标记宏** —— 让模块接口暴露给JavaScript
  * *_实现-(UIView _)view方法__ —— 创建并返回组件视图
  * **封装属性及传递事件**

下面先贴出完整的代码，然后会对属性和事件进行进一步的解说。

### TestScrollViewManager.h

    #import "RCTViewManager.h"

    @interface TestScrollViewManager : RCTViewManager

    @end

### TestScrollViewManager.m

    #import "TestScrollViewManager.h"
    #import "TestScrollView.h"      //第三方组件的头文件

    #import "RCTBridge.h"           //进行通信的头文件
    #import "RCTEventDispatcher.h"  //事件派发，不导入会引起Xcode警告

    @interface TestScrollViewManager() <SDCycleScrollViewDelegate>

    @end

    @implementation TestScrollViewManager

    //  标记宏（必要）
    RCT_EXPORT_MODULE()

    //  事件的导出，onClickBanner对应view中扩展的属性
    RCT_EXPORT_VIEW_PROPERTY(onClickBanner, RCTBubblingEventBlock)

    //  通过宏RCT_EXPORT_VIEW_PROPERTY完成属性的映射和导出
    RCT_EXPORT_VIEW_PROPERTY(autoScrollTimeInterval, CGFloat);

    RCT_EXPORT_VIEW_PROPERTY(imageURLStringsGroup, NSArray);

    RCT_EXPORT_VIEW_PROPERTY(autoScroll, BOOL);

    - (UIView *)view
    {
        //  实际组件的具体大小位置由js控制
        TestScrollView *testScrollView = [TestScrollView cycleScrollViewWithFrame:CGRectZero delegate:self placeholderImage:nil];
        //  初始化时将delegate指向了self
        testScrollView.pageControlStyle = SDCycleScrollViewPageContolStyleClassic;
        testScrollView.pageControlAliment = SDCycleScrollViewPageContolAlimentCenter;
        return testScrollView;
    }

    /**
     *  当事件导出用到 sendInputEventWithName 的方式时，会用到
    - (NSArray *) customDirectEventTypes {
        return @[@"onClickBanner"];
    }
     */

    #pragma mark SDCycleScrollViewDelegate
    /**
     *  banner点击
     */
    - (void)cycleScrollView:(TestScrollView *)cycleScrollView didSelectItemAtIndex:(NSInteger)index
    {
    //    这也是导出事件的方式，不过好像是旧方法了，会有警告
    //    [self.bridge.eventDispatcher sendInputEventWithName:@"onClickBanner"
    //                                                   body:@{@"target": cycleScrollView.reactTag,
    //                                                          @"value": [NSNumber numberWithInteger:index+1]
    //                                                        }];

        if (!cycleScrollView.onClickBanner) {
            return;
        }

        NSLog(@"oc did click %li", [cycleScrollView.reactTag integerValue]);

        //  导出事件
        cycleScrollView.onClickBanner(@{@"target": cycleScrollView.reactTag,
                                        @"value": [NSNumber numberWithInteger:index+1]});
    }

    // 导出枚举常量，给js定义样式用
    - (NSDictionary *)constantsToExport
    {
        return @{
                 @"SDCycleScrollViewPageContolAliment": @{
                         @"right": @(SDCycleScrollViewPageContolAlimentRight),
                         @"center": @(SDCycleScrollViewPageContolAlimentCenter)
                         }
                 };
    }

    //  因为这个类继承RCTViewManager，实现RCTBridgeModule，因此可以使用原生模块所有特性
    //  这个方法暂时没用到
    RCT_EXPORT_METHOD(testResetTime:(RCTResponseSenderBlock)callback) {
        callback(@[@(234)]);
    }

    @end

### 属性

> RCT_EXPORT_VIEW_PROPERTY(autoScrollTimeInterval, CGFloat);

通过宏RCT_EXPORT_VIEW_PROPERTY完成属性的映射和导出。  
CGFloat为autoScrollTimeInterval的OC数据类型,转化成js则对应number。

**React Native用RCTConvert来在JavaScript和原生代码之间完成类型转换。**  
支持的默认转换类型(部分)如下：

  * string (NSString)
  * number (NSInteger, float, double, CGFloat, NSNumber)
  * boolean (BOOL, NSNumber)
  * array (NSArray) 包含本列表中任意类型
  * map (NSDictionary) 包含string类型的键和本列表中任意类型的值

如果转换无法完成，会产生一个“红屏”的报错提示，这样你就能立即知道代码中出现了问题。如果一切进展顺利，上面这个宏就已经包含了导出属性的全部实现。

ps：更复杂的类型转换，则涉及到MKCoordinateRegion类型，本文没做应用，具体可参考官方文档例子。

### 事件

js和原生之间需要有事件的交互，例如，在原生实现的代理或者点击事件，js也需要实时获取到此类事件时，就需要利用事件进行交互。  
事件的实现方式有以下两种：

  1. **通过sendInputEventWithName实现**

  1. 实现customDirectEventTypes，返回自定义的事件名数组（on开头才有效）

      - (NSArray *) customDirectEventTypes {
        return @[@"onClickBanner"];
    }

  2. sendInputEventWithName实现事件调用(reactTag用于实例的区分)

    [self.bridge.eventDispatcher sendInputEventWithName:@"onClickBanner"
                                                      body:@{@"target": cycleScrollView.reactTag,
                                                             @"value": [NSNumber numberWithInteger:index+1]
                                                            }];

  2. **通过RCTBubblingEventBlock实现**

  1. 在封装的View中添加RCTBubblingEventBlock的block属性（on开头才有效）

    @property (nonatomic, copy) RCTBubblingEventBlock onClickBanner;

  2. 在Manager类中通过宏RCT_EXPORT_VIEW_PROPERTY完成Block属性的映射和导出

    RCT_EXPORT_VIEW_PROPERTY(onClickBanner, RCTBubblingEventBlock)

  3. 实现事件调用(reactTag用于实例的区分)

    cycleScrollView.onClickBanner(@{@"target": cycleScrollView.reactTag,
                                        @"value": [NSNumber numberWithInteger:index+1]});

> 通过上面两种方式封装好的事件，在js中可以直接利用同名函数调用即可（后面会展示）。  
>  不过关于事件这块，挺多都没完全弄懂，希望有大神引导引导，比如为什么只能定义on开头、如何自定义、如何事件数据源的回调等等。。。

### 样式

因为我们所有的视图都是UIView的子类，大部分的样式属性应该直接就可以生效。有些属性定义，需要用到枚举，则可以利用通过原生传递来的常数方式来实现，具体实现如下：

    // 导出枚举常量，给js定义样式用
    - (NSDictionary *)constantsToExport
    {
        return @{
                 @"SDCycleScrollViewPageContolAliment": @{
                         @"right": @(SDCycleScrollViewPageContolAlimentRight),
                         @"center": @(SDCycleScrollViewPageContolAlimentCenter)
                         }
                 };
    }

在js中调用则如下：

    //  首先获取到常量
    var TestScrollViewConsts = require('react-native').UIManager.TestScrollView.Constants;

    //  调用
    <TestScrollView style={styles.container} 
        pageControlAliment = {TestScrollViewConsts.SDCycleScrollViewPageContolAliment.right}
     />

> ps: 一部分组件会希望使用自己定义的默认样式，例如UIDatePicker希望自己的大小是固定的。比如大小用原生默认大小，这个例子具体可以参考[官方文档](<https://link.jianshu.com?t=http://reactnative.cn/docs/0.31/native-component-ios.html#content>)的样式模块。

## 三、在JS中进行调用

在js中调用，可以有两种方式，一为直接作为扩展React组件调用，二为新建一个组件封装好，再进行调用。  
下文用第二种方式，官方推荐，逻辑比较清晰。

1.先倒入原生组件，新建TestScrollView.js文件，在里面对TestScrollView导入，进行属性类型声明等。具体代码和解释如下：

### TestScrollView.js

    // TestScrollView.js

    import React, { Component, PropTypes } from 'react';
    import { requireNativeComponent } from 'react-native';

    // requireNativeComponent 自动把这个组件提供给 "RCTScrollView"
    var RCTScrollView = requireNativeComponent('TestScrollView', TestScrollView);

    export default class TestScrollView extends Component {

      render() {
        return <RCTScrollView {...this.props} />;
      }

    }

    TestScrollView.propTypes = {
        /**
        * 属性类型，其实不写也可以，js会自动转换类型
        */
        autoScrollTimeInterval: PropTypes.number,
        imageURLStringsGroup: PropTypes.array,
        autoScroll: PropTypes.bool,

        onClickBanner: PropTypes.func
    };

    module.exports = TestScrollView;

2.在index.ios.js中进行调用

### index.ios.js

    var TestScrollView = require('./TestScrollView');

    // requireNativeComponent 自动把这个组件提供给 "TestScrollView"
    // 如果不新建TestScrollView.js对原生组件封装声明，则直接用这句导入即可
    // var TestScrollView = requireNativeComponent('TestScrollView', null);

    // 导入常量
    var TestScrollViewConsts = require('react-native').UIManager.TestScrollView.Constants;

    var bannerImgs = [
      'http://upload-images.jianshu.io/upload_images/2321678-ba5bf97ec3462662.png?imageMogr2/auto-orient/strip%7CimageView2/2',
      'http://upload-images.jianshu.io/upload_images/1487291-2aec9e634117c24b.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/480/q/100',
      'http://f.hiphotos.baidu.com/zhidao/pic/item/e7cd7b899e510fb37a4f2df3db33c895d1430c7b.jpg'
    ];

    class NativeUIModule extends Component {

      constructor(props){
        super(props);
        this.state={
            bannerNum:0
        }
      }

      render() {

        return (
          <ScrollView style = {{marginTop:64}}>
          <View>
            <TestScrollView style={styles.container} 
              autoScrollTimeInterval = {2}
              imageURLStringsGroup = {bannerImgs}
              pageControlAliment = {TestScrollViewConsts.SDCycleScrollViewPageContolAliment.right}
              onClickBanner={(e) => {
                console.log('test' + e.nativeEvent.value);
                this.setState({bannerNum:e.nativeEvent.value});
              }}
            />
            <Text style={{fontSize: 15, margin: 10, textAlign:'center'}}>
              点击banner -> {this.state.bannerNum}
            </Text>
          </View>
          </ScrollView>
        );
      }
    }

    //  实际组件的具体大小位置由js控制
    const styles = StyleSheet.create({
      container:{
        padding:30,
        borderColor:'#e7e7e7',
        marginTop:10,
        height:200,
      },
    });

    AppRegistry.registerComponent('NativeTest2', () => NativeUIModule);

若使用第一种方式，即使用下面语句进行组件的引用：

    var TestScrollView = requireNativeComponent('TestScrollView', null);

则会存在的这样的问题：  
虽然很方便简单，但这样并不能很好的说明这个组件的用法——用户要想知道我们的组件有哪些属性可以用，以及可以取什么样的值，他不得不一路翻到Objective-C的代码。要解决这个问题，我们可以创建一个封装组件，并且通过PropTypes来说明这个组件的接口。

> 注意：我们现在把requireNativeComponent的第二个参数从null变成了用于封装的组件TestScrollView。这使得React Native的底层框架可以检查原生属性和包装类的属性是否一致，来减少出现问题的可能。

**关于属性、事件的调用，则是如下直接调用：**

    <TestScrollView style={styles.container} 
              autoScrollTimeInterval = {2}
              imageURLStringsGroup = {bannerImgs}
              pageControlAliment = {TestScrollViewConsts.SDCycleScrollViewPageContolAliment.right}
              onClickBanner={(e) => {
                console.log('test' + e.nativeEvent.value);
                this.setState({bannerNum:e.nativeEvent.value});
              }}
    />

关于事件，需要注意的是，事件事件默认传递的是字典数据类型，即json，在js中调用需要利用e.nativeEvent才能将字典取出，在具体调用里面的值。（这里也还未研究透彻、需要指导）

## 四、成果

> 到这里为止，应该能对原生UI控件进行简单的封装和调用了，如果不用到数据源，只是实现代理的第三方控件的话，封装来让RN模块调用是没用问题的+_+

> 下面推荐下有用的相关文章：  
>  1.[官方文档——原生UI组件](<https://link.jianshu.com?t=http://reactnative.cn/docs/0.31/native-component-ios.html#content>)（这是肯定的）  
>  2.[React Native构建本地视图组件](<https://link.jianshu.com?t=https://github.com/ele828/dobest.me/blob/master/React%20Native%E6%9E%84%E5%BB%BA%E6%9C%AC%E5%9C%B0%E8%A7%86%E5%9B%BE%E7%BB%84%E4%BB%B6.md>)  
>  3.[React-Native之复用原生UI组件](<https://link.jianshu.com?t=http://5minuteswalk.com/2016/01/18/React-Native%E4%B9%8B%E5%A4%8D%E7%94%A8%E5%8E%9F%E7%94%9FUI%E7%BB%84%E4%BB%B6/>)  
>  4.[React Native - How to Bridge an Objective-C View Component](<https://link.jianshu.com?t=http://browniefed.com/blog/react-native-how-to-bridge-an-objective-c-view-component/>)

> 还有对第三方对原生tableview的封装代码：  
>  [https://github.com/aksonov/react-native-tableview](<https://link.jianshu.com?t=https://github.com/aksonov/react-native-tableview>)

> 另外，关于交互原理的文章则推荐以下几篇：  
>  [[iOS] 干货 | 速收藏 | React Native iOS 源码解析篇 (二)](<https://link.jianshu.com?t=http://www.tuicool.com/articles/E3uABz>)  
>  [浅析ReactNative之通信机制（一）](<https://www.jianshu.com/p/203b91a77174>)  
>  [bang's blog : React Native通信机制详解](<https://link.jianshu.com?t=http://blog.cnbang.net/tech/2698/?from=groupmessage&isappinstalled=1>)

demo还是先暂时放到百度云中：

> [https://pan.baidu.com/s/1jI4lr3S](<https://link.jianshu.com?t=https://pan.baidu.com/s/1jI4lr3S>)

下面是demo的演示效果：

* * *

因为没继续这方面的工作所以好久没更新了，可能代码因为rn的更新会有些问题，最好更新下pod的版本，看看官方文档，看到评论里有相应的讨论，出现问题的朋友最好也看看评论哈哈，可能有解决办法♪───Ｏ（≧∇≦）Ｏ────♪

> 已有的成果如下：  
>  [1) React Native 简介与入门](<https://www.jianshu.com/p/5b185df2d11a>)  
>  [2) React Native 环境搭建和创建项目(Mac)](<https://www.jianshu.com/p/a85cba2efb7a>)  
>  [3) React Native 开发之IDE](<https://www.jianshu.com/p/dfec60a479ec>)  
>  [4) React Native 入门项目与解析](<https://www.jianshu.com/p/35c3e08bfddd>)  
>  [5) React Native 相关JS和React基础](<https://www.jianshu.com/p/61a5fdbc9b35>)  
>  [6) React Native 组件生命周期(ES6)](<https://www.jianshu.com/p/72f8c1da0b65>)  
>  [7) React Native 集成到原生项目(iOS)](<https://www.jianshu.com/p/3dc9d70a790f>)  
>  [8) React Native 与原生之间的通信(iOS)](<https://www.jianshu.com/p/9d7dbf17daa5>)

  9. React Native 封装原生ＵI组件(iOS)
