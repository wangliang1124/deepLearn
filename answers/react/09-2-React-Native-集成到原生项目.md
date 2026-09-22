# React Native 集成到原生项目

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://www.jianshu.com/p/3dc9d70a790f>
> 对应题目：React 第 9 题 · RN 如何实现一个原生的组件
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

想了很久，要先介绍各种组件的实际应用好，还是先介绍怎么把React Native集成到原生项目好。  
因为想起，一旦开始写各种组件的应用，就会花很长很长的篇幅，会把这个挺重要的内容抛到好远，而集成到原生项目又是很多人所需要学习的（像我一样哈，直接替代现有的项目是不科学的，作为一个模块集合进去才比较现实），所以决定了，还是先花两个篇章写写怎么将React Native集成到原生项目以及JS与原生之间简单的交互。

* * *

由于React并没有假设你其余部分的技术栈——它通常只作为MVC模型中的V存在——它也很容易嵌入到一个并非由React Native开发的应用当中。实际上，它可以和常见的许多工具结合，譬如CocoaPods。

## 一、准备工作

#### 1\. React Native 开发基础环境

这个可以直接参考我写的第二篇文章[React Native 环境搭建和创建项目(Mac)](<https://www.jianshu.com/p/a85cba2efb7a>)。如果已经按上篇文章操作过，或者说已经在Mac平台已经成功运行过React Native应用，那肯定是已经有了开发基础环境，可以直接忽略这一步。

**1) 安装Node.js**  
_方式一：_  
安装 nvm（安装向导在[这里](<https://link.jianshu.com?t=https://github.com/creationix/nvm#installation>)）。然后运行命令行如下：

    nvm install node && nvm alias default node

这将会默认安装最新版本的Node.js并且设置好命令行的环境变量，这样你可以输入node命令来启动Node.js环境。nvm使你可以可以同时安装多个版本的Node.js，并且在这些版本之间轻松切换。  
_方式二：_  
先安装Homebrew，再利用Homebrew安装Node.js，运行命令行如下：

    //安装Home-brew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    //安装Node.js
    brew install node

**2) 安装React Native的命令行工具（react-native-cli）**

    npm install -g react-native-cli

#### 2\. 安装CocoaPods

> 本文只写使用CocoaPods安装React Native的方式，比较支持使用，也比较简单直接。  
>  若依旧不想使用CocoaPods，想直接集成的朋友可以参考下面两篇文章：  
>  1)[【iOS&Android】RN学习3——集成进现有原生项目](<https://link.jianshu.com?t=http://www.chaisong.xyz/2016/08/02/RN%E5%AD%A6%E4%B9%A03%E2%80%94%E2%80%94%E9%9B%86%E6%88%90%E8%BF%9B%E5%B7%B2%E6%9C%89%E5%8E%9F%E7%94%9F%E9%A1%B9%E7%9B%AE/>)

  2. [reactnative集成到原生ios项目](<https://link.jianshu.com?t=http://www.tuicool.com/articles/BfInEv>) 文中的手动集成react-native

如果之前已经安装并使用过CocoaPods，请忽略这一步（相信只要是iOS开发，一定大多数都接触过了哈）。  
若没有安装，则运行命令如下：

    gem install  cocoa pods
    //权限不够则运行下面一句
    sudo gem install cocoapods

## 二、集成React Native

#### 1\. 安装React Native

##### 1）创建ReactComponent文件夹和配置文件

在项目中建一个名为ReactComponent的文件夹, 用于存放我们react-native的相关文件, 再创建一个package.json文件, 用于初始化react-native.（文件夹名字自定义哈）  
文件目录结构如下：

创建package.json文件，文件内容如下：

    {
      "name": "NativeRNApp",
      "version": "0.0.1",
      "private": true,
      "scripts": {
        "start": "node node_modules/react-native/local-cli/cli.js start"
      },
      "dependencies": {
        "react": "15.2.1",
        "react-native": "0.29.2"
      }
    }

> 其中，name为项目名称。dependencies里为react和react-native的版本信息。  
>  建议利用react-native init AwesomeProject新建新项目时会自动创建package.json，直接把文件复制过来，更改name为自己的原生项目名，以确保react、和react-native的版本最新哈。

##### 2）安装React Native依赖包

在ReactComponent目录下运行命令行：

    npm install

运行效果如下：

> 这里很需要耐心，曾经的我看着毫无反应的控制台就放弃了n次。  
>  可能静下心去看部动漫回来就会发现它只想成功了。  
>  实在install不回来的话，如果之前有创建过React Native项目，把里面的node_modules直接拷贝过来，也是没有问题（个人尝试过）。

#### 2\. 创建 index.ios.js（js文件入口）

在ReactComponent文件夹里创建index.ios.js文件，作为js文件入口。

index.ios.js文件内容如下：

    /**
     * Sample React Native App
     * https://github.com/facebook/react-native
     * @flow
     */

    import React, { Component } from 'react';
    import {
      AppRegistry,
      StyleSheet,
      Text,
      View
    } from 'react-native';

    class NativeRNApp extends Component {
      render() {
        return (
          <View style={styles.container}>
            <Text style={styles.welcome}>
              Welcome to React Native!
            </Text>
            <Text style={styles.instructions}>
              To get started, edit index.ios.js
            </Text>
            <Text style={styles.instructions}>
              Press Cmd+R to reload,{'\n'}
              Cmd+D or shake for dev menu
            </Text>
          </View>
        );
      }
    }

    const styles = StyleSheet.create({
      container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F5FCFF',
      },
      welcome: {
        fontSize: 20,
        textAlign: 'center',
        margin: 10,
      },
      instructions: {
        textAlign: 'center',
        color: '#333333',
        marginBottom: 5,
      },
    });

    //  项目名要有所对应
    AppRegistry.registerComponent('NativeRNApp', () => NativeRNApp);

#### 3\. Cocoapods集成React Native

若原项目无使用Cocoapods，则在根目录下创建Podfile。（有则直接添加pod相关代码）  
目录结构如下：

Podfile文件内容为（需确保路径对）：

    platform :ios, “7.0”

    # 取决于你的工程如何组织，你的node_modules文件夹可能会在别的地方。
    # 请将:path后面的内容修改为正确的路径（一定要确保正确～～）。
    pod 'React', :path => ‘./ReactComponent/node_modules/react-native', :subspecs => [
     'Core',
      'ART',
      'RCTActionSheet',
      'RCTAdSupport',
      'RCTGeolocation',
      'RCTImage',
      'RCTNetwork',
      'RCTPushNotification',
      'RCTSettings',
      'RCTText',
      'RCTVibration',
      'RCTWebSocket',
      'RCTLinkingIOS',
    ]
    #需要的模块依赖进来便可，这里是为了举例子，列举所有的模块

然后在根目录执行pod更新命令：

    pod install

    /*
    以下是失败情况的处理
    */
    //  pod命令过慢则可尝试下面命令
    pod install --verbose --no-repo-update

    //  其中无法正常下载pod install的解决方法：
    （or更新最新的CocoaPods version: 0.39.0  查看方法 pod --version）
    gem sources --remove https://rubygems.org/
    gem sources -a 
    gem sources -l 

    # 注意 taobao 是 https; 
    # gem如果版本太老可以更新：sudo gem update --system; 
    # 更新pod repo：pod repo update

运行效果：

## 三、原生项目处理

#### 1\. 向对应ViewController 添加RCTRootView

下面的ReactViewController是我创建的专门放React Native模块的ViewController，有必要的话也可对RCTRootView进行进一步封装（就不用每次都重新配置一次）。  
ReactViewController代码如下：

    #import "ReactViewController.h"
    #import <RCTRootView.h>

    @interface ReactViewController ()

    @end

    @implementation ReactViewController

    - (void)viewDidLoad {
        [super viewDidLoad];
        // Do any additional setup after loading the view.

        NSString * strUrl = @"http://localhost:8081/index.ios.bundle?platform=ios&dev=true";
        NSURL * jsCodeLocation = [NSURL URLWithString:strUrl];

        RCTRootView * rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                             moduleName:@"NativeRNApp"
                                                      initialProperties:nil
                                                          launchOptions:nil];
        self.view = rootView;
        //  也可addSubview，自定义大小位置
    }

    - (void)didReceiveMemoryWarning {
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
    }

    @end

项目结构如下：

#### 2\. iOS项目更新App Transport Security

在iOS 9以上的系统中，除非明确指明，否则应用无法通过http协议连接到localhost主机。 我们建议你在Info.plist文件中将localhost列为App Transport Security的例外。 如果不这样做，在尝试通过http连接到服务器时，会遭遇这个错误 - Could not connect to development server.

打开工程中的 Info.list 文件，添加下面配置即可：

    <key>NSAppTransportSecurity</key>
      <dict>
        <key>NSExceptionDomains</key>
        <dict>
          <key>localhost</key>
          <dict>
           <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
           <true/>
          </dict>
        </dict>
      </dict>

配置效果如下：

App Transport Security配置.png

#### 3\. 启动开发服务器

在运行我们的项目之前，我们需要先启动我们的开发服务器。进入 reactnative目录 ,然后命令行启动服务：

    react-native start

#### 4\. 运行iOS项目

运行成功效果如下：

可以成功看到上面的界面，那就恭喜集成成功了。之前弄这个弄了一两天，主要卡在npm install不回来那一步，然后pod是不可能的。。写个更加详细的教程希望大家能更轻松的把React Native集成到原生项目中哈，有问题欢迎留言哈。

> 目前暂时把demo打包到自己的百度云(以后再想办法放到github)：  
>  [https://pan.baidu.com/s/1hrKnlvm](<https://link.jianshu.com?t=https://pan.baidu.com/s/1hrKnlvm>)

* * *

因为没继续这方面的工作所以好久没更新了，可能代码因为rn的更新会有些问题，最好更新下pod的版本，看看官方文档，看到评论里有相应的讨论，出现问题的朋友最好也看看评论哈哈，可能有解决绑法♪───Ｏ（≧∇≦）Ｏ────♪

> 已有的成果如下：  
>  [1) React Native 简介与入门](<https://www.jianshu.com/p/5b185df2d11a>)  
>  [2) React Native 环境搭建和创建项目(Mac)](<https://www.jianshu.com/p/a85cba2efb7a>)  
>  [3) React Native 开发之IDE](<https://www.jianshu.com/p/dfec60a479ec>)  
>  [4) React Native 入门项目与解析](<https://www.jianshu.com/p/35c3e08bfddd>)  
>  [5) React Native 相关JS和React基础](<https://www.jianshu.com/p/61a5fdbc9b35>)  
>  [6) React Native 组件生命周期(ES6)](<https://www.jianshu.com/p/72f8c1da0b65>)  
>  [7) React Native 集成到原生项目(iOS)](<https://www.jianshu.com/p/3dc9d70a790f>)  
>  [8) React Native 与原生之间的通信(iOS)](<https://www.jianshu.com/p/9d7dbf17daa5>)  
>  [9) React Native 封装原生ＵI组件(iOS)](<https://www.jianshu.com/p/e16c91acce03>)
