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

---

## 四、底层原理

### 18. KVC 的底层原理是什么？🔥

KVC 靠 `NSKeyValueCoding` 协议（`NSObject` 默认遵循），底层用的是 ObjC runtime 的方法查找和 ivar 访问能力。考点全在**查找顺序**上。

**`setValue:@"Tom" forKey:@"name"`**

1. 找 setter：`setName:` → `_setName:`，命中任意一个就 `objc_msgSend` 调用，结束
2. 没找到 setter，问 `+accessInstanceVariablesDirectly`（默认 `YES`）。返回 `NO` 就直接跳到第 4 步
3. 找 ivar：`_name` → `_isName` → `name` → `isName`，命中就 `object_setIvar` 直接赋值
4. 都没有 → `setValue:forUndefinedKey:`，默认抛 `NSUndefinedKeyException`

**`valueForKey:@"name"`**

1. 找 getter：`getName` → `name` → `isName` → `_name`。返回值是基本类型会自动包成 `NSNumber` / `NSValue`
2. 没找到就检查**集合代理方法**：NSArray 模式要同时有 `countOfName` + `objectInNameAtIndex:`；NSSet 模式要同时有 `countOfName` + `enumeratorOfName` + `memberOfName:`。满足就返回代理对象（`NSKeyValueArray` / `NSKeyValueSet`）
3. 问 `+accessInstanceVariablesDirectly`
4. 找 ivar：`_name` → `_isName` → `name` → `isName`
5. 都没有 → `valueForUndefinedKey:`，抛 `NSUndefinedKeyException`

注意两个顺序不一样：setter 找两个名字，getter 找四个；ivar 的查找顺序两边倒是一致的。

⚠️ 给**基本类型**属性 `setValue:nil forKey:` 会走 `setNilValueForKey:`，默认抛 `NSInvalidArgumentException`。重写它给个默认值可以免崩。

**Swift 里的区别**：继承 `NSObject` 且属性标了 `@objc dynamic` 的走同一套。而 Swift 原生 KeyPath（`\Person.name`）是**完全不同的机制**——编译期类型安全，用编译器算好的偏移量直接读写内存，不解析字符串也不查方法，更快但没有运行时动态性。

→ [原文：KVC 底层原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/KVC底层原理.md)

### 19. KVO 的底层实现原理是什么？🔥

核心是 **isa-swizzling**。

**① 动态建子类.** 调 `addObserver:` 时，runtime 查有没有 `NSKVONotifying_ClassName`，没有就 `objc_allocateClassPair` 创建 + `objc_registerClassPair` 注册，然后把对象的 **isa 指向这个子类**。

```
添加观察前：instance.isa → Account
添加观察后：instance.isa → NSKVONotifying_Account → Account（superclass）
```

**② 重写 setter.** 把被观察属性的 setter IMP 换成 Foundation 内部的 `_NSSetXXXValueAndNotify` 系列（按类型选，对象用 `_NSSetObjectValueAndNotify`，int 用 `_NSSetIntValueAndNotify`）。逻辑等价于：

```objc
- (void)setBalance:(int)balance {
    [self willChangeValueForKey:@"balance"];
    [super setBalance:balance];        // 调原始 setter
    [self didChangeValueForKey:@"balance"];
}
```

**③ 还重写了三个辅助方法.**

- `class` —— 返回原始父类而非 `NSKVONotifying_` 子类，对外瞒住实现细节
- `dealloc` —— 销毁时做 KVO 清理
- `_isKVOA` —— 返回 YES，供 runtime 内部识别

**④ 观察者信息存哪.** 存在被观察对象的 `observationInfo` 里（`NSObject` 上声明的属性），指向 Foundation 的 `NSKeyValueObservationInfo`，内含一组 `NSKeyValueObservance` 记录（observer、keyPath、options、context）。`didChangeValueForKey:` 触发时从里面找出该 keyPath 的所有记录逐一回调。

> ✅ **实测**（[objc-kvo-internals.m](ios-snippets/objc-kvo-internals.m)）上面四条全部命中：
>
> ```
> == 添加观察者之前 ==
>       object_getClass() = Account                      (真实 isa)
>       [obj class]       = Account                      (对外宣称)
>       setBalance: IMP   = 0x102dc8994
>       setNotObserved:   = 0x102dc89d4
>
> == 添加观察者之后 ==
>       object_getClass() = NSKVONotifying_Account       (真实 isa)
>       [obj class]       = Account                      (对外宣称)
>       setBalance: IMP   = 0x1858efad0      ← 换了！地址落在 Foundation 镜像里
>       setNotObserved:   = 0x102dc89d4      ← 没被观察的属性，IMP 原封不动
>
>   动态子类的 superclass = Account
>
>   动态子类重写了哪些方法：
>       setBalance:
>       class
>       dealloc
>       _isKVOA
> ```
>
> 注意三处细节：`[obj class]` **撒了谎**（仍报 `Account`），`object_getClass()` 才说实话；只有**被观察**的那个属性的 setter 被换了；移除观察者后 isa 会换回 `Account`。

**几个必答的补充点：**

- **直接改 ivar 不触发 KVO**（绕过了 setter）。但用 KVC 的 `setValue:forKey:` 即使没 setter 也会触发，因为 KVC 内部自动包了 `willChangeValueForKey:` / `didChangeValueForKey:`

  > ✅ 实测：`*(int *)((void *)acc + ivar_getOffset(iv)) = 777;` 把值改成了 777，**没有任何回调**；随后手动调一对 `willChange`/`didChange`，回调立刻来了（`balance: 777 -> 777`）。

- 重写 `automaticallyNotifiesObserversForKey:` 返回 `NO` 可关掉自动通知，改为手动控制时机（合并多次变更、只在真正变化时才通知）
- **集合属性直接操作不触发**，要通过 `mutableArrayValueForKey:` 之类的代理方法，它会自动包 `willChange:valuesAtIndexes:forKey:` / `didChange:...`

→ [原文：KVO 底层原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/KVO底层原理.md)

### 20. OC 中的 Block 是函数指针还是对象？底层怎么实现的？🔥

**是对象。** 准确说：Block 是一个**带 isa 的 C 结构体**，结构体里存着一个函数指针 `FuncPtr` 和捕获的上下文。所以它是「对象形式包装的函数指针 + 上下文」，不是裸函数指针。

```c
struct __block_impl {
    void *isa;         // ← 有 isa，所以是 OC 对象
    int   Flags;
    int   Reserved;
    void *FuncPtr;     // ← 函数指针在这儿
};

struct __main_block_impl_0 {
    struct __block_impl        impl;
    struct __main_block_desc_0 *Desc;   // 大小、copy/dispose 辅助函数
    int a;                              // 捕获的变量排在后面
};
```

调 `block()` 实际是取出 `FuncPtr` 调用，并把 Block 自身作为第一个参数传进去，所以函数体里能通过 `__cself` 访问捕获的变量。

> ✅ **实测**（[objc-block-internals.m](ios-snippets/objc-block-internals.m)）把 block 强转成上面的结构体，直接把 isa 和 invoke 读出来了：
>
> ```
>   Block 的 isa    = __NSGlobalBlock__
>   Block 的 invoke = 0x102c84cb8  <- 真正的函数指针在这个字段里
>   继承链：__NSGlobalBlock__ -> NSBlock -> NSObject
> ```

**三种 Block**

| 类型 | 存储 | 什么时候是它 | copy 行为 |
| --- | --- | --- | --- |
| `__NSGlobalBlock__` | 数据区 | 不捕获局部自动变量（只用全局/static 也算） | 什么都不做，返回自身 |
| `__NSStackBlock__` | 栈 | 捕获了局部自动变量且还没被 copy | 拷到堆上，变成 Malloc |
| `__NSMallocBlock__` | 堆 | Stack Block 被 copy 之后 | 引用计数 +1 |

> ✅ **实测** —— 这里有个**比教科书答案更细的坑**：ARC 下你几乎看不到 `__NSStackBlock__`。
>
> ```
>   不捕获外部变量                 : __NSGlobalBlock__
>   捕获变量 + 赋给强引用          : __NSMallocBlock__   <- ARC 自动 copy 了
>   捕获变量 + __unsafe_unretained : __NSMallocBlock__   <- 居然还是被 copy 了
>   捕获变量 + 转裸结构体指针       : __NSStackBlock__    <- 这才看到栈 Block
> ```
>
> 只要把 block 当 ObjC 指针传递或赋值，编译器就插 `_Block_copy`。连 `__unsafe_unretained` 都拦不住——**必须绕开 ObjC 指针转换**（转成裸结构体指针）才能观察到栈 Block。这也解释了为什么 Block 属性要声明成 `copy`：目的就是把可能在栈上的 Block 挪到堆上。

**变量捕获规则**

| 变量类型 | 捕获方式 | Block 内能改吗 | 为什么 |
| --- | --- | --- | --- |
| 局部自动变量 | **值拷贝** | 不能 | 结构体里存的是创建时的副本 |
| `static` 局部变量 | 指针拷贝 | 能 | 在数据区，生命周期够长 |
| 全局 / 静态全局 | 不捕获，直接访问 | 能 | 地址编译期就定了 |
| `__block` 变量 | 包成 byref 结构体，捕获指针 | 能 | 通过 `__forwarding` 访问同一份 |
| 对象类型局部变量 | 指针值拷贝 + 引用管理 | 能改**内容**，不能改指向 | copy 到堆时走 `_Block_object_assign` |

> ✅ **实测**值拷贝：
>
> ```
>   block 外把 normal 改成了 999
>     block 里看到 normal = 1
> ```

**`__block` 的底层：`__forwarding` 转发**

`__block` 不是简单的"按引用捕获"，而是把变量包进一个结构体：

```c
struct __Block_byref_a_0 {
    void                     *__isa;
    struct __Block_byref_a_0 *__forwarding;   // ← 关键
    int                       __flags;
    int                       __size;
    int                       a;
};
```

初始时 `__forwarding` 指向栈上的自己。当捕获它的 Block 从栈 copy 到堆，byref 结构体**也跟着 copy 到堆**，同时把**栈上那份的 `__forwarding` 改指向堆上那份**：

```
栈上 byref                          堆上 byref
┌──────────────────────┐          ┌──────────────────────┐
│ __forwarding ─────────────────→ │ __forwarding ──┐     │
│ a = 10（已失效）      │          │ a = 10         │     │
└──────────────────────┘          └────────────────┼─────┘
                                                   └──→ 自己
```

之后不管从 Block 内还是外访问 `a`，编译器都转成 `a.__forwarding->a`，于是**都落到堆上那一份**，读写一致。

> ✅ **实测**：`__block int mutable_ = 1;` 经过 block 里的 `+= 100`，外部读到 `101`。

⚠️ `__block` 修饰对象时，ARC 下**默认仍是强引用**。`__block` 只解决"能不能改指针指向"，不解决循环引用——这是最常见的误解。

→ [原文：Block 底层原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Block底层原理.md)

### 21. Mach-O 文件由哪几部分组成？🔥

三段：

```
┌──────────────────────────┐
│           Header         │  文件的"身份证"
├──────────────────────────┤
│       Load Commands      │  文件的"目录"
├──────────────────────────┤
│            Data          │  真正的代码和数据
└──────────────────────────┘
```

- **Header** —— 魔数、CPU 类型、文件类型（可执行/动态库/…）、Load Commands 数量
- **Load Commands** —— 描述布局和依赖。常见的：`LC_SEGMENT_64`（段的位置/大小/权限）、`LC_LOAD_DYLIB`（依赖哪些动态库）、`LC_SYMTAB`（符号表）、`LC_DYSYMTAB`（动态符号表）、`LC_MAIN`（入口）、`LC_CODE_SIGNATURE`（代码签名）
- **Data** —— 按 Segment / Section 两级组织

常见 Segment：

| Segment | 权限 | 里面有什么 |
| --- | --- | --- |
| `__PAGEZERO` | 不可访问 | 空的。从地址 0x0 起的保护区，**解引用 NULL 会落在这里，立刻 `EXC_BAD_ACCESS`** |
| `__TEXT` | 读 + 执行 | `__text`（机器码）、`__stubs`（桩）、`__cstring`、`__const`、`__objc_methname`、`__swift5_typeref` |
| `__DATA_CONST` | 读写 → 启动后转只读 | `__got`（非延迟绑定指针）、`__const`、`__objc_classlist`、`__swift5_proto` |
| `__DATA` | 读 + 写 | `__data`（已初始化全局变量）、`__bss`（未初始化）、`__swift5_types`、`__la_symbol_ptr`（延迟绑定指针） |
| `__DATA_DIRTY` | 读 + 写 | 运行时一定会改的数据，单独分页以优化 COW |
| `__LINKEDIT` | 只读 | 符号表、字符串表、代码签名 |

`__DATA_CONST` 和 `__DATA_DIRTY` 是 iOS 13+ 对 `__DATA` 的细分：`__DATA_CONST` 启动完成后转只读，**可被多进程共享**，省内存。

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 22. Segment 和 Section 是什么关系？

两级结构，**Segment 是 Section 的容器**：

- **Segment** 是**内存映射**的基本单位，定义读/写/执行权限，页对齐（iOS 上通常 16KB）
- **Section** 是**数据组织**的逻辑单位，同一 Segment 内的所有 Section 共享该 Segment 的权限

```
__TEXT Segment（可读、可执行、不可写）
├── __text       编译后的机器码
├── __stubs      动态库调用桩
├── __cstring    C 字符串常量
└── __const      常量数据
        ↑ 这四个都继承 __TEXT 的权限
```

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 23. 为什么 iOS App 不能用 dlopen 加载任意动态库？

代码签名机制要求所有可执行代码都经过签名验证。App 只能加载两类：

- 系统动态库（Apple 已签名）
- 嵌在 App Bundle 里、跟 App 一起签名的动态库

从别处下载一个 dylib 再 `dlopen`，签名过不了 —— 这也正是 iOS 上做不了「热更新原生代码」的根本原因。

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 24. Rebase 和 Bind 哪个开销更大？

**Bind 更大。**

- Rebase 只是加法：编译期地址 + slide
- Bind 要**查符号表、做字符串比较**，然后才能绑定

所以优化时减少外部符号引用（Bind）比减少内部指针（Rebase）收益更明显。

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 25. ObjC 和 Swift 的符号名有什么区别？

| | Objective-C | Swift |
| --- | --- | --- |
| 命名规则 | 简单直接，类名/方法名就是符号的一部分 | 复杂 mangling，编码模块、类型、完整函数签名 |
| 含模块名 | ❌ | ✅ |
| 同名类 | 全局命名空间，**整个 App 不能有同名类** | 不同模块可以同名 |
| 避冲突方式 | 靠类名前缀约定（NS、UI、AF…） | 模块名自动区分 |

```
Objective-C:
  -[MyClass doSomething]  →  -[MyClass doSomething]
  类符号                   →  _OBJC_CLASS_$_MyClass

Swift:
  func foo()              →  $s4Main3fooyyF
  MyModule.MyClass        →  $s8MyModule7MyClassC...
```

ObjC 符号不含模块信息，所以不同库里的同名类会冲突：静态链接时报 `duplicate symbol '_OBJC_CLASS_$_MyClass'`；动态库在运行时注册同名类，**行为未定义**。这就是 ObjC 前缀约定的由来。

Swift 符号可以用 `swift demangle` 还原：

```bash
$ swift demangle '$s4Main3fooyyF'
$s4Main3fooyyF ---> Main.foo() -> ()
```

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 26. XCFramework 解决了什么问题？

Xcode 11 引入，解决 Fat Framework 的四个老毛病：

| 问题 | Fat Framework | XCFramework |
| --- | --- | --- |
| 架构冲突 | 真机和模拟器都可能有 arm64（Apple Silicon 的模拟器），**分不开** | 不同变体分目录存放，可共存 |
| 上架 | 含模拟器架构会被拒，得手动 strip | 自动选对架构 |
| 多平台 | 没法同时装 iOS 和 macOS 版 | iOS / macOS / watchOS / tvOS 都行 |
| Swift 版本 | 要求同版本 Swift 编译 | 支持 Module Stability，可跨版本 |

```
MyFramework.xcframework/
├── Info.plist                      描述所有变体
├── ios-arm64/                      真机
├── ios-arm64_x86_64-simulator/     模拟器（Intel + Apple Silicon）
└── macos-arm64_x86_64/
```

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 27. CocoaPods 有哪些库的链接方式？各有什么优缺点？

| Podfile 配置 | 产物 | 链接 | 优点 | 缺点 |
| --- | --- | --- | --- | --- |
| 默认（无选项） | `.a` | 静态 | 体积小、启动快 | 不支持 Module，**Swift Pod 不可用** |
| `use_frameworks!` | `.framework` | 动态 | 支持 Swift、自带 Module、资源打包方便 | **启动慢**，动态库多了还会撞上数量限制 |
| `use_frameworks! :linkage => :static` | `.framework` | 静态 | 启动快 + 支持 Swift + 自带 Module | 体积略大于纯 `.a` |
| `use_modular_headers!` | `.a` + `module.modulemap` | 静态 | 体积最小、启动快、支持 Module | 部分 Pod 不兼容，资源要额外配 |

实践上**推荐第三行**（`:linkage => :static`）：拿到了 Swift 支持和 Module，又没有动态库的启动开销。

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 28. 静态链接和动态链接有什么区别？🔥

| | 静态链接 | 动态链接 |
| --- | --- | --- |
| **时机** | 编译期 | 运行时由 dyld 完成 |
| **符号解析** | 链接器直接重定位，地址写死进可执行文件 | 只记录符号引用，运行时 Bind 填地址 |
| **代码位置** | 库代码复制进可执行文件 | 留在独立的 `.dylib` / `.framework` 里 |
| **App 体积** | 第三方库合并进主二进制 | 第三方动态库要打进 ipa，**体积相近甚至略大**（多了元数据） |
| **内存** | 每个进程各一份 | 系统动态库可跨进程共享物理内存（dyld shared cache）；**App 内嵌的动态库仍是每进程一份** |
| **启动速度** | 快 | 慢（要 Rebase + Bind） |

两个容易答错的点：**动态库不一定更省体积**（内嵌的还得打包）；**内嵌动态库不共享内存**（只有系统库走 shared cache 才共享）。

→ [原文：Mach-O 的链接、装载与库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Mach-O的链接、装载与库.md)

### 29. mmap 有哪些优势？适用于哪些场景？🔥

**五个优势：**

1. **零拷贝** —— 传统 IO 是「磁盘 → 内核缓冲区 → 用户缓冲区」两次拷贝；mmap 直接把文件映射到地址空间，访问即读写，**0 次拷贝**
2. **按需加载** —— 映射时不加载内容，访问到哪页才触发缺页中断读哪页，内存占用与实际访问量成正比
3. **编程模型简单** —— 像操作内存一样操作文件，不用管缓冲区、分块、seek
4. **多进程共享** —— `MAP_SHARED` 的映射可被多进程共享。iOS 上主要用于 App 与 Extension（Widget、Share Extension）间共享数据
5. **崩溃现场可恢复** —— 预映射 ring buffer 写 breadcrumbs、页面路径、网络摘要，进程崩了已写入的映射页通常比用户态缓冲区更容易捞回来。⚠️ 但 mmap **不保证绝对持久化**，完整 Crash Report 还是要写独立文件

**适用：** APM 现场缓存、高性能 KV（MMKV）、大文件处理（日志分析、视频）、离线资源包、数据库（SQLite 也用 mmap）、App ↔ Extension 共享。

**不适用：** 小文件频繁创建删除（mmap 本身有创建开销，不划算）、需要追加写入的文件（mmap 要预先指定大小）。

→ [原文：mmap 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/mmap详解.md)

### 30. mmap 可以映射比物理内存大的文件吗？

**可以。** mmap 只是建立**虚拟地址**映射，物理内存按需分配。只有访问到的页才加载进物理内存，系统会自动换出不常用的页。

映射 10GB 文件在 2GB 内存的设备上完全没问题——只要你不一次性访问全部内容。

→ [原文：mmap 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/mmap详解.md)

### 31. mmap 映射的文件被删除会怎样？

**映射仍然有效。** 这是 Unix 文件系统的引用计数特性：`unlink` 只是删掉目录项，只要还有引用（这里是 mmap 的映射）文件本体就不会真正释放。映射区域照常可读写，直到 `munmap` 后数据才丢失。

→ [原文：mmap 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/mmap详解.md)

### 32. NSObject 中的 isa 是什么？🔥

`isa` 是 `objc_object` 结构体的**第一个成员**，是对象与它的类之间的连接。

它是**动态派发的起点**：调 `[obj doSomething]` 时运行时不是直接跳到函数地址，而是先通过 `isa` 找到类对象，在类对象的方法列表里查，找不到再沿 `superclass` 往上回溯。没有 `isa`，运行时就不知道对象属于哪个类，任何方法查找都无从谈起。

**Non-Pointer isa（64 位优化）**：32 位时代 `isa` 就是个普通 `Class` 指针。64 位上苹果把它改成了联合体 `isa_t`，用位域把 64 位切成多个字段：

- `shiftcls`（33 位）—— 类对象指针
- `extra_rc`（19 位）—— 引用计数
- `has_assoc` —— 有无关联对象
- `weakly_referenced` —— 是否被弱引用
- 等等

原本要 22~26 字节才能存下的信息压进了 8 字节。对象一多，省的内存很可观。

> ✅ **实测**（[objc-isa-metaclass.m](ios-snippets/objc-isa-metaclass.m)）见下一题。

→ [原文：Objective-C 底层原理-NSObject](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C底层原理-NSObject.md)

### 33. 实例对象、类对象、元类对象之间的 isa 和继承关系是怎样的？🔥

这是经典的「isa 指向图」。两条链：

**isa 链**

- 实例对象 isa → **类对象**（查实例方法）
- 类对象 isa → **元类对象**（查类方法）
- 元类对象 isa → **根元类**（NSObject 的元类）
- 根元类 isa → **自己**，闭环

**superclass 继承链**

- 类对象：`SubClass → SuperClass → … → NSObject → nil`
- 元类：`SubClass元类 → SuperClass元类 → … → 根元类 → NSObject类对象 → nil`

⚠️ 最后那步是重点：**根元类的 superclass 指向 NSObject 类对象，不是 nil。** 这让 `NSObject` 的实例方法能给类方法调用兜底——`[NSObject description]` 在根元类里找不到 `+description`，就沿 superclass 回溯到 `NSObject` 类对象，找到并执行了 `-description`。

> ✅ **实测**（[objc-isa-metaclass.m](ios-snippets/objc-isa-metaclass.m)）
>
> 有个必须注意的陷阱：**元类和类同名**，只打印 `class_getName` 根本分不清，得靠 `class_isMetaClass()` 区分。加上标记后：
>
> ```
> == isa 链 ==
> dog 实例  .isa = Dog [类]
> Dog 类    .isa = Dog [元类]
> Dog 元类  .isa = NSObject [元类]   <- 所有元类的 isa 都指向根元类
> NSObject元类.isa= NSObject [元类]   <- 根元类的 isa 指向自己
>
> == 继承链（类对象）==
>   Dog [类]
>   Animal [类]
>   NSObject [类]
>
> == 继承链（元类）==
>   Dog [元类]
>   Animal [元类]
>   NSObject [元类]
>   NSObject [类]          ← 根元类的 superclass 落回了 NSObject 类对象
>
> == 两个关键闭环 ==
> 根元类的 isa 指向自己吗？        是
> 根元类的 superclass 是 NSObject？ 是
>
> == [obj class] vs object_getClass() ==
> [dog class]                  = Dog [类]
> [Dog class]                  = Dog [类]    <- 类对象调 class 返回自己，拿不到元类
> object_getClass([Dog class]) = Dog [元类]   <- 这才是元类
>
> 类对象也是对象：Dog 是 NSObject 的实例吗？ 是
> ```
>
> 最后一条附带说明了「万物皆对象」：类对象本身也是 `NSObject` 的实例。

→ [原文：Objective-C 底层原理-NSObject](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C底层原理-NSObject.md)

### 34. 什么是 Tagged Pointer？和 Non-Pointer isa 有什么区别？🔥

两者都是 64 位下对指针空间的优化，但**优化的东西完全不同**：

- **Non-Pointer isa** 优化的是**已经在堆上的对象的 isa 指针**。对象照样 `malloc` 在堆上，只是把 isa 那 64 位拆成位域顺便存点元信息
- **Tagged Pointer** 优化的是**小值对象本身**。`NSNumber`、短 `NSString`、`NSDate` 这类值足够小的，直接把类型标签和数据编码进那 64 位里，**根本不在堆上分配**。这个"指针"不指向任何内存，它本身就是数据

| | Non-Pointer isa | Tagged Pointer |
| --- | --- | --- |
| 优化对象 | 堆对象 isa 里的空闲位 | 小值对象的指针本身 |
| 有堆分配吗 | 有 | **没有** |
| 引用计数 | 要维护（内嵌 isa 或侧表） | 不需要 |
| 适用范围 | 所有 ObjC 对象 | `NSNumber`、短 `NSString`、`NSDate` 等 |
| 怎么判断 | isa 的 `nonpointer` 位 | 指针**最高位**（arm64）/ **最低位**（x86_64） |

Tagged Pointer 收益更大，因为它把堆分配、引用计数、释放整条流程全跳过了。

> ✅ **实测**（[objc-tagged-pointer.m](ios-snippets/objc-tagged-pointer.m)）实际跑出来比标准答案更细致，有两个意外：
>
> ```
>   @1  （编译期字面量）
>       tagged=no   class=NSConstantIntegerNumber     ← 意外①
>   [NSNumber numberWithInt:1] （运行时构造）
>       tagged=YES  class=__NSCFNumber
>   @(arc4random()%100) （运行时求值）
>       tagged=YES  class=__NSCFNumber
>   numberWithLongLong:~1.2e18 （运行时构造的大数）
>       tagged=no   class=__NSCFNumber                ← 超出可内联位宽，退回堆对象
>   @"abc"  （编译期字面量）
>       tagged=no   class=__NSCFConstantString        ← 意外②
>   运行时短字符串（3 字符）
>       tagged=YES  class=NSTaggedPointerString
>   运行时长字符串（26 字符）
>       tagged=no   class=__NSCFString
> ```
>
> **意外①②：编译期字面量根本不走 Tagged Pointer**，它们是 `NSConstantIntegerNumber` / `__NSCFConstantString` 这类常量对象，编译期就分配好了。只有**运行时构造**的小值才会被 tag。很多资料拿 `@1` 举例说它是 Tagged Pointer，在当前系统上是不对的。
>
> 另外两条：值相同的 Tagged Pointer **指针也相同**；短字符串 3 字符被 tag、26 字符不被 tag，能看出位宽上限。

**Swift 里的对应**：Swift 值类型（`Int`、`Double`）天生栈分配，不需要 Tagged Pointer；但桥接成 `NSNumber` 时仍复用这套机制。Swift `String` 有自己的小字符串内联优化（15 字节以内直接存在结构体里），思路一脉相承。

→ [原文：Objective-C 底层原理-NSObject](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C底层原理-NSObject.md)

### 35. Tagged Pointer 对象能否被弱引用？对 retain/release 有什么影响？

**弱引用：不支持。** 它不是堆对象，没有 SideTable，也永远不会被释放，没法在 `weak_table` 里注册。runtime 创建弱引用时用 `isTaggedPointerOrNil()` 检查，是 Tagged Pointer 就直接返回原值，不做任何注册。

**retain/release：空操作。** 没有引用计数概念，runtime 先判断是不是 Tagged Pointer，是就直接返回。`dealloc` **永远不会被调用**。

这些特判正是它性能优势的来源——省掉了引用计数的原子操作和侧表查找。

> ✅ **实测**（[objc-tagged-pointer.m](ios-snippets/objc-tagged-pointer.m)）
>
> ```
> tagged 对象 retainCount = 9223372036854775807（恒为最大值，不走 SideTable）
>
> weak 赋值后仍可读：7
> 能赋值，但它不是堆对象、没有 dealloc，weak 永远不会被置 nil。
> ```
>
> `9223372036854775807` 就是 `LONG_MAX`。注意措辞要准确：`__weak` 赋值**语法上不报错也能读**，但因为对象永不销毁，那个"自动置 nil"的语义永远不会发生——不是"不能写"，而是"写了没意义"。

→ [原文：Objective-C 底层原理-NSObject](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C底层原理-NSObject.md)

### 36. 实例对象和类对象在底层有什么区别？内存结构分别是怎样的？

底层结构体不同，但**都以 `isa` 开头**——这就是「万物皆对象」的基础。

**实例对象**（`objc_object`），从低地址到高地址：

1. `isa` 指针（8 字节）→ 类对象，用于查实例方法
2. 父类的实例变量（按继承链从上往下排）
3. 本类的实例变量
4. 内存对齐填充

**类对象**（`objc_class`，继承自 `objc_object`）：

1. `isa` 指针（8 字节）→ 元类对象，用于查类方法
2. `superclass` 指针（8 字节）→ 父类，建立继承链
3. `cache` —— 方法缓存，存最近调过的方法
4. `bits` → `class_rw_t` → `class_ro_t`，含方法列表、属性列表、协议列表、ivar 描述

区别一句话：实例对象存**数据**，能有无数个；类对象存**描述信息**，每个类在内存中**只有唯一一份**。

→ [原文：Objective-C 底层原理-NSObject](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C底层原理-NSObject.md)

### 37. 纯 Swift 类和继承自 NSObject 的 Swift 类在底层有什么区别？

**① 实例头部不同.**

- 继承 NSObject：头部是 `isa` 指针（兼容 ObjC runtime），引用计数存在 isa 的 `extra_rc` 位域和 SideTable 里
- 纯 Swift：头部是 `HeapMetadata` 指针 + 8 字节 `InlineRefCountBits`（bit 0-31 unowned 计数，bit 32 isDeiniting，bit 33-62 strong 计数，bit 63 UseSlowRC 标志），**默认内联存储**不用查外部结构，缓存更友好

  ⚠️ 当对象被 weak 引用时，bit 63 置 1，这 8 字节**切换成指向 `HeapObjectSideTableEntry` 的指针**，此后所有引用计数统一由 SideTable 管。**这个切换不可逆。**

**② 类型元数据结构不同.**

- 继承 NSObject：混合结构。前半是标准 `objc_class` 布局（isa/superclass/cache_t/class_data_bits_t → class_rw_t，ObjC 可见的方法/属性/协议列表），后半追加 Swift 的 vtable、typeDescriptor、协议一致性记录。ObjC runtime 只看前半，Swift runtime 看后半，互不干扰
- 纯 Swift：纯 `ClassMetadata`（kind/superclass/flags/instanceSize/vtable），没有 `cache_t` 和 `class_rw_t`，vtable 直接内嵌，更紧凑

**③ 有无 ObjC 元类参与派发.** 继承 NSObject 的有 ObjC 元类，`@objc`/`dynamic` 类方法通过元类方法列表供 `objc_msgSend` 查找。纯 Swift 类不依赖 ObjC 元类，可重写的 `class func` 和实例方法统一放 vtable。

**④ 方法派发.** 两者都支持 vtable / 静态 / 见证表派发。区别在于继承 NSObject 的天然接入 ObjC runtime，可以用 `@objc dynamic` 强制走消息派发，从而支持 Selector、method swizzling、KVO。纯 Swift 类的 Swift-only 成员默认不走 `objc_msgSend`；显式加 `@objc`/`dynamic` 能桥接过去，但**不会因此自动获得完整的 NSObject/KVO 语义**。

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)

### 38. Swift 有哪些方法派发方式？🔥

四种：

| 派发方式 | 怎么找到实现 | 什么时候用它 |
| --- | --- | --- |
| **静态派发** | 编译期就确定地址，直接嵌进调用指令 | struct/enum 的所有方法、`final` 类和 `final` 方法、`private` 方法、`static func` |
| **函数表派发**（vtable） | 查类元数据里的 vtable | 类在 class body 里声明的实例方法（默认）、可被 override 的 `class func` |
| **消息派发** | `objc_msgSend` 动态查找 | ObjC 方法，以及 Swift 里显式 `@objc dynamic` 且 ObjC 可表示的成员 |
| **见证表派发**（witness table） | 查协议见证表 | 通过**协议类型**调用协议要求的方法 |

见证表有个设计细节值得答：它**不存在类型元数据里**，而是作为独立全局符号——见证表本身（函数指针数组）在 `__DATA,__const`，协议一致性记录在 `__TEXT,__swift5_proto`。原因是一个类型可以遵循多个协议，都塞进元数据会让结构大小不固定；独立存储后元数据保持固定布局，靠一致性记录间接关联。

**协议方法的派发取决于调用上下文：**

| 上下文 | 派发方式 |
| --- | --- |
| 具体类型调用 `Circle().draw()` | 静态派发 |
| 协议类型调用 `(c as Drawable).draw()` | 见证表派发 |
| 泛型约束 + **特化成功** | 静态派发（等价于直接生成了具体类型的专用版本） |
| 泛型约束 + 未特化 | 见证表派发（通用版本，见证表当隐藏参数传入） |

**泛型特化的条件**：同模块 + 开优化（`-O`）能特化；跨模块默认不行，除非标了 `@inlinable`；**Debug（`-Onone`）不执行特化**。

#### ⚠️ 两个必踩的坑：协议扩展 和 类扩展

**协议要求方法**（写在 `protocol` 声明体里的）会进见证表，动态派发，能正确找到具体类型的实现。

**协议扩展方法**（只在 `extension` 里定义、不在协议要求里的）**不在任何派发表中**，编译后就是个普通函数符号，所有调用由编译器按变量的**声明类型**静态绑定。

> ✅ **实测**（[swift-dispatch.swift](ios-snippets/swift-dispatch.swift)）同一个 `EnglishGreeter` 实例，换个变量类型结果就变了：
>
> ```
>   用具体类型调用（编译期就知道类型，都走自己的实现）：
>     EnglishGreeter.inProtocol()
>     EnglishGreeter.onlyInExtension()
>   用协议类型调用：
>     EnglishGreeter.inProtocol()      ← 见证表，找到了具体实现
>     默认实现 onlyInExtension()        ← 静态派发，调到了 extension 的默认实现！
> ```
>
> 类扩展同理，而且**编译器根本不让你 `override` 它**：
>
> ```
>   声明为 Base、实际是 Derived：
>     Derived.inClassBody()    ← vtable 派发
>     Base.inExtension()       ← 静态派发
> ```
>
> **SIL 层面的铁证**：把这份代码 `swiftc -emit-sil` 后统计派发指令：
>
> ```
>    1 witness_method   →  #Greeter.inProtocol        （协议要求）
>    2 class_method     →  #Base.inClassBody, #Dyn.viaVTable
>    3 objc_method      →  #Dyn.viaObjC!foreign       （@objc dynamic）
> ```
>
> `onlyInExtension`、`inExtension`、`viaFinal` **压根没出现在这三类指令里**——它们编译成了 `function_ref`，纯静态派发。

想自己验派发方式，这条命令最直接：

```bash
swiftc -emit-sil x.swift | grep -E 'class_method|witness_method|function_ref|objc_method'
#   function_ref   → 直接派发
#   class_method   → 函数表派发
#   witness_method → 见证表派发
#   objc_method    → 消息派发
```

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)

### 39. 纯 Swift 类的编译器有哪些性能优化手段？

1. **栈提升（Stack Promotion）** —— 类实例满足条件（够小、不逃逸、不含内部堆引用）时，把堆分配优化成栈分配，**零 ARC 开销**
2. **引用计数消除（RC Elimination）** —— 数据流分析识别并删掉成对的 retain/release，比如短暂引用、不逃逸的函数参数
3. **生命周期合并（Lifetime Merging）** —— 追踪变量词法作用域，两个变量生命周期不重叠时复用内存槽位

相比 ObjC，Swift 编译器能做的 ARC 优化激进得多。ObjC 的 ARC 优化相对保守，每次赋值和传递都严格 retain/release；Swift 靠追踪 RC Identity 和数据流分析，在保证正确的前提下尽量消掉冗余。

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)

### 40. 为什么协议类型作为函数参数比泛型约束慢？底层区别是什么？🔥

```swift
func drawA(_ shape: any Shape) { shape.draw() }    // 存在类型
func drawB<T: Shape>(_ shape: T) { shape.draw() }  // 泛型约束
```

区别在**参数的底层表示**。

`drawA` 的参数是存在类型，编译器把传入的值装进**存在容器（Existential Container）**——固定大小的结构：

```
24 字节内联缓冲区 (inlineBuffer[3])
+ 8 字节类型元数据指针
+ 8 字节见证表指针
──────────────────────────────
= 40 字节（单协议）
```

具体类型 ≤ 24 字节就直接存在 `inlineBuffer` 里；超过就堆分配，`inlineBuffer[0]` 存堆指针。调 `draw()` 时从容器里取见证表，函数指针间接跳转——见证表派发，**无法内联**。

`drawB` 则可以泛型特化：调用处类型已知时直接生成专用版本，参数就是具体类型，没有容器包装，`draw()` 变成静态派发、可内联。

性能差异来自三处：**容器的构造和拷贝**（大值还要堆分配）、**见证表间接跳转**、**无法内联导致后续优化全都做不了**。

> ✅ **实测**（[swift-existential-generic.swift](ios-snippets/swift-existential-generic.swift)）
>
> 容器大小对上了：
>
> ```
>   MemoryLayout<Small>.size      = 8 字节
>   MemoryLayout<Large>.size      = 40 字节
>   MemoryLayout<any Shape>.size  = 40 字节  <- 恒定，5 个 word
> ```
>
> 性能差距 —— **但必须用 `-O` 测，否则结论是反的**：
>
> ```
>              存在类型    泛型约束    比值
>   -O          5.3 ms     0.5 ms    10.31x
>   -Onone     30.8 ms    24.2 ms     1.27x
> ```
>
> 因为**泛型特化是优化器的功能，`-Onone` 下压根不发生**。拿 `swift x.swift`（默认 `-Onone`）跑基准测试会得出"差不多嘛"的错误结论。

**补充**：协议带类约束（`AnyObject`）时用更紧凑的**类存在容器**（8 字节对象引用 + 8 字节见证表指针），不需要 inlineBuffer。特例：`Any` 是零协议约束的存在容器（32 字节），`AnyObject` 是零协议约束的类存在容器（**仅 8 字节**）。

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)

### 41. 用 `as?` 转协议类型时，Swift 运行时怎么判断类型是否遵循该协议？

靠**协议一致性（Protocol Conformance）查找**。编译器为每一对（类型, 协议）生成一条**一致性记录**，存在 Mach-O 的 `__TEXT,__swift5_proto` 段，记录该类型对该协议的见证表位置。

运行时 `swift_conformsToProtocol` 四步走：

1. **查缓存** —— 全局一致性缓存（哈希表，key 是 (类型, 协议) 对），命中直接返回见证表地址
2. **扫描一致性记录** —— 未命中就遍历所有已加载镜像的 `__TEXT,__swift5_proto` 段逐条匹配
3. **处理条件一致性** —— 记录若标了条件一致性（如 `extension Array: Equatable where Element: Equatable`），递归检查泛型参数是否满足
4. **写缓存** —— 匹配成功后缓存，后续查询接近 O(1)

一个值得提的设计：一致性记录用 **RelativePointer（相对指针）** 而非绝对指针，存的是偏移量。好处是**不需要 dyld 重定位**，所以能放在只读的 `__TEXT` 段，只读页可多进程共享，省内存。

这套机制不只服务 `as?`/`as!`，泛型约束检查、协议类型赋值等所有「判断类型是否遵循协议」的场景都走它。

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)
