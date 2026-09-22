# React+RN 开发过程中的一些问题总结

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/amandakelake/blog/issues/52>
> 对应题目：React 第 8 题 · RN 遇到的兼容性问题
> 抓取时间：2026-09-22

---

写RN的过程中踩过大大小小的坑，有些解决了，有些还等挖掘更好的方案，甚至有些解决不了的就直接绕道了（希望有大神指导一下），也一并记录下来好了，这部分也会持续更新。。。  
可惜有些问题解决完就忘了，没记录下来，特别是调试、真机、平台方面的

题外话：有些当初苦苦想破脑袋的坑，踩过后才发现是如此的弱🐔，本来是不应该show出来贻笑大方的，但万一就是有小白也刚好陷入跟我当初一样的思维怪圈呢？所以不怕大家笑话，就一股脑都写下来吧，若干年后回头一看：原来当年我傻的如此可爱，能博得自己一笑，不也挺有意思的么

## 一、如何解决问题

这里科普一下自己遇到问题的通用解决办法

1、看官方文档，很多问题官方都已经考虑到了，对着关键词搜  
这里要吐槽一句，RN的中文文档是真滴烂，推荐看英文文档（看不懂就好好学英语）  
2、google （不要百度）  
google出来的列表里面，优先看github的issue，其次看stackoverflow，然后才是其他的选项  
[![e3d09196-d76a-469f-9653-953dc2eb5194](https://user-images.githubusercontent.com/25027560/41219155-1186c0ce-6d90-11e8-9ba0-20a6dc97470b.png)](<https://user-images.githubusercontent.com/25027560/41219155-1186c0ce-6d90-11e8-9ba0-20a6dc97470b.png>)

3、问同事（一定要再自己google后），问你认识的大神好友  
带着清晰的问题，傻逼问题就别问了

4、以上三板斧都解决不了的话，信佛的阿弥陀佛，信基督的阿门吧

## 二、问题记录

PS：下面的问题全都没有按照顺序或者时间分类，大部分是以前自己随手记录的笔记，就是辛苦一些看文章的小伙伴了，或者可以`cmd+F`或者`ctrl+F`直接搜索自己需要的内容

### 1、RN：子元素宽度问题、位置居中

RN默认使用flex布局，子元素不用设置宽度，会自动拉伸满容器  
[![45667b71-3ed7-46db-90d1-e012388c947a](https://user-images.githubusercontent.com/25027560/42729982-73e000a4-881c-11e8-9302-8e637fd5b6ec.png)](<https://user-images.githubusercontent.com/25027560/42729982-73e000a4-881c-11e8-9302-8e637fd5b6ec.png>)

如果子元素想居中  
除了使用父元素的`alignItems: 'center'`  
还是可以使用子元素的`alignSelf: 'center'`  
这样子的话子元素的宽度不再拉伸，会按照实际内容宽度，如下

    export default class PopularizeHome extends Component<Props> {
      render() {
        return (
          <View>
            <View style={styles.childContainer}>
              <Text>PopularizeHome</Text>
            </View>
          </View>
        );
      }
    }

    const styles = StyleSheet.create({
      childContainer: {
        // alignSelf: 'center',
        backgroundColor: 'red'
      },
    });

[![29240659-9956-4da3-b58f-047da63750ab](https://user-images.githubusercontent.com/25027560/42729983-7ea8eabe-881c-11e8-9be6-583c1bf5012a.png)](<https://user-images.githubusercontent.com/25027560/42729983-7ea8eabe-881c-11e8-9be6-583c1bf5012a.png>)

### 2、RN：使用原生的`Navigator`时隐藏TarBar底部导航栏

会有小bug，最好是用react-navigation或者react-native-navigation  
[![f6e90656-f5b8-4372-a5b9-324e53413ecc](https://user-images.githubusercontent.com/25027560/42729984-85c8c6f2-881c-11e8-80a9-2760c8f1635f.png)](<https://user-images.githubusercontent.com/25027560/42729984-85c8c6f2-881c-11e8-80a9-2760c8f1635f.png>)

### 3、RN：HTTP安全限制

[iOS9 & iOS10 HTTP 不能正常使用的解决办法 - iOS前沿 - SegmentFault](<https://segmentfault.com/a/1190000002933776>)  
[![46b2ab74-1601-4e9a-9446-937336ae079f](https://user-images.githubusercontent.com/25027560/42729985-8cf233fa-881c-11e8-8e20-5947ab816cb1.png)](<https://user-images.githubusercontent.com/25027560/42729985-8cf233fa-881c-11e8-8e20-5947ab816cb1.png>)  
[![50754b81-27fd-4f0f-b2f6-6f57848886dc](https://user-images.githubusercontent.com/25027560/42729986-8fd61960-881c-11e8-9cf7-a76dd30c58df.png)](<https://user-images.githubusercontent.com/25027560/42729986-8fd61960-881c-11e8-9cf7-a76dd30c58df.png>)

### 4、React：swiper高度限制

swiper自带的的高度是属性控制，不是样式控制  
可以在swiper外面套一层来控制高度

### 5、React：循环渲染时，onPress事件不需要再把item当做参数

否则会拿不到正确的item值  
[![886e1618-d743-415a-a5ee-7d52e5b2fdc6](https://user-images.githubusercontent.com/25027560/42729990-9695ffc2-881c-11e8-95d2-7a5b196c5a99.png)](<https://user-images.githubusercontent.com/25027560/42729990-9695ffc2-881c-11e8-95d2-7a5b196c5a99.png>)  
[![bd9af936-ae2a-40e6-90d5-7e7fc20a6163](https://user-images.githubusercontent.com/25027560/42729993-9cfd6008-881c-11e8-8b8a-428cee38507b.png)](<https://user-images.githubusercontent.com/25027560/42729993-9cfd6008-881c-11e8-8b8a-428cee38507b.png>)

### 6、fecth使用formData上传数据

[![11f82003-de60-4be3-a914-aa9de3735073](https://user-images.githubusercontent.com/25027560/42729994-a2b9edb8-881c-11e8-8f7c-7c29e94bcd18.png)](<https://user-images.githubusercontent.com/25027560/42729994-a2b9edb8-881c-11e8-8f7c-7c29e94bcd18.png>)

### 7、TextInput右边的padding会超出屏幕

flex：1无法读取宽度，需要计算屏幕宽度  
[![6085bd15-316d-40a9-9bb0-e07c0e3f54c6](https://user-images.githubusercontent.com/25027560/42729995-ab721066-881c-11e8-96bc-a9e61747a42e.png)](<https://user-images.githubusercontent.com/25027560/42729995-ab721066-881c-11e8-96bc-a9e61747a42e.png>)  
[![e9508e7c-6a15-4206-874c-726f3bc83ff9](https://user-images.githubusercontent.com/25027560/42729997-ad6a1166-881c-11e8-8503-7b52adc09ac8.png)](<https://user-images.githubusercontent.com/25027560/42729997-ad6a1166-881c-11e8-8503-7b52adc09ac8.png>)

### 8、react-navigation的设置`navigationOptions`里面读取state的数据和绑定方法

需要记得bind(this)  
[![fa70e3e0-78a6-43b3-995e-7ea56742114c](https://user-images.githubusercontent.com/25027560/42729999-b69ac258-881c-11e8-8f51-84d75f319f29.png)](<https://user-images.githubusercontent.com/25027560/42729999-b69ac258-881c-11e8-8f51-84d75f319f29.png>)

### 9、复用input[radio]组件时，ID必须唯一，否则会两个input[radio]之间造成串联，互相影响

[![1b6ac217-52ea-4750-9f2a-13fdd1cdba4e](https://user-images.githubusercontent.com/25027560/42730000-bb1378d4-881c-11e8-958b-4a6428c05582.png)](<https://user-images.githubusercontent.com/25027560/42730000-bb1378d4-881c-11e8-958b-4a6428c05582.png>)

### 10、RN：`AsyncStorage`本地存储，setItems时要用string,不能用到其他类型

    setAsyncStorageIsLaunched() {
        AsyncStorage.setItem('HAS_LAUNCHED',true).then(() => {
          console.log('第一次登录成功',this.getAsyncStorageIsLaunched());
        });
      }

[![d690b9bd-beb5-41e5-a68a-26ce25e6a563](https://user-images.githubusercontent.com/25027560/42730003-c122333c-881c-11e8-9419-4a3e5f77f4f9.png)](<https://user-images.githubusercontent.com/25027560/42730003-c122333c-881c-11e8-9419-4a3e5f77f4f9.png>)

### 11、RN： source.uri should not be an empty string

有可能后台真的没有返回图片链接，虽然不是红色错误，黄色warning也很烦，做好三元判断就好了

    {card.bank_background ? <Image
      style={styles.itemBgIcon}
      resizeMode="contain"
      source={{ uri: card.bank_background }}
    /> : null}

### 12、对于一些依靠后台数据的地方，做好拿不到数据或者错误数据的准备，给一个默认值，防止报错

比如这里，一个渐变模块，后台如果不给颜色，那就会直接报错  
[![b8009866-a6db-43a4-8416-2faef8233be4](https://user-images.githubusercontent.com/25027560/42730004-c8c565dc-881c-11e8-8433-0ccaa5868922.png)](<https://user-images.githubusercontent.com/25027560/42730004-c8c565dc-881c-11e8-8433-0ccaa5868922.png>)

还有一个最常见的情况，数组的渲染，做好多重保险  
[![b11f74a8-9650-4144-82c5-c4c8c29868c8](https://user-images.githubusercontent.com/25027560/42730008-d42535d8-881c-11e8-84cf-d2eeed1af1c0.png)](<https://user-images.githubusercontent.com/25027560/42730008-d42535d8-881c-11e8-84cf-d2eeed1af1c0.png>)

### 13、Raw text cannot be used outside of a tag. Not rendering string: ''

    {card.status_name && (
      <View style={styles.itemTopRight}>
        <Text style={styles.itemTopRightText}>{card.status_name}</Text>
      </View>
    )}

try the !! trick to make sure you only use booleans

    {!!card.status_name && (
      <View style={styles.itemTopRight}>
        <Text style={styles.itemTopRightText}>{card.status_name}</Text>
      </View>
    )}

Or use the ? : 三元运算符

    {card.status_name ? (
      <View style={styles.itemTopRight}>
        <Text style={styles.itemTopRightText}>{card.status_name}</Text>
      </View>
    ) : null}

### 14、React Native ListView 需触摸/滑动后才显示的问题，官方Issues：

[点这里](<https://github.com/facebook/react-native/issues/1831>)

    // 需要在初始化 ListView 时添加以下参数配置
    removeClippedSubviews={false}

### 15、ListView的问题

[![4884a83d-91b2-41b9-9b0b-ddae3f8f9806](https://user-images.githubusercontent.com/25027560/42730009-daa7765a-881c-11e8-9878-dba4aaa17806.png)](<https://user-images.githubusercontent.com/25027560/42730009-daa7765a-881c-11e8-9878-dba4aaa17806.png>)

### 16、使用FlatList的注意事项

[![1a27cad1-e885-4dc3-a93e-230ca8ca0d20](https://user-images.githubusercontent.com/25027560/42730012-dfe0a5ce-881c-11e8-8ced-5805bee2cf3e.png)](<https://user-images.githubusercontent.com/25027560/42730012-dfe0a5ce-881c-11e8-8ced-5805bee2cf3e.png>)

### 17、安卓的物理返回键盘（防止直接退出应用）

监听返回事件，改写  
移除组件的时候，移除监听  
[![35667ac4-91fb-4fd9-98c8-a1416cae5b28](https://user-images.githubusercontent.com/25027560/42730015-e5680aa0-881c-11e8-92a2-5db445ed8ae6.png)](<https://user-images.githubusercontent.com/25027560/42730015-e5680aa0-881c-11e8-92a2-5db445ed8ae6.png>)

### 18、RN：0.44版本后，Navigator和BackAndroid组件都不存在了

从0.44版本开始，Navigator不再从‘react-native’中引入，而是需要

    npm install react-native-deprecated-custom-components –save

并在代码中引入

    import { Navigator } from 'react-native-deprecated-custom-components'

同样从0.44版本开始，`BackAndroid`组件不在出现，而是用`BackHandler`代替

### 19、在render函数中中循环修改state，导致最后栈溢出

[![f0902ea9-4a98-4131-8590-1efead864162](https://user-images.githubusercontent.com/25027560/42730018-ebf1ed1e-881c-11e8-96a3-941fa661b4ce.png)](<https://user-images.githubusercontent.com/25027560/42730018-ebf1ed1e-881c-11e8-96a3-941fa661b4ce.png>)  
[![0b69c191-a047-4872-aa66-61f4b06b3976](https://user-images.githubusercontent.com/25027560/42730019-edcb79f2-881c-11e8-9bcf-f4a454ee5f3f.png)](<https://user-images.githubusercontent.com/25027560/42730019-edcb79f2-881c-11e8-9bcf-f4a454ee5f3f.png>)

看下面，是罪魁祸首  
应该是定义函数，而不是直接执行  
[![7cb4030a-9f12-4878-9a25-ebd7d1732719](https://user-images.githubusercontent.com/25027560/42730020-f23e9ba4-881c-11e8-9bcd-ee335b97e020.png)](<https://user-images.githubusercontent.com/25027560/42730020-f23e9ba4-881c-11e8-9bcd-ee335b97e020.png>)

### 20、开debug模式时load bundle 100% 卡住（未解决），关掉远程debugger就就OK，需要重启电脑解决

[WebSocket connection to ‘ws://localhost:8081/debugger-proxy?role=debugger&name=Chrome’ failed: Invalid frame header · Issue #6627 · facebook/react-native · GitHub](<https://github.com/facebook/react-native/issues/6627>)  
[React-Native Error: Connection to http://localhost:8081/debugger-proxy?role=client timed out - Stack Overflow](<https://stackoverflow.com/questions/37370916/react-native-error-connection-to-http-localhost8081-debugger-proxyrole-clie?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa>)

还没解决  
[RCTModuleData deadlock when running with debugger · Issue #11196 · facebook/react-native · GitHub](<https://github.com/facebook/react-native/issues/11196>)  
[RCTBridge required dispatch_sync to load RCTDevLoadingView. This may lead to deadlocks · Issue #16376 · facebook/react-native · GitHub](<https://github.com/facebook/react-native/issues/16376>)

具体什么情况我也不是很清楚，mac的话，重启电脑就好了（我试验了很多次）

  * 首先需要设置IP和端口，默认端口是8081，手机(模拟器)和电脑在同一个网络中，查询电脑的IP地址。
  * 手动去删除`.babelrc`隐藏文件，具体文件目录为`node_modules/react-deep-force-update/.babelrc`
  * 如果是其他版本，那也是需要删除的不过路径已经发生变化了。具体路径:`/node_modules/react-native/node_modules/react-transform-hmr/node_modules/react-proxy/node_modules/react-deep-force-update`
  * 最后重点 Android项目关闭终端重新执行运行命令，iOS项目也需要关闭服务终端,重新启动packager

### 21、子组件有复杂的数据和操作，需要父组件触发更新，但不想提升到父组件

使用componentWillReceiveProps增加父组件的标志位，子组件检测到父组件传下来的该标志位的变化时，即可触发更新

    componentWillReceiveProps(nextProps) {
        if (nextProps.needUpdatePopularize !== this.props.needUpdatePopularize) {
          this.onRequestData();
          this.requestRank();
        }
      }

### 22、Task orphaned for request <NSMutableURLRequest: 0x1c4202170>

[Unmount images while loading · Issue #12152 · facebook/react-native · GitHub](<https://github.com/facebook/react-native/issues/12152>)  
图片还没完全加载完成的过程中，就触发其他操作，比如页面跳转，这时候又需要unmount 图片，就会出现这些黄色warning  
同理，FlatList如果有很多图片要渲染，上下拉刷新时也会出现这些情况

### 23、安卓打包错误

    FAILURE: Build failed with an exception.

    * What went wrong:
    Execution failed for task ':app:validateSigningRelease'.
    > Keystore file /Users/macbookpro-luoguangcong/projects/newapp/android/app/my-release-key.keystore not found for signing config 'release'.

`android/app`文件夹下面缺一个`my-release-key.keystore`文件，去旧项目复制过来即可

### 24、打包realease包的时候报错 main.jsbundle does not exist. This must be a bug with + echo 'React Native

先打包debug版本 看看有没有JS代码错误  
如果确认OK，再重新yarn一次

### 25、webview 监听页面变化（不是自己写的H5，没办法使用postMessage）

[![96fe8710-9d55-42d2-b8e5-d4b8306e4fcb](https://user-images.githubusercontent.com/25027560/42730024-02f2ebe4-881d-11e8-8682-46f77ebbd98e.png)](<https://user-images.githubusercontent.com/25027560/42730024-02f2ebe4-881d-11e8-8682-46f77ebbd98e.png>)

    _onNavigationStateChange(webViewState) {
        // console.log('webview ？？？', webViewState);
        if (webViewState.url.indexOf('*****') >= 0) {
          this.props.repaymentActions.repaymentSetCreditCardListNew();
          this.props.navigator.pop();
        }
      }

### 26、传参问题 企图修改原型属性

`One of the sources for assign has an enumerable key on the prototype chain. Are you trying to assign a prototype property? We don't allow it, as this is an edge case that we do not support. This error is a performance optimization and not spec compliant.`

[![451d9db7-847d-414f-9242-bb21cf12fab3](https://user-images.githubusercontent.com/25027560/42730025-090233dc-881d-11e8-8ffd-30231bf85120.png)](<https://user-images.githubusercontent.com/25027560/42730025-090233dc-881d-11e8-8ffd-30231bf85120.png>)

该传的参数还是得传  
[![bc76b168-f431-435e-bb51-9e589072df17](https://user-images.githubusercontent.com/25027560/42730026-0c90f1dc-881d-11e8-9f9c-35cbc5e36a5e.png)](<https://user-images.githubusercontent.com/25027560/42730026-0c90f1dc-881d-11e8-9f9c-35cbc5e36a5e.png>)

### 27、关闭弹窗后自动执行两次路由操作

点击弹出框Btn => 收起弹框 => 切换tab => push进其他页面  
1、收起弹框、切换tab，easy  
2、当前处于什么scene就切换什么scene  
3、在切换后的“我的“页面通过`componentWillReceiveProps`监听scene的变化，然后push到对应的组件去

[![d1e051b0-3de0-485e-b10c-a112b8874f69](https://user-images.githubusercontent.com/25027560/42730027-10a670da-881d-11e8-90c5-edd18d39150b.png)](<https://user-images.githubusercontent.com/25027560/42730027-10a670da-881d-11e8-90c5-edd18d39150b.png>)

### 28、App与webview（H5）通信

postMessage发送消息

    sendMessage(data) {
        this.webview.postMessage(data);
      }

onMessage监听

    <WebView
      injectedJavaScript={ debug}
      style={}
      source={{ uri: *** }}
      userAgent={'GuardianAppIOS/1.0.0 Webview'}
      onMessage={this.handleMessage}
    />

但这里有个bug  
[react native html postMessage can not reach to WebView · Issue #11594 · facebook/react-native · GitHub](<https://github.com/facebook/react-native/issues/11594>)

    // the react native postMessage has only 1 parameter while the default one has 2, so check the signature of the function
      waitForBridge(option) {
        if (window.postMessage.length !== 1) {
          setTimeout(() => {
            this.waitForBridge();
          }, 200);
        } else {
          window.postMessage(
            JSON.stringify(option)
          );
        }
      }

通过观察者（发布-订阅）模式进行页面的跳转  
先实例化一个事件发布器

    import EventEmitter from 'react-native/Libraries/vendor/emitter/EventEmitter'

    let emitter = new EventEmitter()

    export default emitter

    if (url.startsWith('http://') || url.startsWith('https://')) {
        return emitter.emit('NAVIGATION_NAVIGATE_TO', 'WebView', url, extraData)
      }

在navigator进行监听，以及销毁时的移除

    // add eventlistener: navigate to
        emitter.addListener('NAVIGATION_NAVIGATE_TO', (routeName, url, extraData) => {
          this.props.dispatch(
            NavigationActions.navigate({
              routeName,
              params: routeName === 'WebView' ? { url, ...extraData } : {},
            })
          )
        })

    componentWillUnmount() {
        emitter.removeAllListeners()
      }

### 29、配置schemes URL

[React Native URL Scheme and Linking API - Johnson Su](<https://johnsonsu.com/react-native-custom-url-scheme-launch-apps-using-linking/>)  
非常棒的指引

### 30、切换App主题

1、替换整个app(理解为品牌)  
将所有color、size、position相关属性抽离出来，放到一个公共文件`commonStyles.js`，导出常量使用  
该文件根据`config.js`中的`THEME`进行判断采用哪一套主题  
如此，只需要修改`THEME`即可，达到一键替换的作用

2、app换皮肤  
新建一个BaseCommon.js页面，作为这四个页面的父类。在这个父类里面接收主题更改的通知，并更新自己的主题。这样一来，继承它的这四个页面就都会刷新自己

### 31、中间模态窗

大概思路：  
1、第三个导航样式上采用区别对待，该tab本来在路由系统中对应了一个页面组件，现在设置为null，改写它的点击事件（其他四个按钮则是正常的切换tab事件），点击则出现全屏弹层  
[![f93afb37-0fba-48fe-ad99-4e7e5ed5aa6a](https://user-images.githubusercontent.com/25027560/42730036-325d7ff2-881d-11e8-89d9-436d6e8fa9aa.png)](<https://user-images.githubusercontent.com/25027560/42730036-325d7ff2-881d-11e8-89d9-436d6e8fa9aa.png>)

2、为实现弹层效果，给一个动画效果，并占满全屏  
[![02145d25-a1e6-4e70-b22b-07c65acaa263](https://user-images.githubusercontent.com/25027560/42730039-372f0758-881d-11e8-9331-d12fa5482baa.png)](<https://user-images.githubusercontent.com/25027560/42730039-372f0758-881d-11e8-9331-d12fa5482baa.png>)

    wrapper: {
        position: 'absolute',
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        backgroundColor: templateUsage.shouldUseTemplateDaily()
          ? '#191A22'
          : 'rgba(40, 47, 51, 0.8)',
      },

3、弹层上的路由设置  
直接抛弃掉真正的路由系统，用状态来控制页面的隐藏和显示，假装是push进一个页面，其实只是由一个state状态来控制一个页面显示，一个页面隐藏而已

消失或者隐藏，也就是加个动画，然页面更自然

    closePopularize() {
        this.state.y.setValue(0);
        Animated.timing(this.state.y, {
          toValue: Dimensions.get('window').height,
          duration: 200
        }).start(this.props.popPopularize);
      }

      clearPopularize() {
        this.state.y.setValue(0);
        Animated.timing(this.state.y, {
          toValue: Dimensions.get('window').height,
          duration: 200
        }).start(this.props.clearPopularize);
      }
