# iOS 面试题

187 题，按 14 个主题分类。给 RN / Hybrid 背景的同学准备——重点在「原生那一侧到底发生了什么」，而不是背 UIKit API。

## 出处

题目与知识体系整理自 [ChaselAn/awesome-ios-interview](https://github.com/ChaselAn/awesome-ios-interview)。该仓库未附 LICENSE，因此本文**全部答案均为重写**，不搬运原文；每题末尾保留 `→ 原文` 链接指向它对应的长文，想看更详尽的展开请点过去。

## 怎么读

答案分两档：

| 标记 | 含义 |
| --- | --- |
| 🔥 | 高频题。完整展开，讲清楚"为什么"，尽量附实测 |
| （无标记） | 低频 / 冷门题。给核心要点，细节看原文链接 |

结论的可信度也分两档：

| 标记 | 含义 |
| --- | --- |
| ✅ 实测 | 代码在本机真实跑过，贴的是**实际输出**。代码见 [ios-snippets/](ios-snippets/) |
| 📖 据文档 | 依据 Apple 官方文档 / 开源 runtime 源码整理，无法在 macOS 上直接运行验证 |

### 实测环境

| | |
| --- | --- |
| 机器 | Apple Silicon |
| Swift | 6.2.3（swiftlang-6.2.3.3.21, clang-1700.6.3.2） |
| 目标 | arm64-apple-macosx26.0 |

ObjC runtime 与 Swift runtime 在 macOS 和 iOS 上是同一套实现，所以**语言、Runtime、内存、并发**这四类结论可以在 macOS 上直接验证。UIKit 不行（macOS 只有 AppKit），因此 UI 渲染、触摸事件、VC 生命周期这些题一律标 📖。

全部验证代码可一键复跑：

```bash
cd ios-snippets && ./run-all.sh      # 15 个程序，全部通过
```

## 目录

| 章节 | 题数 |
| --- | --- |
| [一、App 启动与优化](#一app-启动与优化) | 3 |
| [二、生命周期](#二生命周期) | 8 |
| [三、RunLoop](#三runloop) | 6 |
| [四、底层原理](#四底层原理) | 38 |
| [五、UI 与渲染](#五ui-与渲染) | 18 |
| [六、内存管理](#六内存管理) | 13 |
| [七、多线程与并发](#七多线程与并发) | 9 |
| [八、运行时机制](#八运行时机制) | 11 |
| [九、语言特性](#九语言特性) | 27 |
| [十、数据持久化](#十数据持久化) | 5 |
| [十一、计算机网络](#十一计算机网络) | 19 |
| [十二、架构设计](#十二架构设计) | 8 |
| [十三、崩溃治理](#十三崩溃治理) | 20 |
| [十四、耗电治理](#十四耗电治理) | 2 |
| **合计** | **187** |

> 「计算机网络」一章和 [02-deep-dive.md 的 HTTP 章](02-deep-dive.md#http-协议)主题重叠：那边是链接索引，这里是成文答案，可以对照着看。

---

## 一、App 启动与优化

### 1. APP 启动的详细流程是什么？🔥

启动分冷启动、热启动、预热启动。**冷启动**最完整，以 `main()` 为界分两段。

#### Pre-main：dyld 的活儿

主线程是内核 `fork()` 建进程时一起建的，这一段全部跑在主线程上。

**① 加载可执行文件.** 内核 `mmap()` 把 Mach-O 映射进虚拟内存——注意是惰性的，只有真正访问到的页才会进物理内存（这正是后面「二进制重排」能优化的前提）。然后解析 Header（Magic Number、CPU 架构、文件类型）和 Load Commands（`LC_SEGMENT_64` 映射段并设权限、`LC_LOAD_DYLIB` 记录依赖、`LC_MAIN` 算入口），最后验签。

**② 加载动态库.** dyld 从 `LC_LOAD_DYLIB` 读依赖路径，优先在 dyld shared cache 里找，`mmap()` 进地址空间，验签，然后**深度优先**递归加载依赖（每个库只加载一次）。初始化顺序按依赖关系倒排——被依赖的先来，所以 Foundation 早于 UIKit。用 Swift 的话这里还会加载 Swift 标准库（iOS 12.2+ 已进系统共享缓存，不用再嵌进 App）。

**③ Rebase & Bind.** ASLR 让每次加载基址都不同，指针得修。

- **Rebase**：修**内部**指针 —— 编译期地址 + slide 偏移量
- **Bind**：修**外部**指针 —— 查符号表绑到真实地址，比如 `_objc_msgSend`

**④ ObjC Runtime 初始化.** dyld 通过 `_dyld_objc_notify_register` 回调通知 runtime，触发 `_objc_init` 的 `map_images`：

- 从 `__DATA` 系列段（`__DATA` / `__DATA_CONST` / `__DATA_DIRTY`）读 `__objc_classlist`、`__objc_catlist`、协议列表
- 遍历 `__objc_classlist` 把**所有类**注册进全局类表 `gdb_objc_realized_classes`
- **非懒加载类**（实现了 `+load` 的）立刻 realize：`realizeClassWithoutSwift` 把只读的 `class_ro_t` 展开成可读写的 `class_rw_t`，接上 `superclass` 继承链和 `isa` 元类关系，初始化方法缓存 `cache_t`
- **懒加载类**推迟到首次收到消息时才 realize（`objc_msgSend` → `lookUpImpOrForward` 触发）
- 遍历 `__objc_catlist` 挂 Category：类已 realize 就立刻把方法/属性/协议附加到 `class_rw_t`，**方法插到列表前面**（这就是所谓"覆盖"）；类还没 realize 就先存进 `unattachedCategories`，等 realize 时再挂

**⑤ Swift Runtime 元数据注册.** 遍历各镜像的 Swift section，把 `__swift5_types`（类型元数据）、`__swift5_proto`（协议遵循表）、`__swift5_fieldmd`（字段描述符）的**位置指针**注册进全局缓存。这一步只登记指针，不解析。真正解析推迟到首次使用：`as?` 触发协议遵循查找、`Mirror(reflecting:)` 触发字段描述符解析、泛型首次实例化时才建完整 metadata。

**⑥ 调用 `+load`.** dyld 调 `load_images` 回调，**通过函数指针直接调用，不走 `objc_msgSend`**——所以 Category 的 `+load` 覆盖不了主类的，两个都会执行。全部在主线程串行跑，**直接阻塞启动**。

**⑦ 执行 Initializers.** 遍历各镜像 `__DATA,__mod_init_func` 里的函数指针并调用。来源是 C++ 静态构造函数和 `__attribute__((constructor))`。同一镜像内顺序：带优先级的 constructor（数字小的先）→ C++ 构造函数 → 不带优先级的 constructor。

#### main：开发者能直接控制的部分

1. `main()` —— OC 里调 `UIApplicationMain`（要手动包 `@autoreleasepool`，此时 RunLoop 还没起）；Swift 用 `@main` 让编译器生成入口
2. `UIApplicationMain` —— 建 `UIApplication` 单例 → 建 `AppDelegate` → 读 Info.plist → **启动主 RunLoop**（`CFRunLoopRun()`，进去就不出来了）
3. AppDelegate 回调 —— 加载 Main Storyboard → `willFinishLaunchingWithOptions:` → 状态恢复 → `didFinishLaunchingWithOptions:`
4. 首帧渲染 —— 建 Window → 设 rootViewController → `viewDidLoad` → `viewWillAppear` → `layoutSubviews` → `drawRect` → Core Animation 提交图层树 → Render Server 渲染 → GPU 合成 → 上屏

#### 预热启动（iOS 15+）

系统预测你可能要开 App，提前在后台跑掉一部分：

| | 冷启动 | 预热启动 |
| --- | --- | --- |
| 触发 | 用户点图标 | 系统预测，后台自动执行 |
| Pre-main | 点击后才全部执行 | 大部分已在后台跑完 |
| 用户感知耗时 | 含完整 Pre-main | 只含 `+load` 之后 |

**预热已做**：加载可执行文件、加载动态库、Rebase & Bind、ObjC 类注册与 Category 处理、Swift 元数据注册
**预热未做**：`+load`、Initializers、main 阶段的一切

⚠️ 这对埋点统计是个坑：预热时进程早就创建了，`sysctl` 拿到的 `p_starttime` 可能比用户点击早几小时。用 `ProcessInfo.processInfo.environment["ActivePrewarm"] == "1"` 判断，别把后台预热时间算进用户感知耗时。

> ✅ 上面 ④ 里「Category 方法插到列表前面」和「`+load` 不走 msgSend」两条都有实测，见 [第 2 题](#4-load-方法的执行顺序是怎样的-) 与 [第 105 题](#105-category可以添加实例变量实例方法类方法吗-)。

→ [原文：App 启动流程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/App启动流程.md)

### 2. 如何测量和监控 iOS 应用的启动时间？

四种方案，线下线上各有分工：

| 方案 | 场景 | 优点 | 缺点 |
| --- | --- | --- | --- |
| dyld 环境变量 | 开发调试 | 无需改代码 | 只能定性，没有耗时数字 |
| Instruments App Launch | 深度分析 | 函数级耗时，最详细 | 只能线下 |
| 代码埋点 | 线下 + 线上 | 粒度自定义，可上报 | 要自己维护 |
| MetricKit | 线上监控 | 系统级数据，带分位数 | iOS 13+，每日回调有延迟，粒度粗 |

实践上通常 **Instruments 深挖 + 埋点/MetricKit 兜线上**。

埋点的关键位置：

- **Pre-main**：`sysctl` 取 `p_starttime`（起点）→ `+load`（dylib 加载 + Rebase/Bind + Runtime 初始化已完成）→ `__attribute__((constructor(101)))`（`+load` 跑完）→ `__attribute__((constructor(65535)))`（Initializers 基本跑完）
- **main**：`main()` 顶部 → `willFinishLaunching` → `didFinishLaunching` 首尾 → 首帧（`viewDidAppear` 里套一层 `DispatchQueue.main.async`）

想让埋点的 `+load` 排在最前，把它打成**动态 xcframework** 并在 Link Binary With Libraries 里拖到第一个——动态库的 `+load` 天然早于静态库和主工程。

预热启动会污染数据，处理见上一题：检测 `ActivePrewarm`、改用 `+load` 时间当起点、两类数据分开统计。

→ [原文：启动优化-观测](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/启动优化/启动优化-观测.md)

### 3. 启动优化有哪些方案？🔥

#### Pre-main：核心思路是「减少 dyld 的工作量」

**减少动态库数量.** 每多一个库，dyld 就多一次 mmap + 验签 + Rebase/Bind + 初始化。合并功能相近的库、动态库改静态库、用 SPM（默认静态链接）、定期清理没用的依赖。

**减少要修的指针（Rebase/Bind 的工作量与指针数成正比）.**

| 做法 | 为什么有效 |
| --- | --- |
| 减少 ObjC 类 | 每个类有一大堆元数据指针：isa、superclass、方法列表、属性列表 |
| 减少 Category | 方法、属性、协议指针都要修 |
| 减少 C++ 虚函数 | 虚函数表里每个指针都要修 |
| 用 struct 替代 class | 值类型不产生堆上待修正的指针 |
| 清无用代码 | 没用的类/方法/全局变量照样占指针 |

**削减 `+load`.** 全部主线程串行、直接阻塞启动。能改 `+initialize` 就改（懒的）、能挪到 `didFinishLaunching` 之后就挪、别在 `+load` 里搞 runtime 动态注册、纯 Swift 类压根没有 `+load`。

**削减 Initializers.** C++ 静态构造和 `__attribute__((constructor))` 同样是主线程同步执行。延迟到首次使用、改用 Swift 的 `lazy` 和全局变量（天然懒加载）、把复杂类型的全局变量换成基本类型（`int`、`const char *` 不需要构造函数）。

**二进制重排.** 这是 Pre-main 唯一一个"不改业务代码也能提速"的手段。

原理：`mmap()` 只是建立映射，不代表代码页在物理内存里。启动时执行到某个函数，若它所在的页还没驻留，就触发 **Page Fault**，内核现去二进制里读这一页。启动路径上的函数如果散落在几百个页里，就是几百次缺页中断。重排把它们集中到相邻的页上。

做法：

1. Clang SanitizerCoverage 插桩（`-fsanitize-coverage=func,trace-pc-guard`），每个函数入口插回调
2. 跑一遍 App，收集启动期函数调用顺序，生成 Order File
3. Xcode 的 `Order File` 配置项指定路径，链接器按序排列
4. 用 Instruments 的 System Trace 对比 Page Fault 数量验证

#### main：优化重点

**任务分级.** 别把什么都塞进 `didFinishLaunching` 同步执行：

| 级别 | 时机 | 放什么 |
| --- | --- | --- |
| P0 关键 | `didFinishLaunching` 同步 | 崩溃监控、日志、网络库配置、首屏数据请求 |
| P1 重要 | `didFinishLaunching` 异步 | 推送注册、数据库初始化、非首屏 SDK |
| P2 可延迟 | 首帧后 / RunLoop 空闲 | 统计、分享、广告 SDK、预加载缓存 |

**并行初始化.** 无依赖的任务丢进 GCD 并发队列吃满多核。注意涉及 UI 的必须回主线程。

**蹭 RunLoop 空闲.** 在 `kCFRunLoopBeforeWaiting` 注册 Observer，把低优任务切成小块，每次空闲跑一批——不阻塞启动也不影响交互。

**延迟加载.** 分享/支付/地图 SDK 等用户首次点到相关功能时再初始化；TabBar 里非首页的 VC 等切过去再建；首屏数据后台预加载避免白屏。

→ [原文：启动优化](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/启动优化/启动优化.md)

---

## 二、生命周期

### 4. `+load` 和 `+initialize` 的主要区别是什么？🔥

| | `+load` | `+initialize` |
| --- | --- | --- |
| **时机** | `main()` 之前，dyld 加载镜像时 | 类第一次收到消息时（懒） |
| **是否必然执行** | 只要编译进项目就执行 | 类从没被用过就永不执行 |
| **调用方式** | 函数指针**直接调用** | 走 `objc_msgSend` |
| **Category** | 主类和所有 Category 的都执行，互不覆盖 | Category 的会**覆盖**主类的 |
| **继承** | 子类没实现就不调用任何 `+load` | 子类没实现会调用**父类的**，导致父类被多次调用 |
| **对启动的影响** | 阻塞启动 | 不影响启动 |

最关键的两条是「调用方式」和「继承」——它们直接推出了后面几题的答案。

> ✅ **实测**（[objc-load-initialize.m](ios-snippets/objc-load-initialize.m)）
>
> `Base ← Child ← Grandchild` 三层继承，只有 `Base` 实现了 `+initialize`：
>
> ```
>   +load       Base
>   +load       Child
>   +load       Grandchild
>   +load       Base (Ext) 分类 —— 没有覆盖主类的 +load
>
> (以上是 main 之前由 dyld 触发的 +load)
>
> == +initialize 是懒的：第一次收到消息才触发 ==
>   即将第一次给 Base 发消息…
>   +initialize Base （self=Base）
>
> == 子类没实现 +initialize 会继承父类的，导致父类的被调用多次 ==
>   即将第一次给 Child 发消息…
>   +initialize Child （self=Child）
>   即将第一次给 Grandchild 发消息…
>   +initialize Grandchild （self=Grandchild）
>
> == 再次发消息不会重复触发 ==
>   再给 Base 发一次消息…（下面应该没有 +initialize 输出）
> ```
>
> 三条都被证实了：Category 的 `+load` 和主类的**同时**执行；`+initialize` 直到发消息才触发；`Base` 的 `+initialize` 实现被执行了 **3 次**，`self` 分别是 `Base`/`Child`/`Grandchild`。

→ [原文：+load 与 +initialize 的区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/load与initialize的区别.md)

### 5. `+load` 方法的执行顺序是怎样的？🔥

四条规则，从强到弱：

1. **父类先于子类** —— runtime 保证调子类 `+load` 前父类的已执行完
2. **类先于 Category** —— 所有类的跑完，才轮到 Category 的；两者都会被调用，不覆盖
3. **同级按编译顺序** —— 无继承关系的类之间，按 Build Phases → Compile Sources 里的顺序；多个 Category 之间同理
4. **跨镜像按依赖顺序** —— 被依赖的镜像先执行

上一题的实测输出正好是这个顺序：`Base` → `Child` → `Grandchild` → `Base (Ext)`。

→ [原文：+load 与 +initialize 的区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/load与initialize的区别.md)

### 6. `+initialize` 可能被调用多次吗？🔥

**会。** 子类没实现 `+initialize` 时，子类首次收到消息会沿继承链找到**父类的实现**并执行，`self` 是子类。有几个这样的子类，父类的实现就被执行几次。

[第 4 题的实测](#4-load-和-initialize-的主要区别是什么-)里 `Base` 的实现跑了 3 次，就是这个。

防护写法：

```objc
+ (void)initialize {
    if (self != [Base class]) return;   // 只认自己，子类触发的直接返回
    // 真正的初始化…
}
```

或者用 `dispatch_once`。注意别只用 `dispatch_once` 而不判类型——那样父类逻辑只跑一次，但哪个子类先触发是不确定的，可能不是你想要的那次。

→ [原文：+load 与 +initialize 的区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/load与initialize的区别.md)

### 7. Method Swizzling 应该在 `+load` 还是 `+initialize` 中执行？为什么？🔥

**`+load`。** 三个理由：

1. **天然只执行一次.** runtime 保证每个类的 `+load` 只调一次，不需要 `dispatch_once`。而 `+initialize` 会因继承被多次调用（见上题），多跑几次 `method_exchangeImplementations` 就把 swizzle **换回去了**——偶数次交换等于没换。
2. **线程安全.** swizzle 通常是 `class_addMethod` + `method_exchangeImplementations` 两步，不是原子的。`+load` 在 `loadMethodLock` 保护下串行执行，天然没有竞争；`+initialize` 可能在多线程环境被触发，就算 `dispatch_once` 守住了入口，多步操作之间仍有窗口。
3. **顺序可控.** `+load` 保证父类先于子类，继承链上的 swizzle 顺序是确定的；`+initialize` 的触发顺序取决于哪个类先收到消息，不可控。

→ [原文：+load 与 +initialize 的区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/load与initialize的区别.md)

### 8. `UIApplicationMain` 后面的代码会执行吗？为什么？

**不会。**

```swift
// main.swift
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                  NSStringFromClass(AppDelegate.self))
print("永远不会打印")
```

`UIApplicationMain` 内部建完 `UIApplication` 单例和 `AppDelegate` 后就调 `CFRunLoopRun()` 进主 RunLoop，那是个无限循环，持续处理触摸、Timer、Source。只有 App 被系统终止时才退出，而那时进程已经没了。

→ [原文：App 启动流程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/App启动流程.md)

### 9. `loadView` 的作用是什么？什么时候需要重写它？

`loadView` 负责**创建** VC 的 `view`。访问 `self.view` 时若为 nil，系统自动调它。

默认行为：有 Storyboard/XIB 就从里面加载，没有就建个空 `UIView`。

想用自定义视图**整个替换** `self.view` 时才需要重写：

```swift
override func loadView() {
    view = MyCustomView()   // 不要调 super.loadView()
}
```

⚠️ 重写时**别调 `super.loadView()`**——那会白白创建一个默认 `UIView` 再被你丢掉。

→ [原文：生命周期](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/生命周期.md)

### 10. iOS 13 之后为什么 Present 默认不再触发 `viewWillDisappear`？

因为 `modalPresentationStyle` 的默认值变了：iOS 13 之前是 `.fullScreen`，之后是 `.automatic`（通常表现为 `.pageSheet`）。

- `.fullScreen`：新页面完全盖住旧页面，旧 VC **从视图层级移除** → 触发 `viewWillDisappear` / `viewDidDisappear`
- `.pageSheet`：卡片式弹出，底下还露着一截，旧 VC **没被移除** → 不触发

踩坑场景：在 `viewWillAppear`/`viewWillDisappear` 里成对做的事（注册/注销通知、开始/停止定位）在 iOS 13+ 上会失衡。

解法：显式设 `vc.modalPresentationStyle = .fullScreen`，或者改用 dismiss 的 completion 回调。

→ [原文：生命周期](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/生命周期.md)

### 11. `UIView` 的 `layoutSubviews` 在什么时机被调用？🔥

📖 它不是"立即调用"的方法，而是视图被标记为需要布局后，在后续布局周期里触发。

常见触发点：

1. 视图第一次显示（加入 window 参与布局）
2. 自身 `bounds` / `frame.size` 变化
3. 添加或移除子视图（`addSubview`、`removeFromSuperview`）
4. 修改约束后 Auto Layout 重算
5. 调用 `setNeedsLayout`（异步，下个周期）
6. 调用 `layoutIfNeeded`（同步，立即）
7. 设备旋转、窗口尺寸变化、Safe Area 变化
8. `UIScrollView` 滚动 —— 滚动改的是 `bounds.origin`，所以会**频繁**触发

有个容易搞反的地方：`layoutSubviews` 的语义是「**我来布局我的子视图**」。所以

```swift
parentView.addSubview(childView)
```

直接触发的是 **`parentView`** 的 `layoutSubviews`（它的子视图集合变了）。`childView` 自己会不会触发，取决于它是否也需要重新布局——比如它 `bounds` 变了、它内部还有子视图要排、或者被显式 `setNeedsLayout` 了。

三条注意：

- 别直接调 `layoutSubviews`，要么 `setNeedsLayout`（异步合并）要么 `layoutIfNeeded`（同步）
- 它**可能被调用多次**，里面的操作必须幂等
- 这里能拿到准确的 frame，适合做依赖 frame 的计算

→ [原文：生命周期](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/生命周期.md)

---

## 三、RunLoop

### 12. RunLoop 的作用

一句话：**让线程在有活时干活、没活时休眠，且不退出。**

没有 RunLoop 的线程执行完任务就结束了。RunLoop 是个事件循环，把线程"钉"在那儿等事件；等待期间调 `mach_msg()` 陷入内核态真正休眠，不占 CPU。

> ✅ **实测**（[runloop-modes.m](ios-snippets/runloop-modes.m)）休眠是真的：`BeforeWaiting` 到 `AfterWaiting` 之间线程在 `mach_msg_trap` 里，CPU 占用为 0。

→ [原文：RunLoop](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runloop.md)

### 13. RunLoop 和线程的关系？🔥

- **一一对应**，存在全局字典 `__CFRunLoops` 里，key 是线程
- **懒加载**：主线程和子线程的 RunLoop 都是第一次获取时才创建
- 主线程的 RunLoop 由 `UIApplicationMain` 内部首次获取并启动，调用链 `UIApplicationMain` → `GSEventRunModal` → `CFRunLoopRunSpecific`
- 线程结束时销毁
- ⚠️ **子线程的 RunLoop 不会自动跑起来**，拿到它 ≠ 它在运行，必须自己启动

> ✅ **实测**（[runloop-modes.m](ios-snippets/runloop-modes.m)）
>
> ```
>   主线程上 CFRunLoopGetMain() == CFRunLoopGetCurrent()? 是
>   子线程里 CFRunLoopGetCurrent() = 0xbeac0c000
>   主线程的 RunLoop              = 0x1002c15c0
>   两者不同 -> 每条线程一个，存在全局字典里，key 是线程
> ```

→ [原文：RunLoop](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runloop.md)

### 14. RunLoop 的 Mode 有什么作用？🔥

**核心作用：事件源隔离 + 优先级管理。**

每个 Mode 内部有各自独立的 Source0 / Source1 / Timer / Observer 集合。RunLoop 同一时刻**只能运行在一个 Mode 下**，只处理当前 Mode 里注册的事件源，别的 Mode 里的一概不管。

| Mode | 说明 |
| --- | --- |
| `kCFRunLoopDefaultMode` | 默认模式，App 正常运行时 |
| `UITrackingRunLoopMode` | ScrollView 及其子类滑动时自动切过来，专心处理追踪事件保证流畅 |
| `kCFRunLoopCommonModes` | **不是真正的 Mode**，是个标记集合，默认含 Default + Tracking。往它里加事件源 = 往所有打了 Common 标记的 Mode 里都加一份 |
| `UIInitializationRunLoopMode` | 启动时用，启动完就不用了 |
| `GSEventReceiveRunLoopMode` | 接收系统事件的内部模式，未公开，别碰 |

**切换机制**：切 Mode 要先退出当前 Mode 的循环，再以新 Mode 重新进入。最典型的就是滑动 —— Default ⇄ Tracking 来回切。

> ✅ **实测**（[runloop-modes.m](ios-snippets/runloop-modes.m)）Mode 隔离是硬隔离。同一个注册在 DefaultMode 的 Timer：
>
> ```
>   在 DefaultMode 跑 0.12s      -> 触发 6 次
>   切到另一个 Mode 跑 0.12s     -> 触发 0 次  <- 被 Mode 隔离了
> ```
>
> 这就是 iOS 上「一滚动 Timer 就停」的全部原因。

→ [原文：RunLoop](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runloop.md)

### 15. RunLoop 的运作流程是怎样的？🔥

先分清**外层启动**和**内层循环**两层，很多人答混了：

| 启动 API | 外层行为 | 能被 `CFRunLoopStop()` 停掉吗 |
| --- | --- | --- |
| `runMode:beforeDate:` | 调一次 `CFRunLoopRunSpecific` | 能（本来就只跑一轮） |
| `CFRunLoopRun()` | do-while 反复调，检查返回值 | **能** |
| `[NSRunLoop run]` | 无条件 `while(1)` | **不能** —— 只停掉当前这轮，外层立刻又进去了 |
| `[NSRunLoop runUntilDate:]` | while 未超时 | 同上 |

下面是**一次 `CFRunLoopRunSpecific` 内部**的流程：

```
┌─ CFRunLoopRunSpecific 入口 ─────────────────────────────
│  1. 通知 Observer：kCFRunLoopEntry      ← AutoreleasePool 在这里创建
│
│  ┌─ __CFRunLoopRun do-while ───────────────────────────
│  │  2. 通知 Observer：kCFRunLoopBeforeTimers
│  │  3. 通知 Observer：kCFRunLoopBeforeSources
│  │  4. 处理 Blocks → 处理 Source0 →（若处理了 Source0）再处理一次 Blocks
│  │  5. 探测 GCD 主队列 port 有无消息（超时 0 的非阻塞检查）→ 有则跳到 9
│  │  6. 通知 Observer：kCFRunLoopBeforeWaiting   ← 系统在这里干三件大事
│  │  7. mach_msg() 休眠，等待：Source1 / Timer 到时 / 超时 / 手动唤醒
│  │  8. 通知 Observer：kCFRunLoopAfterWaiting
│  │  9. 按唤醒原因处理：Timer → __CFRunLoopDoTimers
│  │                    主队列 → __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__
│  │                    Source1 → __CFRunLoopDoSource1
│  │  10. 再处理一次 Blocks（步骤 9 可能又提交了新的）
│  │  11. 判断继续 → 回到 2 ／ 退出 → 12
│  └─────────────────────────────────────────────────────
│
│  12. 通知 Observer：kCFRunLoopExit
└──────────────────────────────────────────────────────────
```

**步骤 6 是整个流程里最该记住的一步。** `kCFRunLoopBeforeWaiting` 时系统做三件事：

1. **手势识别回调** —— 触摸由 Source1 收到后，`UIGestureRecognizer` 不立即执行 action，而是等到这里由系统 Observer 统一触发 `_UIGestureRecognizerUpdate`，批量处理状态更新和回调
2. **UI 更新** —— `setNeedsLayout` / `setNeedsDisplay` 只是打标记；到这里 Core Animation 的 Observer 才统一执行 `layoutSubviews`、`drawRect:`、约束更新，并通过 `CATransaction` 把渲染事务提交给 Render Server
3. **AutoreleasePool 释放与重建** —— 释放本轮产生的 autorelease 对象

**退出条件**（步骤 11）：Mode 为空 / 超时 / 被 `CFRunLoopStop()` / `stopAfterHandle` 为真且已处理事件。

> ✅ **实测**（[runloop-modes.m](ios-snippets/runloop-modes.m)）挂个 `kCFRunLoopAllActivities` 的 Observer，跑 0.15 秒，中间有个 Timer 到时：
>
> ```
>     Entry          进入 RunLoop
>     BeforeTimers   即将处理 Timer
>     BeforeSources  即将处理 Source0
>     BeforeWaiting  即将休眠
>     AfterWaiting   刚被唤醒
>     >>> Timer 触发
>     BeforeTimers   即将处理 Timer
>     BeforeSources  即将处理 Source0
>     BeforeWaiting  即将休眠
>     AfterWaiting   刚被唤醒
>     Exit           退出 RunLoop
> ```
>
> 两轮循环的状态序列和上面的流程图完全吻合，Timer 回调确实发生在 `AfterWaiting` 之后。

→ [原文：RunLoop](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runloop.md)

### 16. RunLoop 在实际开发中有哪些应用？🔥

**① NSTimer 滑动时失效.** 见[第 14 题实测](#14-runloop-的-mode-有什么作用-)。两种解法：Timer 加到 `NSRunLoopCommonModes`；或改用 GCD Timer（`dispatch_source_t`，不依赖 RunLoop Mode）。

**② 子线程保活.** 子线程干完活就退出，想让它常驻：

```objc
__weak typeof(self) weakSelf = self;
_thread = [[NSThread alloc] initWithBlock:^{
    // 必须加 Source，否则 __CFRunLoopModeIsEmpty 检查会让 RunLoop 直接返回
    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
    while (weakSelf && !weakSelf->_stopped) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
}];
[_thread start];
```

三个关键点：

- **必须加 Source**（比如 `NSPort`），否则 Mode 为空，`CFRunLoopRunSpecific` 入口直接返回，RunLoop 压根起不来
- **别用 `[NSRunLoop run]`** —— 外层 `while(1)` 停不掉（见[第 15 题的表](#15-runloop-的运作流程是怎样的-)）
- 用 `while + runMode:beforeDate:` 配合标志位，这是 Apple 官方文档推荐的可控写法。`CFRunLoopRun()` 也能保活且能被 stop，但只跑 DefaultMode，外层退出条件不如自定义循环灵活

**③ 卡顿监控.** 子线程拿信号量等主线程 RunLoop 的状态变化通知，超时（比如 50ms）未等到且主线程停在 `kCFRunLoopBeforeSources` 或 `kCFRunLoopAfterWaiting`，说明卡在处理事件上，抓栈：

```objc
static void cb(CFRunLoopObserverRef ob, CFRunLoopActivity activity, void *info) {
    monitor->_activity = activity;
    dispatch_semaphore_signal(monitor->_semaphore);
}
CFRunLoopObserverRef observer = CFRunLoopObserverCreate(
    kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &cb, &context);
CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);

dispatch_async(dispatch_get_global_queue(0, 0), ^{
    while (YES) {
        long r = dispatch_semaphore_wait(semaphore,
                     dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC));
        if (r != 0 && (activity == kCFRunLoopBeforeSources ||
                       activity == kCFRunLoopAfterWaiting)) {
            // 卡顿，记录堆栈
        }
    }
});
```

⚠️ 这个简单版本有**盲区**：主线程停在 `kCFRunLoopBeforeWaiting` 时看起来像"正常休眠"，但也可能是在那一步里做 UI 更新卡住了，这个方案区分不出来。

**④ 蹭空闲跑低优任务.** 在 `kCFRunLoopBeforeWaiting` 注册 Observer，每次空闲取有限个任务执行——图片预加载、日志上报、缓存清理。靠「每轮的任务数」控制对交互的影响。

→ [原文：RunLoop](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runloop.md)

### 17. Timer 的使用注意事项有哪些？🔥

**① 循环引用.** `NSTimer`/`CADisplayLink` 的 target-action 会**强引用 target**，target 再持有 timer 就成环。三种解法：Block API（iOS 10+）配 weak-strong dance、`NSProxy` 中间层弱引用 target、改用 GCD Timer。

**② Mode 切换.** 见第 14 题。

**③ 子线程 RunLoop 默认不跑.** 直接在子线程 `scheduledTimer` 不会触发，得先加事件源再启动 RunLoop。GCD Timer 无此问题。

**④ 精度不保证.** 精度受 RunLoop 繁忙程度影响，主线程一有耗时任务回调就被推迟，而且**错过的不补偿**。`NSTimer` 的 `tolerance` 属性可以让系统合并多个 Timer 的触发时机省电。GCD Timer 精度最高，用 leeway 控制允许误差。

> ✅ **实测**（[runloop-modes.m](ios-snippets/runloop-modes.m)）间隔 10ms 的重复 Timer 跑 300ms，理论约 30 次，中途人为阻塞 80ms：
>
> ```
>   间隔 10ms、跑 300ms，理论应触发约 30 次，实际 22 次
> ```
>
> 少的 8 次正好对应 80ms 阻塞窗口 —— **错过的回调被直接丢弃，不会事后补齐**。

**⑤ 销毁要对.** Timer 加进 RunLoop 后 **RunLoop 会强引用它**。就算用 Block API 断开了 timer→self 的强引用，timer 本身仍被 RunLoop 持有。Block API 的真正价值是让 `self` 能正常 `dealloc`，从而有机会在 `dealloc` 里调 `invalidate`。

- `NSTimer`/`CADisplayLink` 必须 `invalidate` 才能从 RunLoop 移除，**且必须在它注册的那条线程上调**
- GCD Timer 用 `dispatch_source_cancel`。⚠️ 不能直接释放处于 suspended 状态的 `dispatch_source_t`，会 `EXC_BAD_INSTRUCTION` 崩溃，要先 `resume` 再 `cancel`

→ [原文：Timer 的注意事项](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Timer的注意事项.md)
