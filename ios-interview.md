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

| 章节 | 题号 | 题数 |
| --- | --- | --- |
| [一、App 启动与优化](#一app-启动与优化) | 1–3 | 3 |
| [二、生命周期](#二生命周期) | 4–11 | 8 |
| [三、RunLoop](#三runloop) | 12–17 | 6 |
| [四、底层原理](#四底层原理) | 18–56 | 39 |
| [五、UI 与渲染](#五ui-与渲染) | 57–74 | 18 |
| [六、内存管理](#六内存管理) | 75–87 | 13 |
| [七、多线程与并发](#七多线程与并发) | 88–96 | 9 |
| [八、运行时机制](#八运行时机制) | 97–107 | 11 |
| [九、语言特性](#九语言特性) | 108–133 | 26 |
| [十、数据持久化](#十数据持久化) | 134–138 | 5 |
| [十一、计算机网络](#十一计算机网络) | 139–157 | 19 |
| [十二、架构设计](#十二架构设计) | 158–165 | 8 |
| [十三、崩溃治理](#十三崩溃治理) | 166–185 | 20 |
| [十四、耗电治理](#十四耗电治理) | 186–187 | 2 |
| | **合计** | **187** |

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

> ✅ 上面 ④ 里「Category 方法插到列表前面」和「`+load` 不走 msgSend」两条都有实测，见第 4 题与第 102 题。

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

### 42. 下面代码 `sayGoodbye()` 的输出是什么？为什么？🔥

```swift
protocol Greeting {
    func sayHello()                                     // 协议要求
}
extension Greeting {
    func sayHello()   { print("Hello from protocol") }
    func sayGoodbye() { print("Goodbye from protocol") } // 只在扩展里，不是协议要求
}
struct Person: Greeting {
    func sayHello()   { print("Hello from Person") }
    func sayGoodbye() { print("Goodbye from Person") }
}

let greeter: Greeting = Person()
greeter.sayHello()     // ?
greeter.sayGoodbye()   // ?
```

> ✅ **实测**（Swift 6.2.3）
>
> ```
> greeter.sayHello()      -> Hello from Person       ← 见证表，找到了 Person 的
> greeter.sayGoodbye()    -> Goodbye from protocol   ← 静态派发，调到了扩展的默认实现
>
> 对比：用具体类型调用
> concrete.sayHello()     -> Hello from Person
> concrete.sayGoodbye()   -> Goodbye from Person     ← 同一个方法，结果变了
> ```
>
> SIL 给出了机制层面的直接证据：
>
> ```
> witness_method  #Greeting.sayHello                      ← 走见证表
> function_ref    Greeting.sayGoodbye （扩展版本）          ← 静态绑定
> function_ref    Person.sayGoodbye   （具体类型调用时）
> ```

**原因在于函数地址存在哪里：**

`sayHello` 是**协议要求**，编译器在见证表里给它留了槽位。通过协议类型调用时，运行时从存在容器取出见证表，找到 `Person.sayHello` 的函数指针跳过去——动态派发，能找到具体实现。

`sayGoodbye` **只在扩展里**，不是协议要求，所以它**不在任何派发表中**（既不在见证表也不在 vtable），编译后就是 `__TEXT,__text` 段里一个普通函数符号。编译器在编译期按变量的**声明类型** `Greeting` 直接绑定到扩展版本，运行时**根本没有机会发现** `Person` 还有自己的 `sayGoodbye`。

**结论**：想让具体类型的实现在通过协议类型调用时生效，方法**必须写进 `protocol` 声明体**，不能只放在 extension 里。

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)

### 43. 类型遵循多个协议时，这些协议的方法信息怎么组织？为什么不像虚函数表那样都放进类型元数据？

每个（类型, 协议）组合各有一张**独立的见证表**。

| | 虚函数表 VTable | 见证表 Witness Table |
| --- | --- | --- |
| 归属 | 属于**类** | 属于**一致性关系**（类型-协议组合） |
| 存储 | 内嵌在类的元数据里 | 独立全局符号，在 `__DATA,__const` |
| 怎么找到 | 通过实例头部的 isa / HeapMetadata 直达 | 通过 `__TEXT,__swift5_proto` 的一致性记录间接关联 |
| 数量 | 每个类一张 | **每个类型对每个协议各一张** |

**为什么不内嵌**：一个类型能遵循任意多个协议。都塞进元数据，元数据大小就随协议数量变化，**结构不固定**——运行时就没法用固定偏移量访问 vtable 等其他字段了。独立存储后元数据保持固定布局，见证表靠一致性记录间接关联即可。

→ [原文：Swift 底层原理-结构体、类和协议](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift底层原理-结构体、类和协议.md)

### 44. Swift 的完整编译流程是怎样的？

七步：

1. **词法分析 Lexer** —— 切成 Token 流（关键字、标识符、运算符、字面量），剥掉注释和空白但保留位置信息供诊断用
2. **语法分析 Parser** —— Token 流组织成 AST，此时**还没有类型信息**
3. **语义分析 Sema** —— 前端最复杂的一步：类型推断（基于约束求解器）、类型检查、重载决议、协议一致性检查、访问控制检查，产出**带类型标注的 AST**
4. **SILGen** —— 降为 **Raw SIL**：控制流变成基本块 + 分支指令组成的 CFG，表达式变成 SSA 指令序列，**保守地插入所有必要的 retain/release**
5. **SIL 优化** —— 两组 Pass：**Guaranteed Passes**（任何优化级别都跑，负责诊断：确定初始化、排他性检查、所有权验证）和 **General Passes**（`-O` 才跑：ARC 优化、泛型特化、去虚拟化、内联），产出 **Canonical SIL**
6. **IRGen** —— 降为 LLVM IR：SIL 类型映射成 LLVM 类型，堆分配变成运行时函数调用（`swift_allocObject`），VTable/Witness Table 变成全局常量数组
7. **LLVM 优化 + 代码生成** —— LLVM 自己那套 Pass（指令合并、循环优化、向量化、寄存器分配），生成机器码，链接器产出可执行文件

→ [原文：SIL](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/SIL.md)

### 45. 什么是 SIL？SIL 存在的意义？

SIL（Swift Intermediate Language）是 Swift 编译器的中间表示，夹在 AST 和 LLVM IR 之间。

**为什么需要它**：LLVM IR 是为 C/C++ 设计的通用低级表示，**表达不了 Swift 的高级语义**——ARC、值语义、泛型、协议见证表在 LLVM IR 里都看不出来了。SIL 保留这些信息，让编译器能在降到 LLVM IR 之前做 Swift 特有的优化和检查。

具体解决六个问题：

1. **消除冗余 retain/release** —— SILGen 保守插了一大堆，SIL 层做数据流分析识别并删掉成对的、不影响生命周期的。LLVM IR 层做不到，因为那里 retain/release 只是普通函数调用
2. **消除泛型开销** —— 泛型默认通过值见证表间接操作，SIL 的泛型特化 Pass 在编译期确定具体类型后生成去泛型版本
3. **优化协议动态派发** —— 去虚拟化 Pass 把 `witness_method` 间接调用换成 `function_ref` 直接调用，还能触发内联等级联优化
4. **编译期诊断** —— 基于完整 CFG 和数据流做确定初始化检查、不可达代码检测、switch 穷举检查
5. **内存访问排他性检查** —— `begin_access` / `end_access` 标记访问区间，编译期检测重叠的排他性冲突，测不准的插运行时检查
6. **函数签名优化** —— 死参数消除、Owned-to-Guaranteed 转换（省掉不必要的 retain/release）、未使用返回值消除

→ [原文：SIL](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/SIL.md)

### 46. SIL 中的 OSSA 是什么？有什么作用？

**SSA**（静态单赋值）要求每个变量只被赋值一次，便于数据流分析。**OSSA**（Ownership SSA）是 Swift 5.1 起在 SSA 之上加的所有权模型：**每个非平凡 SIL 值有且仅有一个明确的"所有者"，所有权在编译期被静态验证**。

四种所有权：

| 类别 | 含义 |
| --- | --- |
| `@owned` | 持有所有权，必须负责销毁或转移 |
| `@guaranteed` | 借用语义，调用者保证存活，被调用者**不得销毁** |
| `@unowned` | 无主引用，不保证生命周期 |
| trivial | `Int` 之类平凡类型，无需管理 |

OSSA 里 `strong_retain` / `strong_release` 被换成语义更明确的 `copy_value` / `destroy_value`，并用 `begin_borrow` / `end_borrow` 显式标记借用作用域。好处是能精确消除冗余引用计数、把销毁**提前到最后一次使用之后**；它也是 `consuming` / `borrowing` 参数和 `~Copyable` 类型的底层基础。

→ [原文：SIL](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/SIL.md)

### 47. 开发者可以利用 SIL 做什么？

SIL 虽是编译器内部表示，但可以直接看：

```bash
swiftc -emit-silgen x.swift   # Raw SIL
swiftc -emit-sil    x.swift   # Canonical SIL
swiftc -emit-sil -O x.swift   # 优化后 SIL
```

实际用途：

- **看内存分配在哪** —— `alloc_stack`（栈）、`alloc_ref`（堆）、`alloc_box`（闭包捕获提升到堆）
- **看方法派发方式** —— `function_ref`（静态）、`class_method`（vtable）、`witness_method`（见证表）、`objc_method`（消息）
- **验证优化是否生效** —— 对比优化前后：冗余 retain/release 消了吗、泛型特化了吗、虚调用去虚拟化了吗
- **指导性能调优** —— 按实际生成的指令有针对性地上 `final`/`private`（促进去虚拟化）、值类型（减 ARC）、`@inlinable`（跨模块内联）、WMO
- **理解语言行为** —— Optional 的枚举本质（`switch_enum`）、闭包捕获的 box 提升（`alloc_box` + `partial_apply`）、struct 与 class 的内存模型差异

> ✅ 本文[第 38 题](#38-swift-有哪些方法派发方式-)和[第 42 题](#42-下面代码-saygoodbye-的输出是什么为什么-)的结论就是这么验出来的。

→ [原文：SIL](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/SIL.md)

### 48. Swift 二进制兼容带来的好处是什么？

**① App 体积变小.** ABI 稳定之前每个 Swift App 都要嵌完整的 Swift 标准库（约 10-15MB）。iOS 12.2+ 起 Swift 运行时内置于系统，不用再打包。

**② 启动变快.** 系统级 Swift 运行时进了 dyld shared cache，多 App 共享同一份物理内存页，省掉各自加载的开销。

**③ 能分发预编译二进制框架了.** 这是三个机制合力的结果：

- **ABI 稳定** —— 不同 Swift 版本编译的二进制能正确链接
- **模块稳定性** —— `.swiftinterface` 让不同版本编译器都能导入模块
- **Library Evolution** —— 库可以独立于客户端更新而不破坏兼容

在此之前第三方框架只能发源码（CocoaPods / SPM 源码依赖）或给每个 Swift 版本各编一份。现在直接发 `.xcframework` 就行。

**④ 系统框架可以用 Swift 写.** Apple 自己也受益——系统更新时框架的 Swift 代码可独立升级而不破坏已装的 App，于是能逐步把系统框架从 ObjC 迁到 Swift（SwiftUI、Observation 就是这么来的）。

**⑤ 跨团队协作成本降低.** 各团队独立编译各自模块，产出二进制给别人用，不必全公司锁死同一个 Xcode 版本。

→ [原文：Swift 二进制兼容性](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift二进制兼容性.md)

### 49. 什么是编译插桩？在 iOS 中有哪些应用场景？

编译器在生成代码时自动注入额外指令，**不改变程序逻辑**但能在运行时收集执行信息。发生在 LLVM IR 层，通过 Instrumentation Pass 实现，对源码透明。

| 场景 | 怎么插 |
| --- | --- |
| **Sanitizer** | ASan 在每次内存访问前插边界检查（Shadow Memory 追踪合法区域）；TSan 在内存访问和同步操作处插记录指令查数据竞争；UBSan 在可能未定义行为的操作前插检查 |
| **二进制重排** | SanitizerCoverage（`-fsanitize-coverage=func,trace-pc-guard`）在函数入口插回调，收集启动期调用顺序生成 Order File |
| **代码覆盖率** | `-fprofile-instr-generate` 在基本块边界插计数器，`-fcoverage-mapping` 嵌映射表关联源码位置 |
| **PGO** | 先跑插桩版收集热路径数据，再用 Profile 指导重新编译，优化分支预测、内联和基本块排布 |

⚠️ 插桩有运行时开销：**ASan 约 2x，TSan 约 5-15x**，所以只在 Debug/测试用。PGO 是例外——最终 Release 产物不含插桩。

> 💡 [swift-concurrency.swift](ios-snippets/swift-concurrency.swift) 里的数据竞争可以用 TSan 直接抓出来：`swiftc -sanitize=thread x.swift`。

→ [原文：iOS 编译原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS编译原理.md)

### 50. 什么是类型擦除？为什么 Swift 需要类型擦除？

类型擦除 = 运行时隐藏具体类型信息，让不同类型能通过统一接口操作。

Swift 需要它的**直接原因是 PAT（带关联类型的协议）的限制**：协议一旦有关联类型或 `Self` 约束，就不能直接当类型用，因为编译器不知道关联类型绑定到什么，算不出内存布局和方法签名。

```swift
protocol Container {
    associatedtype Item
    func add(_ item: Item)
}

// ❌ Protocol 'Container' can only be used as a generic constraint
//    because it has Self or associated type requirements
let containers: [Container] = []
```

编译器不知道 `Item` 是 `String` 还是 `Int`，就定不了 `add` 收什么参数，也没法给容器里的值分配正确大小的内存。

两种绕法：

1. **存在类型 `any`** —— 编译器建存在容器，运行时通过见证表间接派发，不需要编译期知道具体类型
2. **手动包装器 `AnyXxx<T>`** —— 把协议层面的关联类型转成泛型参数，`AnyContainer<String>` 就是个完整的具体类型了

→ [原文：类型擦除](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/类型擦除.md)

### 51. Swift 中的存在类型和不透明类型有什么区别？🔥

核心区别：**谁知道具体类型、什么时候确定。**

**存在类型 `any P`** —— 来自存在量词 ∃，「存在某个遵循 P 的类型，但不关心是哪个」。**运行时**确定，同一变量不同时刻可以持有不同具体类型。底层走存在容器 + 见证表间接派发，有运行时开销。

```swift
var animals: [any Animal] = [Dog(), Cat()]   // 异构集合，OK
var pet: any Animal = Dog()
pet = Cat()                                   // 换个类型，OK
```

**不透明类型 `some P`** —— 来自全称量词 ∀，「有一个**确定的**具体类型遵循 P，但不告诉你是哪个」。**编译期**就确定，可静态派发和内联，零额外开销。代价是同一位置必须**始终**是同一种具体类型。

```swift
func makePet() -> some Animal { Dog() }       // ✅

func makeRandomPet() -> some Animal {
    Bool.random() ? Dog() : Cat()             // ❌ 返回类型不一致，编译失败
}
```

> ✅ **实测**（[swift-existential-generic.swift](ios-snippets/swift-existential-generic.swift)）代码里 `returnsAny` 可以按 flag 返回 `Small` 或 `Large`，`returnsSome` 换成两种类型就直接编译不过。

**`any` 关键字的意义**：Swift 5.6 才引入。之前 `let x: Animal` 就是存在类型，但语法上**毫无提示**这里有运行时开销。`any` 强迫开发者有意识地选：要零开销的 `some`/泛型，还是要有开销但灵活的 `any`。Swift 5.7 起，带关联类型的协议**必须**写 `any` 才能当存在类型用。

→ [原文：类型擦除](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/类型擦除.md)

### 52. `any` 和 `some` 分别在什么场景下使用？

**用 `some`** —— 返回类型/属性类型要隐藏具体实现，但**始终返回同一种**具体类型。经典例子是 SwiftUI 的 `var body: some View`：编译器知道 body 的具体类型是 `VStack<TupleView<(Text, Button<Text>)>>` 这种鬼东西，但你不用写出来，改 UI 时也不用跟着改返回类型。

**用 `any`** —— 需要**异构集合**，或函数在不同条件下要返回不同具体类型。

```swift
let shapes: [any Shape] = [Circle(radius: 5), Square(side: 3)]
func randomShape() -> any Shape { Bool.random() ? Circle(radius: 1) : Square(side: 1) }
```

**用泛型约束 `<T: P>`** —— 集合内元素**类型相同**（同构）且要最大化性能。编译器能特化，静态派发甚至内联。

```swift
func process<T: Shape>(_ items: [T]) { for i in items { print(i.area()) } }
// process([Circle(), Square()])   // ❌ 类型不一致
```

**决策**：`some` / 泛型约束是**默认选择**（编译期确定，零开销）；只有真的需要异构能力时才用 `any`。

→ [原文：类型擦除](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/类型擦除.md)

### 53. 标准库 `AnySequence` 这类类型擦除包装器的内部原理是什么？

**Box 模式**：抽象基类 + 具体 Box 子类 + 公开包装器，三层。

```swift
// ① 抽象基类：泛型参数只剩 Element，没有具体序列类型 S
internal class _AnySequenceBox<Element> {
    func makeIterator() -> AnyIterator<Element> { fatalError() }
}

// ② 具体 Box 子类：持有具体类型 S
internal final class _SequenceBox<S: Sequence>: _AnySequenceBox<S.Element> {
    let _base: S
    init(_ base: S) { _base = base }
    override func makeIterator() -> AnyIterator<S.Element> {
        AnyIterator(_base.makeIterator())
    }
}

// ③ 公开包装器
public struct AnySequence<Element>: Sequence {
    internal let _box: _AnySequenceBox<Element>
    public init<S: Sequence>(_ base: S) where S.Element == Element {
        _box = _SequenceBox(base)   // ← 擦除就发生在这一行
    }
    public func makeIterator() -> AnyIterator<Element> {
        _box.makeIterator()          // vtable 派发到子类的 override
    }
}
```

**擦除是怎么发生的**：`_SequenceBox<Array<Int>>` 被赋给类型为 `_AnySequenceBox<Int>` 的属性时发生**向上转型**，泛型参数 `Array<Int>` 从类型签名里消失，只剩 `Element`（即 `Int`）。之后调 `_box.makeIterator()` 通过 vtable 派发到子类的 override，那里面才调用真正的 `Array<Int>.makeIterator()`。

**本质**就是面向对象的子类型多态：父类引用指向子类实例，具体类型信息藏在子类里，被继承层级「吞掉」了。

> ✅ **实测**（[swift-reflection-codable.swift](ios-snippets/swift-reflection-codable.swift)）更轻量的做法是**把方法存成闭包**——标准库的 `AnyPublisher` 走的就是这条路：
>
> ```swift
> struct AnyShape: Shape {
>     private let _area: () -> Double
>     init<T: Shape>(_ s: T) { _area = s.area }   // 捕获具体类型，只留签名
>     func area() -> Double { _area() }
> }
> ```
>
> ```
>   AnyShape(Small(r:2)).area() = 12.566370614359172
>   MemoryLayout<AnyShape>.size = 16 字节（一个闭包 = 2 word）
> ```
>
> 对比 `any Shape` 的 40 字节，闭包方案只要 16 字节。

→ [原文：类型擦除](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/类型擦除.md)

### 54. 存在类型的底层是怎么实现的？为什么有性能开销？

见[第 40 题](#40-为什么协议类型作为函数参数比泛型约束慢底层区别是什么-)，那里有完整的实测数据。补充结构定义：

```c
struct ExistentialContainer {
    void*         valueBuffer[3];   // 24 字节
    TypeMetadata* type;             // 类型元数据指针
    WitnessTable* witnessTable;     // 协议见证表指针
};
```

三部分各司其职：

1. **值缓冲区（24 字节）** —— 具体类型 ≤ 24 字节就内联存这儿；超过就堆分配，缓冲区退化成存堆指针。这就是「小类型的存在类型比大类型快」的原因
2. **类型元数据** —— 运行时靠它对一个「不认识」的类型执行内存分配、拷贝、销毁
3. **协议见证表** —— 类似 C++ 虚表，存协议每个方法要求对应的函数指针

开销来自三处：**见证表间接跳转且无法内联**、**大值类型触发 `malloc`**、**多协议组合时容器里有多张见证表**（`any Hashable & Comparable` 就有两张）。

→ [原文：类型擦除](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/类型擦除.md)

### 55. 泛型约束比存在类型更高效的原因是什么？

特化后的优化是**链式**的：

1. **内存布局已知** —— `Circle` 的大小编译期确定，直接按值操作，不用值见证表
2. **方法地址已知** —— `Circle.area()` 地址编译期确定，直接 `call`，不查见证表
3. **可以内联** —— 实现够短就直接展开进循环，连函数调用开销都省了

| | 泛型 `<T: Shape>` | 存在类型 `any Shape` |
| --- | --- | --- |
| 类型信息 | 编译期已知（特化后） | 运行时才知道 |
| 方法派发 | 静态派发 | 见证表间接派发 |
| 内联 | 可以 | 不可能 |
| 内存操作 | 按已知大小直接操作 | 通过值见证表间接操作 |
| 函数副本 | 每个具体类型一份（空间换时间） | 只有一份通用版本 |

⚠️ **关键的一句**：泛型特化**依赖编译器优化**。`-Onone` 下泛型同样走见证表，性能和 `any` 接近。区别在于泛型**有能力**被特化，而 `any` 在语义上就排除了这个可能——因为数组里每个元素的具体类型都可能不同，编译器没法为"某一个"类型特化。

这也正是[第 40 题实测](#40-为什么协议类型作为函数参数比泛型约束慢底层区别是什么-)里 `-O` 差 10.31x、`-Onone` 只差 1.27x 的原因。

→ [原文：类型擦除](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/类型擦除.md)

### 56. Codable 的底层原理是什么？🔥

**不是运行时反射**，也不是 ObjC 那种遍历属性 + 拼字符串 + KVC 赋值。核心是**编译器合成 + 标准库协议抽象 + 具体 Encoder/Decoder 实现**三层。

`Codable` 本身只是 `Encodable & Decodable` 的组合。关键在于：类型声明遵循 `Codable` 后，只要存储属性也满足编解码条件，编译器就在**编译期自动生成** `CodingKeys`、`encode(to:)`、`init(from:)`。

生成的代码本质就是一份强类型的手写编解码逻辑：

- 编码时 `encode(to:)` 先从 `Encoder` 拿合适的容器（对象用 keyed container、数组用 unkeyed、单值用 single value），按 `CodingKey` 把属性逐个写进去
- 解码时 `init(from:)` 拿对应容器，按属性类型读。**非可选属性走 `decode`**，字段缺失或类型不匹配就抛错；**可选属性走 `decodeIfPresent`**，字段不存在或为 `null` 时得到 `nil`

`Encoder` / `Decoder` 只是抽象协议，不关心最终是 JSON 还是 Plist；真正做格式转换的是 `JSONEncoder` / `JSONDecoder` / `PropertyListEncoder`。`JSONEncoder` 递归调用模型和子模型的 `encode(to:)`，用一个 `storage` 栈维护嵌套层级，最后序列化成 `Data`；`JSONDecoder` 方向相反。

> ✅ **实测**（[swift-reflection-codable.swift](ios-snippets/swift-reflection-codable.swift)）「严格」体现在哪，跑一遍就清楚了：
>
> ```
>   多出未知字段       -> 忽略，正常解码：true
>   缺失 Optional 字段 -> 正常（变 nil）：true
>   缺失非 Optional 字段 -> 抛 keyNotFound(id)，不会静默给默认值
>   类型不匹配         -> 抛 typeMismatch(期望 Int)
> ```
>
> 这是和 OC 字典转模型**最大的行为差异**：Swift 默认严格且报错精确，OC 那套通常静默失败给个 nil/0。

**优劣**：编译期约束强、性能可控、错误路径清晰（`DecodingError` + `codingPath` 能精确定位是哪个字段哪一层出错）。代价是不够动态——复杂字段映射、默认值、条件编码、扁平化/嵌套转换都得手写 `CodingKeys` 或 `init(from:)`。

→ [原文：Codable 底层原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Codable底层原理.md)

---

## 五、UI 与渲染

> 📖 本章全部依据 Apple 文档与公开资料整理。macOS 上只有 AppKit 没有 UIKit，这些结论**无法在本仓库的验证环境里实跑**，所以一律不标「✅ 实测」。

### 57. UIView 和 CALayer 的区别是什么？🔥

| | UIView | CALayer |
| --- | --- | --- |
| 框架 | UIKit | Core Animation |
| 继承自 | `UIResponder` | `NSObject` |
| 职责 | **事件处理**（触摸、手势）、响应链、Auto Layout | **视觉渲染**（位图管理、圆角、阴影、边框、动画） |

关系：每个 `UIView` 内部持有一个 `CALayer`，且 **UIView 是这个 layer 的 delegate**。

**为什么要分开**：职责分离 + 跨平台复用。`CALayer` 能在 iOS（UIKit）和 macOS（AppKit）之间共享，平台特有的交互逻辑交给各自的 View 层去封装。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 58. CALayer 的隐式动画是什么？为什么 UIView 的 layer 没有隐式动画？

**独立创建的** `CALayer` 改可动画属性（`backgroundColor`、`position`、`opacity` 等）时会自动产生 0.25s 过渡动画，这就是隐式动画。

UIView 的 backing layer 没有，是因为 **UIView 作为 layer 的 delegate，在 `action(for:forKey:)` 里返回了 `NSNull`**，把默认动画行为挡掉了。

所以给 UIView 加动画得显式来：`UIView.animate` 系列，或显式 `CAAnimation`。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 59. Auto Layout 的工作原理是什么？🔥

核心是 **Cassowary 约束求解算法**。

每条约束被转成线性等式或不等式：

```
view1.attr = m × view2.attr + c
```

所有约束组成线性方程组，每个视图有 x、y、width、height 四个未知数。Cassowary 用**单纯形法增量求解**——改一条约束不用从头算，在已有解的基础上增量更新。

约束有**优先级 1–1000**：Required（1000）必须满足，Optional 尽量满足，冲突时低优先级的被打破。

⚠️ 性能上的要点：**约束求解的复杂度随约束数量非线性增长**。视图层级一深、约束一多，Layout 阶段耗时会急剧上升——这是列表卡顿的常见原因之一（见[第 74 题](#74-卡顿的常见原因和解决方案有哪些-)）。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 60. `setNeedsLayout` 和 `layoutIfNeeded` 的区别是什么？🔥

| | `setNeedsLayout` | `layoutIfNeeded` |
| --- | --- | --- |
| 同步性 | **异步**，只设标志位 | **同步**，立即执行 |
| 何时触发 `layoutSubviews` | 下一个 RunLoop 周期 | 当场（前提是有待处理的布局标记） |

两者常配合用：约束动画里先改约束（系统自动打标记），再在动画 block 里调 `layoutIfNeeded` 让布局变化被动画系统捕获。详见下一题。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 61. `layoutSubviews` 在什么时候会被调用？

- 视图首次加入视图层级并显示
- `bounds` 变化（含 `frame.size` 改变）
- 添加或移除子视图
- `UIScrollView` 滚动（`contentOffset` 变化导致 `bounds.origin` 变化）→ **高频触发**
- 设备旋转导致父视图尺寸变化
- 调 `setNeedsLayout` 后的下一个布局周期
- 调 `layoutIfNeeded`（有待处理标记时）

⚠️ 添加子视图时，**更直接触发的是父视图的布局**；子视图自己会不会触发取决于它自身是否也需要重新布局。详细展开见[第 11 题](#11-uiview-的-layoutsubviews-在什么时机被调用-)。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 62. 为什么约束动画要在动画 block 里调 `layoutIfNeeded`，而不是修改约束？🔥

```swift
// ✅ 正确
someConstraint.constant = 100
UIView.animate(withDuration: 0.3) {
    self.view.layoutIfNeeded()
}

// ❌ 错误
UIView.animate(withDuration: 0.3) {
    someConstraint.constant = 100
}
```

**改约束只是更新了约束对象的值 + 标记视图需要布局，本身不产生任何可动画的属性变化。** 真正改变 `frame` 的是 `layoutSubviews`，而它由 `layoutIfNeeded` 触发。

动画系统只能捕获 block **内**发生的可动画属性（如 frame）变化。所以必须把 `layoutIfNeeded` 放进 block，让 frame 的实际变化发生在动画上下文里。

错误写法的结果是：约束值变了，但 frame 是在下个 RunLoop 周期才更新的，那时动画上下文早没了——于是**瞬间跳变，没有动画**。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 63. 为什么不能在 `layoutSubviews` 中修改约束？

会**死循环**：改约束 → 系统重新标记该视图需要布局 → 再次触发 `layoutSubviews` → 又改约束 → ……

约束更新应该放在 `updateConstraints` 里，用 `setNeedsUpdateConstraints` 标记触发。这样约束更新在布局**之前**完成，不产生循环依赖。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 64. `setNeedsDisplay` 和 `setNeedsLayout` 的区别是什么？

| | `setNeedsDisplay` | `setNeedsLayout` |
| --- | --- | --- |
| 触发回调 | `draw(_:)` | `layoutSubviews` |
| 所属阶段 | **绘制** | **布局** |
| 用途 | 重绘视图内容（颜色、形状） | 重算子视图的位置和大小 |
| 会互相触发吗 | **不会** | **不会** |

两者属于不同的更新阶段，完全独立。既要重新布局又要重绘，得**分别调用**。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 65. 约束、布局、绘制三个阶段的执行顺序和方向分别是什么？🔥

| 阶段 | 方向 | 为什么 |
| --- | --- | --- |
| **约束** | 叶子 → 根（由内到外） | 父视图的布局可能依赖子视图的固有尺寸 `intrinsicContentSize` |
| **布局** | 根 → 叶子（由外到内） | 子视图的位置和大小依赖父视图的 `bounds` |
| **绘制** | 根 → 叶子（由外到内） | 同上 |

记住这个方向差异就能解释很多现象——比如为什么 `UILabel` 不设宽度约束也能撑开父视图（约束阶段由内到外，label 的固有尺寸先被算出来）。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 66. 如何在添加约束后立即获取视图的 frame？

```swift
let label = UILabel()
label.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(label)
NSLayoutConstraint.activate([...])

print(label.frame)      // (0, 0, 0, 0) —— 布局还没执行

view.layoutIfNeeded()   // 强制同步执行布局
print(label.frame)      // 正确的值
```

加约束后系统只是**打了标记**，要到下一个 RunLoop 周期才执行。`layoutIfNeeded` 同步触发布局计算，之后就能拿到正确 frame。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 67. 连续调用多次 `setNeedsLayout` 会触发多次 `layoutSubviews` 吗？

**不会。** `setNeedsLayout` 只是设一个布尔标志位，调 100 次和调 1 次效果相同。系统在下一个 RunLoop 周期检查该标志，为 YES 就调**一次** `layoutSubviews`，调完清零。

这是 iOS 视图更新的**合并（coalescing）机制**，避免重复计算。同理适用于 `setNeedsDisplay`。

> 这也是为什么 `layoutSubviews` 里的操作必须**幂等**——你无法控制它被调用几次。

→ [原文：布局方法详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/布局方法详解.md)

### 68. 描述一下 iOS 触摸事件从产生到响应的完整流程？🔥

分四段。

#### ① 硬件与系统层

1. 触摸屏硬件检测到电容变化，**IOKit.framework** 接收硬件中断，生成 `IOHIDEvent`
2. **SpringBoard** 收到事件，根据当前前台 App 判断该转发给哪个进程
3. 通过 **mach port**（内核级 IPC）把 `IOHIDEvent` 转给目标 App 进程
4. App 主线程 RunLoop 被唤醒：事件先由 **Source1**（基于 port，收系统/跨进程消息）接收，包装后交给 **Source0**（基于回调，处理 App 内部事件）
5. 封装成 `UIEvent`，内含一个或多个 `UITouch`。每个 `UITouch` 对应一根手指，记录位置、阶段（began/moved/ended）、时间戳

#### ② Hit-Testing（自上而下找到响应者）

6. `UIApplication` 调 `sendEvent:` 把事件交给 `UIWindow`
7. `UIWindow` 调 `hitTest:withEvent:` 开始递归：对每个子视图先 `pointInside:withEvent:` 判断触点是否在 bounds 内，再**逆序**递归子视图的 `hitTest:`。**逆序是因为后添加的子视图在视觉上更靠前，应该优先响应**。最终确定层级最深的可交互视图作为 Hit-Test View
8. 三类视图会被**跳过**：`hidden = YES`、`alpha <= 0.01`、`userInteractionEnabled = NO`
9. ⚠️ **Hit-Testing 只在 touch began 阶段执行一次**。后续同一触摸序列的 moved/ended 直接发给已确定的 Hit-Test View，**不会因为手指移到别的视图上就重新寻址**

#### ③ 事件分发（手势识别器优先）

10. `UIWindow` 的 `sendEvent:` 在同一次 RunLoop 迭代中，**先**把触摸发给 Hit-Test View 自身及其**父视图链上所有关联的手势识别器**
11. **然后**才发给 Hit-Test View 的 `touchesBegan:`。若手势识别器设了 `delaysTouchesBegan = YES`，系统会暂扣 began 及后续 moved，等手势结果确定后再决定补发还是丢弃
12. 手势识别过程**可能跨越多次 RunLoop 迭代**——tap 要等手指抬起，long press 要等一段时间，swipe 要判断方向和速度

**识别结果：**

- 识别成功 且 `cancelsTouchesInView = YES`（默认）→ 系统给 View 发 `touchesCancelled:`，View 不再收后续事件，手势的 action 触发
- 识别失败 → View 继续正常接收后续触摸事件，手势不产生 action

#### ④ 响应者链传递（自下而上）

13. 所有能接收触摸的对象（`UIView`、`UIViewController`、`UIWindow`、`UIApplication`）都继承自 `UIResponder`，`touchesBegan:withEvent:` 正是 `UIResponder` 定义的
14. Hit-Test View 不处理（回调里调了 `super`）就沿 `nextResponder` 向上传：

    ```
    Hit-Test View → 父 View → … → UIViewController → 父 VC → UIWindow
                 → UIApplication → UIApplicationDelegate
    ```

15. 链上任一响应者重写了回调**且没调 super**，传递终止。到链末端仍无人处理，事件被丢弃

→ [原文：响应者链与事件处理机制](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/响应者链.md)

### 69. 父视图加了 UITapGestureRecognizer，点击子视图 UIButton 或自定义 UIControl，分别会怎样？🔥

**结果不一样**，这是个很好的区分题。

**UIButton：只触发按钮的 action，手势不触发。**
UIButton **重写了 `gestureRecognizerShouldBegin:`**，对非自身视图上的单指单击 `UITapGestureRecognizer` 返回 `NO`，手势识别器直接进 Failed 状态，按钮的 target-action 正常触发。

**自定义 UIControl：手势触发，控件的 action 不触发。**
`UIControl` 基类**没有**重写 `gestureRecognizerShouldBegin:`。父视图链上的手势正常识别成功后，会 cancel 掉控件的触摸，导致 target-action 触发不了。

**解法**：在自定义控件里重写 `gestureRecognizerShouldBegin:`，对冲突手势返回 `NO`。

> 补充：系统内置控件普遍做了这类防御——`UISlider` 会阻止 swipe，`UIButton` 会阻止单击 tap。自己写的 `UIControl` 子类不会自动获得这个待遇。

→ [原文：响应者链与事件处理机制](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/响应者链.md)

### 70. UIButton 上盖了一个 UIView，点击该 UIView，UIButton 的 action 会触发吗？

**不会。**

虽然 `UIControl` 重写了 `touchesBegan:`，但它内部会检查 **`touch.view` 是不是自身**。而 `UITouch` 的 `view` 属性在 **Hit-Testing 阶段就已确定**，指向 Hit-Test View。

覆盖的那个 UIView 默认 `userInteractionEnabled = YES`，于是它成了 Hit-Test View。即使它不处理事件、事件沿响应者链传回 UIButton 的 `touchesBegan:`，此时 `touch.view` 指的仍是那个 UIView —— UIButton 不会启动 tracking 流程，action 无法触发。

**解法**：把覆盖视图的 `isUserInteractionEnabled` 设为 `false`，让它在 Hit-Testing 中被跳过，Hit-Test View 重新落回 UIButton。

→ [原文：响应者链与事件处理机制](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/响应者链.md)

### 71. 有哪些常见场景需要利用响应者链和 Hit-Testing？

| 场景 | 做法 |
| --- | --- |
| **扩大按钮点击区域** | 重写 `pointInside:withEvent:`，把判定范围扩到 bounds 之外（如四周各 10pt），**不用改实际 frame** |
| **子视图超出父视图 bounds 仍可点** | 默认父视图 `pointInside:` 返回 NO 会让 Hit-Testing 提前终止。重写父视图的 `hitTest:withEvent:`，跳过 `pointInside:` 限制，直接对子视图坐标转换后递归检查 |
| **穿透遮罩层让下层响应** | 重写遮罩层的 `hitTest:withEvent:`：命中自身就返回 `nil`（穿透），命中子视图正常返回（遮罩上的关闭按钮仍可交互） |
| **跨层级通信** | `UIApplication` 的 `sendAction:to:from:forEvent:` 中 target 传 `nil` 时，action 会沿响应者链向上找第一个能响应该 selector 的对象。深层嵌套 Cell 里的按钮事件可以直接传给 VC，**不用逐层 delegate 或闭包** |
| **手势与控件冲突** | 手势代理的 `gestureRecognizer:shouldReceiveTouch:` 排除 UIControl 区域；或设 `cancelsTouchesInView = NO` 让两者同时响应 |
| **全局点击收起键盘** | 根视图/Window 上加 `UITapGestureRecognizer` 并设 `cancelsTouchesInView = NO`，点空白处调 `endEditing:`，同时不影响其他控件 |

→ [原文：响应者链与事件处理机制](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/响应者链.md)

### 72. iOS 中卡顿的本质是什么？如何产生的？🔥

**本质是掉帧。** 屏幕以固定频率刷新（60Hz 设备 16.67ms 一帧），每次 VSync 信号到来时系统从帧缓冲区取一帧显示。这一帧的渲染没按时完成，屏幕只能**重复显示上一帧**，用户就感到卡。

#### 先搞清三棵图层树

| 树 | 在哪 | 是什么 |
| --- | --- | --- |
| **Model Tree** | App 进程 | 开发者直接操作的属性（`layer.position = …`），改了立即生效但不触发渲染 |
| **Presentation Tree** | App 进程 | 反映当前屏幕上**实际显示**的值。非动画时与 Model Tree 同步；动画时 Model Tree 已是终点值，而它在 `layer.presentation()` 被调用时**根据本地动画描述实时计算插值**（不是 Render Server 回传的） |
| **Render Tree** | Render Server 进程 | GPU 实际渲染依据的私有副本。每次 Commit 时 Model Tree 的变更通过 IPC 同步过来 |

⚠️ **动画过程中做命中测试必须用 `layer.presentation()`**，因为 Model Tree 早就是终点值了。

#### 一帧的三个阶段

**阶段一：App 进程（CPU，主线程）**

主线程在 Handle Events 阶段处理触摸、手势、Timer，这些回调里的 UI 修改写进 **Model Tree** 并把图层标记为 dirty。然后 RunLoop 在 **BeforeWaiting** 时触发 `CA::Transaction::commit()`，进入 Commit Transaction 的四个子阶段：

| 子阶段 | 干什么 | 性能坑 |
| --- | --- | --- |
| **Layout** | 遍历 dirty 图层，调 `layoutSubviews()` 解 Auto Layout，frame 写回 Model Tree | 约束复杂度**非线性增长**，层级深时耗时急剧上升 |
| **Display** | 对需重绘的图层调 `draw(_:)`，用 Core Graphics 在 **CPU** 上生成位图 | 重写 `draw(_:)` 会额外分配大块内存 |
| **Prepare** | 图片延迟解码（PNG/JPEG → 位图）和格式转换 | **没提前在后台解码的大图会在这里阻塞主线程** |
| **Commit** | Model Tree → Render Tree 的**同步点**，也是 Presentation Tree 的更新时机。dirty 属性序列化后经 Mach Port 发给 Render Server | 图层越多序列化开销越大 |

**阶段二：Render Server（`backboardd`，独立进程）**

收到图层树快照后合并进 Render Tree。**进行中的动画直接在 Render Tree 上按曲线插值——从插值到渲染指令生成再到 GPU 提交，整条链路都由 Render Server 独立驱动，不依赖 App 主线程。这就是 Core Animation 动画不受主线程卡顿影响的原因。**

然后遍历 Render Tree：图层排序（画家算法）、可见性剔除、离屏渲染判定，最后翻译成 Metal 渲染指令（Draw Calls）提交给 GPU。

**离屏渲染**是这个阶段的头号杀手：`cornerRadius + masksToBounds`、无 `shadowPath` 的阴影、`mask`、`allowsGroupOpacity` 等会让 GPU 额外分配离屏缓冲区，产生上下文切换和内存带宽开销。

**阶段三：GPU 渲染**

顶点处理 → 图元装配（一个矩形 CALayer 被拆成**两个三角形**，GPU 原生只处理三角形）→ 光栅化（三角形转成离散片段，每片段对应一个像素位置）→ 片段着色（按纹理坐标采样颜色；圆角裁剪、高斯模糊要更复杂的计算）→ 混合：

```
Result = Source.RGB × Source.A + Dest.RGB × (1 − Source.A)
```

不透明图层可跳过混合直接覆写。GPU 瓶颈主要来自**过度绘制**（多层半透明重叠，像素被反复处理）、**离屏 Pass 切换**、**大纹理上传占带宽**。

**最终显示**：VSync 到来，前后缓冲区交换（双缓冲），显示新帧。

#### 为什么掉帧

三个阶段的时间预算是**串行叠加**的——CPU 多花 1ms，留给 GPU 的就少 1ms。60Hz 设备上 CPU + Render Server + GPU 的总耗时必须挤进 16.67ms。任何环节超时，VSync 到来时帧缓冲区没有新数据，屏幕重复上一帧，即掉帧。

| 瓶颈类型 | 典型原因 | 排查工具 |
| --- | --- | --- |
| CPU | 复杂布局、主线程同步 IO、大量文本绘制、图片主线程解码 | Time Profiler |
| GPU | 离屏渲染、过度绘制、超大纹理 | GPU Report / Core Animation |
| 带宽 | 高分辨率图片频繁上传显存 | Metal System Trace |

→ [原文：卡顿原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-原理.md)

### 73. 如何检测 iOS 应用的卡顿？有哪些检测方案？🔥

六种方案 + 一个所有方案共有的难题。

| 方案 | 原理 | 适用 | 局限 |
| --- | --- | --- | --- |
| **① CADisplayLink 帧率** | 记录每次回调时间戳，每秒算一次 FPS，低于 55 就是掉帧 | 开发阶段悬浮窗实时看 | 只知道"掉帧了"，**不知道是哪段代码**；主线程阻塞时它自己的回调也被延迟 |
| **② RunLoop Observer** | 子线程用信号量等 RunLoop 状态变化，超阈值（如 100ms）没等到就判定卡顿，向主线程发 `SIGURG` 触发 `backtrace` 采集真实堆栈 | 开发 + 线上 | 有 `BeforeWaiting` 盲区，见下 |
| **③ 子线程 Ping** | 子线程定期 `DispatchQueue.main.async` 丢个置标志位的任务，超时未执行就判定阻塞 | 线上 | 实现简单但精度受阈值限制，还得自己实现堆栈采集 |
| **④ Instruments** | Time Profiler（CPU 热点）、Core Animation（FPS、离屏渲染）、System Trace（线程调度、锁竞争、IO） | 仅开发 | **无法部署线上** |
| **⑤ MetricKit（iOS 13+）** | 系统级收集，**零额外开销**。iOS 14+ 还能拿卡顿堆栈 `MXCallStackTree` 和滚动卡顿率 `scrollHitchTimeRatio` | 线上长期趋势 | **每日回调一次，不实时** |
| **⑥ Sentry ANR V2** | 基于**帧延迟**分析，能区分完全阻塞和非完全阻塞 | 线上 | 见下 |

**② 的盲区值得单独说**：简单方案（单个 Observer，order=0）盯的是 `BeforeSources` 和 `AfterWaiting`，但 **UI 布局/绘制、手势回调等系统 Observer 是在 `kCFRunLoopBeforeWaiting` 阶段执行的**，它们的耗时捕获不到。微信 Matrix 的解法是注册**两个** Observer（order 分别为 `LONG_MIN` 和 `LONG_MAX`）把所有系统 Observer 夹在中间。

#### ⑥ Sentry ANR V2 的思路

三个组件协作：`SentryFramesTracker`（CADisplayLink 记录每帧实际耗时，超 16.67ms 标为延迟帧）→ `SentryDelayedFramesTracker`（存储并支持按区间查询，返回 `delayDuration` 和 `framesContributingToDelayCount`）→ `SentryANRTrackerV2`（Watchdog 线程，把 2 秒超时切成 5 份，每 0.4 秒查一次）。

判定：

```
framesContributingToDelayCount == 1 且 delayDuration >= 2s
    → Fully Blocking（完全阻塞）

framesContributingToDelayCount > 1 且 delayDuration > 2s × 99%
    → Non-Fully Blocking（非完全阻塞）
```

```
Fully Blocking：
0s                                    2s
|-------------------------------------|
|      一个函数 A 一直占着主线程         |
|      整个周期只产生了 1 帧延迟          |
                                      └─ 采集堆栈 → 指向 A → 可信 ✅

Non-Fully Blocking：
0s      0.5s   0.8s   1.2s   1.5s    2s
|-------|------|------|------|--------|
| 函数A  |函数B |函数C |函数D |函数E   |
| 5 帧都贡献了延迟，累加超过 99% 阈值      |
                                      └─ 采集堆栈 → 指向 E → 不可信 ⚠️
```

**99% 这个阈值的设计考量**：就算卡 0.5 秒、渲染约 5 帧、再卡 0.5 秒，用户仍有机会响应输入（比如点返回），此时帧延迟约 97%。只有超过 99%，应用才真正「看起来卡死了」。

**Sentry 的价值不在于解决了堆栈采集时机问题**（没有方案能完美解决），而在于用 `framesContributingToDelayCount` 告诉你这份堆栈**可不可信**。

#### 所有超时采集方案的共同难题

```
阈值 2 秒：
0s                   1.9s  2.0s
|---------------------|-----|
|      函数 A (1.9s)   |函数B|
                            ↑ 超时触发采集 → 堆栈指向 B
                              但真凶是 A
```

检测机制是「定时检查」而非「持续监控」，只能在超时那一刻拍快照，无法回溯。五个优化策略：

1. **周期性采样** —— 整个检测期间每 100ms 采一次，留最近 N 个样本，分析出现频率最高的调用路径。⚠️ CPU 开销大（要靠 `SIGURG` + `backtrace`），只适合灰度/测试
2. **堆栈聚合** —— 把样本按调用路径去重，统计每条出现次数降序排列，数据量大减后才好上报
3. **退火算法** —— 解决的是**检测本身的性能损耗**：连续采到相同堆栈时按**斐波那契数列**递增检测间隔（1→1→2→3→5→8→13…），堆栈变了就重置为 1。好处是避免重复写入、主线程已卡死时不再雪上加霜
4. **火焰图** —— 聚合数据的可视化，横轴是采样次数占比，越宽越可能是瓶颈。本身零运行时开销，是对已有数据的后处理
5. **标记堆栈可信度** —— 即上面 Sentry 的思路，不增加额外采样开销

→ [原文：卡顿检测](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-检测.md)

### 74. 卡顿的常见原因和解决方案有哪些？🔥

#### 一、CPU 瓶颈

**1. 主线程阻塞** —— 耗时计算、文件 IO（`Data(contentsOf:)`）、数据库操作、同步网络请求。

- **任务异步化**：挪到后台线程，完成回主线程更新 UI。GCD 按 QoS 选队列（`userInitiated` 计算密集、`utility` IO、`background` 低优先级），或用 `async/await` + `TaskGroup`
- **任务拆分与调度**：必须在主线程做的（如大量 Cell 更新）切成小块，每批之后 `DispatchQueue.main.async` 让出主线程。高频操作（`scrollViewDidScroll`）用 CADisplayLink 节流，合并成每帧最多一次
- **去重与条件更新**：Debounce 合并短时间内多次请求（搜索框）；值没变就跳过；只更新屏幕上可见的视图

**2. 锁竞争** —— 后台线程持锁做耗时操作，主线程抢同一把锁就被阻塞。

- **读写锁**：`pthread_rwlock_t` 或 GCD 并发队列 + barrier，多读并发、写独占。**推荐 GCD barrier**，更简洁不易错
- **减小锁粒度**：一把大锁拆成多把细锁；简单计数器用 `os_unfair_lock`
- **串行队列替代锁**：用串行 `DispatchQueue` 保证线程安全，免去手动管锁

**3. 复杂布局计算** —— 约束多、`layoutSubviews` 频繁、层级深。

- **预计算与缓存**：后台线程预算文本高度、Cell 高度并缓存
- **手动 frame 替代 Auto Layout**：高频滚动的 Cell 里值得这么干
- **第三方库**：Texture（AsyncDisplayKit）的 Flexbox 布局在后台线程执行；IGListKit 的自动 Diff 只更新变化的 Cell

**4. 图片解码** —— PNG/JPEG 是压缩格式，GPU 要位图。默认 `UIImage` 加载时**不解码**，拖到 Commit Transaction 的 Prepare 阶段才在**主线程**解。一张 1000×1000 RGBA 解码后占 4MB。

- **异步解码**：后台线程建 `CGContext` 绘制强制解码；或 ImageIO 的 `kCGImageSourceShouldCacheImmediately`；或 `UIGraphicsImageRenderer`
- **降采样**：显示尺寸远小于原图时用 `CGImageSourceCreateThumbnailAtIndex` 按目标尺寸加载。**4000×4000 原本要 64MB，降到 100×100 只要 40KB**
- **多级缓存**：内存（`NSCache`，设 `countLimit` / `totalCostLimit` 并监听内存警告）→ 磁盘 → 网络
- **直接用成熟库**：SDWebImage / Kingfisher / Nuke 已经把上面全做了

**5. 文本渲染** —— 字体查找、字形排版、断行计算在 CPU 端开销大。

- `NSCache` 缓存算好的 `NSAttributedString`
- TextKit 在后台线程排版（`NSTextStorage` + `NSLayoutManager` + `NSTextContainer`），或用 YYText

#### 二、GPU 瓶颈

**1. 离屏渲染** —— GPU 没法一次性完成，得先渲到离屏缓冲区再合成。额外的缓冲区创建、上下文切换、合成，以及**对渲染流水线的打断**都是开销。

触发条件：`cornerRadius` + `masksToBounds`、无 `shadowPath` 的阴影、`layer.mask`、`allowsGroupOpacity`、`UIBlurEffect`。

| 问题 | 优化 |
| --- | --- |
| **圆角** | ① 只设 `cornerRadius` 不设 `masksToBounds`——圆角只作用于 backgroundColor 和 border，不裁剪 contents，**不触发离屏**（适合纯色背景控件）② 让 CDN 处理（如 OSS 的 `?x-oss-process=image/rounded-corners,r_20`），**零 GPU 开销** ③ 后台线程用 `UIBezierPath` + `UIGraphicsImageRenderer` 预裁圆角图 |
| **阴影** | ① 指定 `shadowPath` 明确告诉系统形状，免得系统遍历像素算轮廓（注意要在 `layoutSubviews` 里同步更新）② 用预制的 9-patch 阴影图 |
| **遮罩** | ① 后台用 Core Graphics 预渲染成已裁剪位图（不适合形状动态变化）② `draw(_:)` 里用 blend mode 实现，避开 `layer.mask` |
| **透明度** | ① 关掉 `allowsGroupOpacity` ② 把透明度应用到 `backgroundColor`（`UIColor.white.withAlphaComponent(0.5)`）而非视图的 `alpha` |
| **毛玻璃** | ① CDN 处理（`?x-oss-process=image/blur,r_50,s_50`）② 背景不变时用 `CIGaussianBlur` 预生成静态模糊图 ③ 先缩小截图再模糊再放大 ④ 控制 `UIVisualEffectView` 的大小和数量 |

**2. `shouldRasterize`** —— 这是**主动触发离屏渲染**的优化手段：把复杂图层渲成位图缓存，后续帧直接用。适合内容不常变的复杂视图（带阴影和圆角的卡片），本质是空间换时间。

⚠️ 两个坑：必须设 `rasterizationScale = UIScreen.main.scale` 否则 Retina 屏发虚；**内容频繁变化时缓存不断失效重建，反而更慢**。

#### 三、列表场景

| 手段 | 要点 |
| --- | --- |
| **Cell 复用** | `dequeueReusableCell(withIdentifier:for:)`；在 `prepareForReuse` 里重置状态并**取消进行中的异步任务**（如图片加载） |
| **高度缓存** | 预算并缓存到字典。或 `estimatedRowHeight` + `automaticDimension`，在 `willDisplay` 里缓存实际高度。**所有 Cell 等高时直接设固定 `rowHeight` 性能最好** |
| **异步渲染** | 后台用 `UIGraphicsImageRenderer` 把文本图形绘成位图，回主线程赋给 `layer.contents`。每次配置新 Item 时**取消上一次的渲染任务**，否则复用 Cell 会显示错乱 |
| **预加载** | `UITableViewDataSourcePrefetching` 的 `prefetchRowsAt` / `cancelPrefetchingForRowsAt` |
| **减少视图层级** | 多个子视图合并异步绘制到单个 CALayer，减轻 GPU 合成压力 |
| **Diff 更新** | `UITableViewDiffableDataSource` 或 IGListKit，只更新真正变化的 Cell，别 `reloadData` |
| **快速滚动优化** | 快滚时只显示占位，停下再渲染完整内容 |
| **分页加载** | 接近底部时异步加载下一页，用 `insertRows` 增量更新 |

→ [原文：卡顿原理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-原理.md) · [主线程优化](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-主线程优化.md) · [图片优化](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-图片优化.md) · [离屏渲染](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-离屏渲染.md) · [TableView 优化](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/卡顿/卡顿-TableView优化.md)

---

## 六、内存管理

### 75. iOS 有哪些内存区域和内存分类？🔥

这题要答**两个角度**，只答一个就少了一半。

**角度一：程序内存布局**

| 区域 | 存什么 | 谁管 |
| --- | --- | --- |
| 栈 Stack | 局部变量、函数参数、返回地址 | 系统自动，先进后出 |
| 堆 Heap | 动态分配的对象实例 | 引用计数 |
| 全局/静态区 BSS/Data | 全局变量、静态变量 | 程序启动时分配 |
| 常量区 Rodata | 字符串常量等只读数据 | — |
| 代码区 Text | 编译后的机器码 | — |

**角度二：系统内存管理（这个才是优化时真正关心的）**

| 类型 | 是什么 | 特点 |
| --- | --- | --- |
| **Clean Memory** | 可重新加载的：代码段、mmap 映射文件、未写入的内存页 | **可被系统随时回收** |
| **Dirty Memory** | 被写入过的：堆对象、解码后的图片、缓存数据 | **无法被系统自动回收** |
| **Compressed Memory** | 被压缩的 Dirty Memory | 访问时自动解压 |

```
Memory Footprint = Dirty Memory + Compressed Memory
```

这是 iOS 衡量 App 内存占用的**核心指标**。**Clean Memory 不计入 footprint**（系统随时能回收）。footprint 超限 App 就被杀。所以优化内存 = 减少 Dirty Memory。

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

### 76. Swift 和 Objective-C 在内存管理上有什么区别？

**内存分配**

| | Swift | Objective-C |
| --- | --- | --- |
| 值类型 | 大量用 struct/enum，**优先栈分配** | 几乎全是对象，全部堆分配 |
| 引用类型 | class 始终在堆 | 对象始终在堆 |
| 复制行为 | 值类型深拷贝，引用类型浅拷贝 | 对象浅拷贝，要显式 `copy` |

**值类型的逃逸**：值类型需要活过创建它的函数作用域时，编译器会把它分配到堆上——被逃逸闭包捕获、被存进堆上的属性、通过返回值逃逸。

**协议类型变量的隐式堆分配**：`let shape: Shape = Circle()` 会包进存在容器。容器内联缓冲区 24 字节，超过就堆分配。**这意味着即使是值类型，通过协议类型持有也可能产生堆分配开销**——这在 ObjC 里不存在（ObjC 的协议类型本质就是个 `id` 指针）。详见[第 40 题](#40-为什么协议类型作为函数参数比泛型约束慢底层区别是什么-)。

**COW**：Array / Dictionary / Set 实现了写时拷贝，赋值时共享底层存储，改的时候才真拷贝。[第 125 题](#125-swift-中-copy-on-write-的底层原理是什么-)有实测。

**ARC 实现差异**

| | Swift | Objective-C |
| --- | --- | --- |
| 引用计数存储 | 纯 Swift 类在**对象头部** | 非指针 isa 或 SideTable |
| ARC 优化 | 更激进（栈提升、RC 消除） | 较保守 |
| 逃逸分析 | 编译器自动做，可把堆分配优化成栈分配 | 不支持 |

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md) · [值类型和引用类型的区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/值类型和引用类型的区别.md)

### 77. 什么是引用计数？它是如何工作的？🔥

每个对象维护一个计数器：新强引用 +1，强引用移除 -1，归零就销毁释放。

**ObjC 对象是两级存储**：

1. **isa 内嵌（小引用计数）** —— Non-Pointer isa 模式下 `extra_rc` 字段直接存「引用计数 - 1」。arm64 下 19 位，最多表示 524288
2. **侧表（大引用计数）** —— `extra_rc` 溢出时 `has_sidetable_rc` 置 1，计数转存到 `SideTable` 的 `RefcountMap` 哈希表。传统指针 isa（32 位）也走侧表

**纯 Swift 类**的引用计数直接在对象头部的 RefCount 字段，不用 SideTable，访问更快。

> ✅ **实测**（[objc-weak-and-arc.m](ios-snippets/objc-weak-and-arc.m) / [swift-memory-arc.swift](ios-snippets/swift-memory-arc.swift)）
>
> ```
>   刚创建                 rc=2
>   多一个强引用            rc=3
>   再加一个 weak           rc=3  <- weak 不增加引用计数
> ```
>
> ⚠️ **注意这里的绝对值**。常见说法是「刚 alloc 出来 retainCount 是 1」，但实测是 **2** —— 因为 ARC 为那个强引用的局部变量也插了一次 retain（`-O0` 下不会被优化掉）。
>
> **`CFGetRetainCount` 的绝对值受编译器插入的临时 retain 影响，只有相对变化才有意义。** 面试时说「加一个强引用 +1、加 weak 不变」是对的；说死「新对象就是 1」就容易被追问翻车。

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

### 78. weak 和 assign 有什么区别？什么时候用 weak？🔥

| | `weak` | `assign` / `unsafe_unretained` |
| --- | --- | --- |
| 对象释放后 | **自动置 nil** | 不置 nil，**变野指针** |
| 安全性 | 安全，给 nil 发消息不崩 | 不安全，可能 `EXC_BAD_ACCESS` |
| 性能 | 稍高（要维护弱引用表） | 更低 |
| 适用 | 对象类型 | 基本数据类型，或明确知道自己在干什么的特殊场景 |

**用 weak 的场景**：delegate（避免循环引用）、IBOutlet（已被父视图强引用）、Block 里引用 self 时配合 strong-weak dance。

> ✅ **实测**（[objc-weak-and-arc.m](ios-snippets/objc-weak-and-arc.m)）两者的差别在出作用域那一刻立刻显形：
>
> ```
> == weak 在对象销毁后自动置 nil ==
>   出作用域前 weakRef = B
>     [dealloc] B
>   出作用域后 weakRef = nil  <- runtime 在 dealloc 时清空了 weak 表
>
> == assign（unsafe_unretained）不会置 nil，变成野指针 ==
>     [dealloc] C
>   出作用域后 unsafeRef 指针 = 0x102f352c0（非 nil，已指向已释放内存）
> ```
>
> 注意 `unsafeRef` 打印出来是个**看起来很正常的地址**——这正是野指针危险的地方，判空判不出来。

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

### 79. 什么是循环引用？如何解决？🔥

两个或多个对象**相互强引用**，引用计数永远归不了零 → 内存泄漏。

**四个常见场景**：

1. 两个对象互相持有
2. Block 捕获 self，而 self 又持有 Block
3. delegate 用了 `strong`
4. `NSTimer` 强引用 target，target 又持有 timer

**解法**：`weak`/`unowned` 打破循环；Block 里用 `__weak`/`[weak self]`；适当时机手动断开（如 `viewDidDisappear` 里 `invalidate` timer）。

> ✅ **实测**（[swift-memory-arc.swift](ios-snippets/swift-memory-arc.swift)）泄漏和修复的对比非常直观：
>
> ```
> == 循环引用：两个 strong 互指，谁都释放不掉 ==
>   构造完毕，即将离开作用域（下面应该没有任何 deinit）
>   离开了——两个对象都泄漏了          ← 一行 deinit 都没有
>
> == 用 weak 打破循环 ==
>   构造完毕，即将离开作用域
>     - deinit Parent2
>     - deinit Child2                  ← 两个都正常销毁了
>   离开了
> ```

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

### 80. weak 的实现原理是什么？🔥

**SideTable + weak_table + weak_entry** 三层结构。

**数据结构**：系统维护一个固定大小的 `SideTable` 数组（`StripedMap`），对象地址哈希取模定位到其中一个。对象数量远大于 SideTable 数量，所以多个对象会映射到同一个——**这样设计的核心目的是分散锁竞争**，每个 SideTable 有独立的 `os_unfair_lock`，不同 SideTable 上的操作可以并行。

每个 SideTable 内含一个 `weak_table_t`：以对象地址为 key 的**开放寻址哈希表**（线性探测，用 `mask` 快速取模，用 `max_hash_displacement` 限制探测范围）。表里每个 `weak_entry_t` 对应一个被弱引用的对象，记录指向它的所有弱引用**指针地址**（≤4 个时内联存储，超过就切换成动态哈希表）。

**三个操作：**

| 操作 | 链路 |
| --- | --- |
| **创建** `__weak id p = obj` | → `objc_initWeak(&p, obj)` → `storeWeak` → 哈希定位 SideTable 并加锁 → `weak_register_no_lock` 查找或创建 entry → 把 `&p` 加进 referrers → 设置 isa 的 `weakly_referenced` 标志位 |
| **读取** `id o = p` | → `objc_loadWeakRetained(&p)` → **无锁 do-while 重试**读指针并尝试 `rootTryRetain()`，成功返回对象（调用方稍后 release），失败且 `*location` 已置 nil 则返回 nil |
| **清理** | `dealloc` → `rootDealloc` → 慢速路径 → `clearDeallocating_slow` → `weak_clear_no_lock` 遍历所有弱引用指针执行 `*referrer = nil` |

→ [原文：weak 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/weak详解.md)

### 81. Block 中直接用 weakSelf 和转成 strongSelf 有什么区别？🔥

```objc
// 写法 A
__weak typeof(self) weakSelf = self;
view.action = ^{ [weakSelf action]; };

// 写法 B
__weak typeof(self) weakSelf = self;
view.action = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf action];
};
```

**两者都能避免循环引用**，区别不在这儿。区别是：**A 是每次使用时读一次弱引用；B 是先取出来强持有，在作用域内复用这个稳定对象。**

底层上 `[weakSelf action]` 并不是直接对裸指针发消息，ARC 会转换成：

```objc
id tmp = objc_loadWeakRetained(&weakSelf);
objc_msgSend(tmp, @selector(action));
objc_release(tmp);
```

`objc_loadWeakRetained` 读出对象并尝试 retain，成功才返回——**保证这一次消息发送期间对象不会被释放**。对象已在释放或 weak 已清零就返回 `nil`。

**所以：如果 Block 里只访问一次，两种写法底层差异很小。** 差异出现在多次访问时：

```objc
[weakSelf step1];   // objc_loadWeakRetained + msgSend + release
[weakSelf step2];   // 又来一遍
[weakSelf step3];   // 再来一遍
```

三次弱引用读取。而 strongSelf 写法**只读一次**：

```objc
id strongSelf = objc_loadWeakRetained(&weakSelf);
objc_msgSend(strongSelf, @selector(step1));
objc_msgSend(strongSelf, @selector(step2));
objc_msgSend(strongSelf, @selector(step3));
objc_release(strongSelf);                      // 作用域结束时 ARC 插入
```

**两个收益**：省掉重复的弱引用读取开销；更重要的是**保证三步之间对象不会中途被释放**——用 A 写法时 `step1` 执行完、`step2` 还没开始的间隙里对象可能已经没了，后两步就静默变成了给 nil 发消息。

> ✅ **实测**（[objc-weak-and-arc.m](ios-snippets/objc-weak-and-arc.m)）
>
> ```
>     只用 weakSelf：进入 block 时 还活着
>     strongSelf 提升成功，rc=3 —— 在 block 执行期间对象不会被释放
>   对象已释放后再调用：
>     strongSelf = nil（这就是提升的意义：判空后安全返回）
> ```
>
> 提升后 `rc` 确实涨了，证明它真的是**强**引用。所以标准写法一定要配判空：
>
> ```objc
> __strong typeof(weakSelf) strongSelf = weakSelf;
> if (!strongSelf) return;      // ← 这句不能少
> ```

→ [原文：weak 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/weak详解.md)

### 82. weak 变量在对象释放后为什么能自动变成 nil？

靠对象析构时 runtime 的**主动清理**：

```
-[NSObject dealloc]
  → _objc_rootDealloc → rootDealloc()
    ├── 快速路径：isa 标志位全 false（无弱引用/关联对象/SideTable 引用计数）→ 直接 free
    └── 慢速路径：object_dispose → objc_destructInstance
          → clearDeallocating() → clearDeallocating_slow()
                ├── weak_clear_no_lock()   // 清弱引用
                └── refcnts.erase()        // 清 SideTable 引用计数
```

关键在 `rootDealloc()` 的**快速路径判断**：检查 isa 里的 `weakly_referenced` 标志位，**只有为 true 才走慢速路径**。没被弱引用过的对象直接 free，省掉整套查表开销。

`weak_clear_no_lock` 做四件事：

1. 以对象地址为 key 在 `weak_table` 哈希查 `weak_entry`
2. 按 entry 的 `out_of_line_ness` 标志判断用内联数组还是动态数组
3. 遍历所有弱引用指针地址，**校验 `*referrer == referent` 后**才执行 `*referrer = nil`
4. 从 `weak_table` 移除 entry

整个过程在 SideTable 锁保护下进行，保证与其他线程的 `storeWeak`、`objc_loadWeakRetained` 线程安全。

→ [原文：weak 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/weak详解.md)

### 83. weak 和 unowned 的区别是什么？分别适用于什么场景？🔥

两者都**不增加引用计数**，区别在对象释放之后：

| | `weak` | `unowned` |
| --- | --- | --- |
| 对象释放后 | 自动置 nil | **不置 nil** |
| 类型 | 必须是 Optional | 非 Optional |
| 访问已释放对象 | 得到 nil，安全 | **确定性崩溃**（不是野指针） |
| 开销 | 有注册/清理开销 | 更低 |
| 适用 | 对象可能随时被释放（delegate） | **确定被引用对象的生命周期 ≥ 自己** |

`unowned` 默认是 `unowned(safe)`：它依赖 Swift 对象头里的 **unowned 引用计数**实现「僵尸状态」检测，所以访问已释放对象时是一个明确的 fatal error，而不是读到随机内存。报错长这样：

```
Fatal error: Attempted to read an unowned reference but object 0x… was already deallocated
```

> ✅ **实测**（[swift-memory-arc.swift](ios-snippets/swift-memory-arc.swift)）
>
> ```
>   对象存活时：weak = 非 nil
>     - deinit Owner
>   对象销毁后：weak = nil（自动置空，安全）
> ```
>
> `unowned` 那一半没有实跑——跑了进程就直接 fatal error 终止了，所以代码里只保留了说明。这本身也说明了问题：**`unowned` 猜错了就是崩，没有中间地带。**

→ [原文：weak 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/weak详解.md)

### 84. 纯 Swift 类的 weak 实现和 OC 有什么不同？

三处显著差异。

**① 对象布局** —— OC 对象以 `isa` 开头，引用计数溢出才进 SideTable；纯 Swift 类以 `HeapObject` 为基础，含 `metadata`（等效 isa）+ `InlineRefCounts`（8 字节，内联编码 strong/unowned 计数）。

**② 弱引用存储路径**

- **OC**：对象地址 → `StripedMap` 哈希 → `SideTable` → `weak_table` → `weak_entry`。**weak 指针直接指向对象**
- **Swift**：首次创建 weak 引用时，Runtime 分配 `HeapObjectSideTableEntry`（含完整引用计数和对象指针），把对象的 `InlineRefCounts` 替换成指向该 entry 的指针。**weak 变量存的是 entry 指针而非对象指针**，读取时需通过 entry 间接取对象

  > 这就是[第 37 题](#37-纯-swift-类和继承自-nsobject-的-swift-类在底层有什么区别)说的「bit 63 置 1 后切换不可逆」。

**③ 置 nil 时机**

- **OC**：`dealloc` 时**同步**遍历 `weak_entry` 把所有弱引用置 nil
- **Swift**：**延迟置 nil** —— dealloc 时不主动清理，而是在**下一次读取 weak 变量时**检查 strong count 是否为 0，已释放才返回 nil

**native vs non-native**：编译器在**编译期**按继承关系决定走哪条路——纯 Swift 类走 `HeapObject` 路径；继承自 `NSObject` 或 OC 类的 Swift 类**退回 OC 的 SideTable + weak_table 路径**，行为与 OC weak 完全一致。

→ [原文：weak 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/weak详解.md)

### 85. 详细介绍 Autorelease Pool 的工作机制和底层实现🔥

一种**延迟释放机制**：对象被标记 autorelease 后不立即释放，而是注册到当前 pool，等池销毁时统一 `release`。

| | 立即释放 | 延迟释放 |
| --- | --- | --- |
| 怎么创建 | `alloc/init`、`new`、`copy` | 便利构造方法如 `stringWithFormat:` |
| 何时释放 | 引用计数归零就 dealloc | pool 销毁时 |
| 依赖 RunLoop | 否 | 主线程依赖 |

⚠️ 现代 ARC 有 **autorelease elision** 优化，进一步减少了 autorelease 对象数量，所以**实际上大部分对象都是立即释放的**。

#### AutoreleasePoolPage

- 每个 page **4096 字节**（一个虚拟内存页），约存 **505 个**对象指针
- 多个 page 通过 `parent`/`child` 形成**双向链表**
- page 内部是**栈**，`next` 指针指向栈顶
- **每个线程有独立的 pool**（通过 TLS 存 hotPage）

#### POOL_BOUNDARY（哨兵）

值为 `nil` 的特殊标记。进 `@autoreleasepool {` 时 push 一个，出 `}` 时从栈顶逐个 `release` 直到遇见**对应的**那个哨兵。**这个设计就是为了支持嵌套**：

```objc
@autoreleasepool {          // push POOL_BOUNDARY_1
    NSString *a = ...;      // push a
    @autoreleasepool {      // push POOL_BOUNDARY_2
        NSString *b = ...;  // push b
    }                       // pop 到 BOUNDARY_2，释放 b
}                           // pop 到 BOUNDARY_1，释放 a
```

#### autorelease 的流程

1. 对象调 `autorelease` → 实际执行 `objc_autorelease()`
2. 通过 TLS 拿当前线程的 `hotPage`
3. 添加：**快速路径** page 有空间就存进 `next` 位置并 `next++`；**慢速路径** page 满了就创建新 page 作为 child
4. 作用域结束调 `objc_autoreleasePoolPop()`，逐个 release 到哨兵为止

#### 主线程的 pool 由 RunLoop 自动管理

| RunLoop 状态 | 动作 |
| --- | --- |
| `kCFRunLoopEntry` | 创建 pool |
| `kCFRunLoopBeforeWaiting` | **释放旧池、创建新池** ← autorelease 对象在此释放 |
| `kCFRunLoopExit` | 释放 pool |

这和[第 15 题](#15-runloop-的运作流程是怎样的-)说的「BeforeWaiting 时系统做三件事」的第三件是同一回事。

> ✅ **实测**（[objc-weak-and-arc.m](ios-snippets/objc-weak-and-arc.m)）嵌套 pool 的释放时机：
>
> ```
>   进入外层 pool
>   内层 pool 中，对象存活 rc=3
>     [dealloc] E
>   内层 pool 结束后 wp = nil（已随 pool drain 释放）
>   外层 pool 结束
> ```
>
> `dealloc` 精确发生在内层 `}` 处，不是等到外层——哨兵机制生效。

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

### 86. 收到内存警告时应该注意什么？

这题的考点是一个**反直觉的陷阱**：别「先解压再释放」。

iOS 的内存压缩机制会把长时间未访问的 Dirty Memory 压缩。如果你在 `didReceiveMemoryWarning` 里遍历并释放这些**已压缩**的数据，系统**必须先解压才能释放**。于是清理操作会先**临时增加**内存占用（解压后比压缩时更大），然后才降下来——**可能适得其反地加剧内存压力**，同时 CPU 飙升造成卡顿。

**推荐用 `NSCache`**：它内部实现了对内存压力的智能响应，系统紧张时自动清理，且**优先清理未压缩的、访问频率低的数据**，避开了上面这个坑。

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

### 87. 如何检测和定位内存泄漏？

**工具**

| 工具 | 用途 |
| --- | --- |
| Instruments - **Leaks** | 检测循环引用导致的泄漏 |
| Instruments - **Allocations** | 分析分配情况，找内存增长点 |
| **Memory Graph Debugger** | Xcode 内置，可视化看对象引用关系 |
| **MLeaksFinder** | 第三方，运行时自动检测 UIViewController 泄漏 |

**排查顺序**

1. Memory Graph 看引用关系，找环
2. 检查 delegate 是不是 `weak`
3. 检查 Block 里 self 处理对不对
4. 检查 Timer、NotificationCenter 有没有正确移除
5. Allocations 追踪内存增长

> 💡 补充一个本地就能用的土办法：给关键类加 `deinit`/`dealloc` 打印。[swift-memory-arc.swift](ios-snippets/swift-memory-arc.swift) 就是靠这个把循环引用演示出来的——**该打印的 deinit 没出现，就是泄漏了**。不用开 Instruments，跑一遍就知道。

→ [原文：iOS 中的内存管理](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的内存管理.md)

---

## 七、多线程与并发

### 88. 死锁的条件是什么？如何破坏？🔥

**Coffman 四个必要条件**——注意是「必要」，破坏任意一个就不会死锁：

| 条件 | 怎么破 |
| --- | --- |
| **互斥** | 读写锁、无锁结构、值类型 |
| **持有并等待** | 一次性申请所有资源，或 `tryLock` + 回退 |
| **不可抢占** | 加锁超时、可取消任务 |
| **循环等待** | **全局统一加锁顺序**（最常用，比如按对象地址排序） |

实践中**破「循环等待」是性价比最高的**——定一个全局顺序，所有代码按同一顺序加锁、反向释放，成本低且不影响性能。

→ [原文：死锁](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/死锁/死锁.md)

### 89. `DispatchQueue.main.sync` 为什么会死锁？什么时候不会？🔥

`sync` 的语义是：**把 block 排到队列尾部，然后阻塞当前线程等它完成。**

主队列是**串行**的。如果调用方当前就在主线程：主线程卡在 `sync` 上等 block 完成 → 主队列要等当前任务（就是正卡着的这个）结束才能调度那个 block → 循环等待。

**不死锁的情况**：在**子线程**调用 `main.sync`。此时当前线程不是主队列的执行线程，阻塞它不影响主队列继续调度。

> ✅ **实测**（[swift-concurrency.swift](ios-snippets/swift-concurrency.swift)）并发队列嵌套 `sync` **不会**死锁，因为并发队列不要求串行执行，能另开线程：
>
> ```
>   并发队列嵌套 sync：跑通了，没死锁
>   从外部线程 sync 进串行队列：正常
> ```
>
> 对照着记：**死锁的充分条件是「串行队列 + 在它自己的执行线程上 sync 它自己」**，三个条件缺一不可。

→ [原文：死锁](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/死锁/死锁.md)

### 90. iOS 中死锁的常见场景有哪些？🔥

十个，前四个是高频考点。

**① GCD 串行队列对自身 `sync`** —— 最经典。

```swift
DispatchQueue.main.sync { updateUI() }        // 主线程调用 → 死锁

let queue = DispatchQueue(label: "cache")
queue.async {
    queue.sync { saveCache() }                // 同一串行队列 sync 自己 → 死锁
}
```

**② 锁的循环等待** —— 最标准的死锁模型，同时满足「持有并等待」和「循环等待」。

```swift
DispatchQueue.global().async { lockA.lock(); lockB.lock() }   // 等 B
DispatchQueue.global().async { lockB.lock(); lockA.lock() }   // 等 A
```

**③ 非递归锁的同线程重入** —— `NSLock`、默认 `pthread_mutex_t`、`os_unfair_lock` **都不是递归锁**。

```swift
func update() {
    lock.lock(); defer { lock.unlock() }
    reload()          // reload 内部再次 lock → 同线程重入 → 死锁
}
```

修法：把公共逻辑抽到**不加锁的 private 方法**；确实需要递归语义时才用 `NSRecursiveLock`。

**④ 用 `DispatchSemaphore.wait()` 把异步接口同步化** —— 常见于包装网络请求、Core Bluetooth、`evaluateJavaScript`、delegate 回调。

```swift
func syncFetch() -> Data? {
    let sem = DispatchSemaphore(value: 0)
    asyncFetch { data in
        DispatchQueue.main.async { result = data; sem.signal() }
    }
    sem.wait()        // 在主线程调用时，main.async 根本没机会执行 → 永远等不到
    return result
}
```

现代 Swift 应该用 `async/await` 或 `withCheckedContinuation` 桥接，而不是这样。

**⑤ FMDB / Core Data 嵌套队列** —— `inDatabase:` / `inTransaction:` / `performAndWait:` 本质都依赖串行队列同步执行，嵌套就等价于场景 ①。

```swift
context.performAndWait {
    updateObject()
    context.performAndWait { saveObject() }   // 同一个 context 嵌套 → 死锁
}
```

**⑥ 持锁时调用外部回调/发通知/派发同步任务** —— 锁内执行用户闭包、通知回调、delegate、KVO 这类**不可控代码**非常危险：外部代码可能反向调用当前对象，也可能申请另一把锁。

正确做法：**锁内只读写共享状态、生成快照，锁外再执行回调。**

**⑦ `+initialize` / `+load` 里的跨类依赖** —— runtime 执行 `+initialize` 时有内部锁保护。A 初始化触发 B，B 初始化又反向依赖 A，多线程同时触发就可能死锁。初始化逻辑应该只初始化自己。

**⑧ 主线程等后台线程持有的锁，最终被 watchdog 杀掉** —— 未必是经典 Coffman 死锁，但用户感知一样：主线程卡在 `os_unfair_lock_lock` / `pthread_mutex_lock` / `semaphore_wait`，后台持锁跑长任务，界面长时间无响应。

**⑨ signal handler 里再次申请锁** —— 崩溃采集路径如果调用 `malloc`、`NSLog`、ObjC runtime、dyld 这些**非 async-signal-safe** 的 API，可能在原线程已持锁时再次申请同一把锁，导致**采集链路自己死锁**。详见[第 169 题](#169-signal-handler-为什么要求异步信号安全哪些操作不能在里面做-)。

**⑩ Swift Concurrency 误用** —— actor 的可重入设计能减少传统死锁，但不等于不会卡死：

```swift
@MainActor func loadSync() {
    let sem = DispatchSemaphore(value: 0)
    Task { @MainActor in updateUI(); sem.signal() }
    sem.wait()    // MainActor 被阻塞，Task 永远排不上 → 死锁
}
```

**一句话总结这十条：绝大多数都是「同步等待一个需要当前线程/队列才能完成的事」。**

→ [原文：死锁](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/死锁/死锁.md)

### 91. 死锁如何治理？

治理不是写几条编码规范，而是**事前 / 事中 / 事后**的闭环。

#### 事前：预防与准入

1. **选更安全的并发模型** —— 新 Swift 代码优先 `actor` / async-await / `@MainActor` / 值类型 / 串行队列封装。**锁越少，循环等待的机会越少**
2. **统一加锁顺序** —— 可能同时拿多把锁时定义全局顺序（按模块层级、资源 id、对象地址），所有代码同序加锁、反向释放
3. **缩短临界区** —— 临界区只做共享状态读写，不做 IO、网络、大事务、图片解码、复杂计算，更不在持锁时等另一把锁/队列/信号量
4. **锁内不调用外部代码** —— 锁内复制快照，锁外回调
5. **避免同步等待异步结果** —— 要桥接旧接口就用 `withCheckedContinuation`，让调用方 `await` 挂起而非阻塞线程
6. **团队红线 + Code Review 清单** —— 禁止主线程 `semaphore.wait()`、禁止串行队列 sync 自身、禁止 `performAndWait` 嵌套、禁止持锁发通知、禁止 `+initialize` 跨类依赖。落地靠 SwiftLint、pre-commit、TSan CI、Swift 严格并发检查

#### 事中：检测与现场保留

1. **主线程卡死监控** —— RunLoop observer / 主线程 ping / MetricKit / Sentry App Hangs。卡死时抓**全线程**堆栈、线程状态、队列 label、CPU 使用、关键寄存器
2. **等待必须有超时和失败路径** —— 能用 `tryLock` 就别无限等。超时不是为了吞问题，是为了避免主线程永久阻塞，同时记录锁等待耗时、线程 id、队列 label、业务上下文
3. **主线程路径特殊保护** —— 同步封装先判断是否已在主线程；UI 状态用 `@MainActor` 约束
4. **高风险封装加断言和埋点** —— Debug 下断言「不能从同一队列同步进入」；线上控制采样
5. **监控链路自身要安全** —— 见上面场景 ⑨

#### 事后：归因与防劣化

1. **先区分死锁 / 死循环 / 单纯耗时** —— 这是最关键的第一步：

   | 现象 | CPU | 线程状态 | 栈顶特征 |
   | --- | --- | --- | --- |
   | **死锁** | 接近 0 | WAITING / BLOCKED | `__psynch_mutexwait`、`semaphore_wait_trap`、`dispatch_sync_wait`、`os_unfair_lock_lock` |
   | **死循环** | 高 | running | 业务代码循环 |
   | **单纯耗时** | 中高 | running | IO、计算、主线程大任务 |

2. **全线程堆栈聚合 + 死锁图** —— 只看主线程不够，要找到「主线程在等谁、那个线程又在等谁」。拿得到锁 owner 时可以建「线程等待锁、锁被线程持有」的有向图判环
3. **按根因修复并补测试** —— 别只加个超时了事。统一锁顺序、拆掉同步等待、缩短临界区、把锁内回调挪出去。能复现的要补并发压力测试或 TSan 测试任务
4. **灰度验证** —— 看卡死率、watchdog 崩溃率、App Hang 数量的**趋势**，死锁类问题依赖时序，低频但影响严重
5. **复盘回灌准入体系** —— 变成 SwiftLint 规则、CI 的 TSan Job、Review checklist，并在基础库里提供安全封装，减少业务层直接碰锁

→ [原文：死锁](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/死锁/死锁.md)

### 92. OSSpinLock 为什么被废弃？什么是优先级反转？🔥

**自旋锁**等待时不让线程休眠，而是**忙等**（busy-wait）不断检查锁是否可用。好处是没有线程切换开销，临界区极短时快；坏处是等待期间**持续占 CPU**。

`OSSpinLock` 被废弃，是因为在 iOS 的优先级调度下会触发**优先级反转**：

```
1. 低优先级线程拿到自旋锁，开始执行临界区
2. 高优先级线程要同一把锁，开始自旋等待（忙等，霸占 CPU）
3. 中优先级线程抢占了低优先级线程的 CPU（中 > 低）
   → 低优先级线程分不到时间片，锁一直释放不掉
4. 结果：高优先级空转烧 CPU，低优先级饿死，形成活锁
```

**关键点在于**：自旋锁的忙等让高优先级线程一直「正在运行」，调度器因此不会去调度低优先级线程，那把锁就永远释放不了。

**替代方案**

| 方案 | 为什么安全 |
| --- | --- |
| **`os_unfair_lock`**（推荐） | 等待时线程被内核挂起而非忙等，且系统做优先级继承 |
| `pthread_mutex` | 支持**优先级继承**——高优先级线程等锁时，系统临时提升持锁低优先级线程的优先级，让它赶紧跑完释放 |
| `NSLock` | 底层就是 `pthread_mutex`，同样有优先级继承 |
| Actor | Swift Concurrency 运行时自动处理优先级 |

→ [原文：多线程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/多线程.md)

### 93. 如何实现读写锁？

核心需求：**多个线程可同时读，写必须独占。**

最常用的实现是**并发队列 + barrier**：

```swift
final class ReadWriteStore {
    private let queue = DispatchQueue(label: "com.example.rwlock", attributes: .concurrent)
    private var _data: Any?

    func readData() -> Any? {
        queue.sync { _data }                    // 多个读可并发
    }

    func writeData(_ data: Any?) {
        queue.async(flags: .barrier) {          // barrier 独占执行
            self._data = data
        }
    }
}
```

- 读用 `sync` 提交到并发队列 → 多个读并发跑
- 写用 `async(flags: .barrier)` → barrier 等前面所有任务跑完后**独占执行**，完成后后续任务才继续

另一个选择是 `pthread_rwlock_t`，但 GCD barrier 方式代码更简洁、不容易写错，**推荐优先用它**。

→ [原文：多线程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/多线程.md)

### 94. 不同队列和执行方式的组合会怎样？🔥

这张表要能默写出来：

| | 串行队列 | 并发队列 | 主队列 |
| --- | --- | --- | --- |
| **sync** | 不开新线程，串行执行 | 不开新线程，**串行执行** | **在主线程调用会死锁** |
| **async** | 开 **1** 条新线程，串行执行 | 开**多**条新线程，并发执行 | 不开新线程，串行执行 |

逐条说明：

- **串行 + sync** —— 任务在**当前线程**执行（`sync` 从不开新线程），一个跑完才下一个
- **串行 + async** —— 开一条新线程，任务在该线程按序执行。**只开一条**，因为串行队列同一时间只执行一个任务
- **并发 + sync** —— 任务在**当前线程**执行。虽然是并发队列，但 `sync` 会阻塞等待，效果**等同串行**。这是最容易答错的一格
- **并发 + async** —— 开多条线程并发执行，最常用的并发场景
- **主队列 + sync** —— 主线程调用会死锁；**子线程调用不会**，任务在主线程执行
- **主队列 + async** —— 任务在主线程串行执行，回主线程刷 UI 就用它

**一句话记忆：`sync` 永远不开新线程；开不开新线程、开几条，只由队列类型和 `async` 决定。**

→ [原文：多线程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/多线程.md)

### 95. 如何保证线程安全？🔥

| 方案 | 适用场景 | 例子 |
| --- | --- | --- |
| **锁**（`NSLock` / `pthread_mutex` / `os_unfair_lock`） | 保护临界区，短暂的共享数据访问 | 属性读写、计数器递增 |
| **`@synchronized`** | 性能要求不高的简单场景 | 单例初始化（OC）、简单临界区 |
| **`dispatch_semaphore`** | 控制**最大并发数**、资源池 | 限制同时下载数、连接池 |
| **串行队列** | 把所有对共享资源的操作集中到一个队列 | 日志写入、数据库操作 |
| **并发队列 + barrier** | **多读单写** | 缓存读写、配置管理 |
| **`atomic` 属性** | 仅保护单个属性的 getter/setter | 简单标志位 |
| **Actor**（Swift 5.5+） | Swift 里的推荐方案，**编译器保证** | ViewModel 状态、共享数据存储 |

⚠️ **`atomic` 的陷阱**：它只保证单次 getter/setter 原子，**复合操作仍然不安全**。`self.count += 1` 是「读-改-写」三步，`atomic` 救不了。

> ✅ **实测**（[swift-concurrency.swift](ios-snippets/swift-concurrency.swift)）这个坑有多大，看数字：
>
> ```
> == 没有保护的共享可变状态 = 数据竞争 ==
>   期望 100000，实际 72525
>   丢失了 27475 次自增
>
> == 加锁修好 ==
>   期望 100000，实际 100000
>
> == actor ==
>   actor 计数：期望 1000，实际 1000
> ```
>
> 10 万次并发自增**丢了 27475 次**，超过四分之一。`value += 1` 看着像一步，实际是读-改-写三步，随时可能被打断。

→ [原文：多线程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/多线程.md)

### 96. Actor 的优势是什么？结构化并发解决了什么问题？🔥

#### Actor 的优势

传统多线程要开发者手动选锁、管加锁解锁时机，漏一处就是数据竞争，而且这类 bug **难复现难调试**（见上题：同样的代码每次跑丢的数量都不一样）。Actor 从语言层面解决：

- **编译时安全** —— 从 actor 外部访问可变状态必须 `await`，忘了**编译器直接报错**，而不是等运行时崩
- **无需手动加锁** —— 内部状态自动隔离，消除「忘记解锁」「死锁」这类人为错误
- **消除数据竞争** —— Swift 6 严格并发检查 + Actor + `Sendable` 三者配合，可在**编译期**消除 Data Race
- **抽象层次更高** —— 锁保护的是「代码段」，你得记住哪些代码要加锁；**Actor 保护的是「数据」**，只要数据在 actor 内就自动安全
- **可组合性好** —— actor 之间通过 `await` 交互，得益于可重入设计，不会有传统锁的嵌套死锁问题

#### 结构化并发解决了什么

GCD 时代 `dispatch_async` 派发出去的任务**与创建它的上下文完全脱钩**，带来四个问题：

| 问题 | 具体表现 |
| --- | --- |
| **任务泄漏** | 派发出去的任务没有所有者，无法确保它一定完成或被取消 |
| **取消困难** | 要手动持有 `DispatchWorkItem` 再 `cancel()`，而且**子任务不会自动取消** |
| **错误处理分散** | 每个闭包回调各自处理错误，无法自动向上传播 |
| **生命周期不可控** | 闭包捕获了 `self`，异步任务的生命周期可能超出预期 |

结构化并发（`async let`、`TaskGroup`）把**任务生命周期绑定到作用域**来解决——作用域结束时所有子任务必然已完成或已取消。

> ✅ **实测**（[swift-concurrency.swift](ios-snippets/swift-concurrency.swift)）
>
> 并行效果，三个各 100ms 的任务：
>
> ```
>   串行 await（累加耗时）：    结果 1 2 3，耗时 313 ms
>   async let（并行，取最长）：  结果 1 2 3，耗时 103 ms
> ```
>
> 取消自动沿结构向下传播：
>
> ```
>   任务取消会沿结构向下传播：
>     子任务感知到取消并退出
> ```
>
> 父 Task 一 `cancel()`，TaskGroup 里正在 `Task.sleep` 的子任务立刻抛出并退出——**这正是 GCD 做不到的那件事**。

→ [原文：多线程](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/多线程.md)

---

## 八、运行时机制

### 97. `objc_msgSend` 的执行流程？🔥

1. 检查 receiver 是否为 **nil** → 是就直接返回（这就是「给 nil 发消息不崩」的原因）
2. 通过 **isa** 找到 receiver 的类对象
3. 在类对象的**方法缓存 `cache_t`** 里查
4. 缓存命中 → 直接调用 IMP
5. 缓存未命中 → 在类对象的**方法列表**里查
6. 找到 → **缓存起来**再调用
7. 没找到 → 沿 **`superclass` 链**向上查，每一级重复 3–6
8. 一路到根类仍没找到 → 进入**消息转发**

关键设计是第 3、6 步的 `cache_t`：方法查找是每次调用都发生的高频操作，缓存把大部分调用压到一次哈希查找。

> ✅ 第 1 步「nil 直接返回」实测（[objc-value-semantics.m](ios-snippets/objc-value-semantics.m)）：
>
> ```
>   [nil length]        = 0（返回 0）
>   [nil description]   = nil
> ```

→ [原文：runtime](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runtime.md)

### 98. 消息转发的三个阶段？🔥

| 阶段 | 方法 | 能力 | 开销 |
| --- | --- | --- | --- |
| **① 动态方法解析** | `+resolveInstanceMethod:` / `+resolveClassMethod:` | 用 `class_addMethod` 动态加实现。返回 YES 且加成功，runtime **重新发送消息** | 小 |
| **② 快速转发** | `-forwardingTargetForSelector:` | 返回一个备用对象接收该消息，runtime 直接对它 `objc_msgSend`。**不创建 `NSInvocation`，效率高**。但改不了参数/返回值，也没法转给多个对象 | 中 |
| **③ 完整转发** | `-methodSignatureForSelector:` + `-forwardInvocation:` | 拿到封装了完整调用信息的 `NSInvocation`，可以改参数、换 target、转发给多个对象、存下来以后再用 | 大 |

三个阶段都不处理 → `doesNotRecognizeSelector:` → 抛 `unrecognized selector` 异常。

⚠️ 第三阶段里 `methodSignatureForSelector:` **返回 nil 会直接崩溃**，不会走到 `forwardInvocation:`。

> ✅ **实测**（[objc-msgsend-forwarding.m](ios-snippets/objc-msgsend-forwarding.m)）三个阶段逐个跑通：
>
> ```
> == 阶段一：动态方法解析 ==
>   [阶段一 resolveInstanceMethod: 动态加方法]
>     -> 运行时加进来的 IMP 执行了，sel=notImplemented
>
> == 阶段二：快速转发 ==
>   [阶段二 forwardingTargetForSelector: 转给 Helper]
>     -> Helper 代收了 sayHi
>
> == 阶段三：完整转发 ==
>   [阶段三 methodSignatureForSelector: 给出签名]
>   [阶段三 forwardInvocation: 拿到 NSInvocation，可读改参数与返回值]
>     -> 截获参数 a=3 b=4，手动写回返回值 7
>     调用方拿到的返回值 = 7
>
> == 三个阶段都不接 ==
>     -> 捕获到 NSInvalidArgumentException
>     -> -[Unhandled nobodyHandlesThis]: unrecognized selector sent to instance 0x101321860
> ```
>
> **还有一条容易被忽略的结论**：
>
> ```
>   s2 respondsToSelector:@selector(sayHi) = NO  <- 转发能跑通，但这里仍是 NO
> ```
>
> `respondsToSelector:` 只查方法列表，**不考虑转发**。所以「能响应」和「`respondsToSelector:` 返回 YES」是两回事——写防御性代码时容易踩。
>
> 💡 另一个踩坑记录：我最初想演示兜底时重写了 `doesNotRecognizeSelector:` 并正常返回，结果进程直接 **SIGTRAP**。runtime 断言这个方法**绝不能返回**，只能让它照常抛异常、在调用处 `@try/@catch`。

→ [原文：runtime](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runtime.md)

### 99. Method Swizzling 的注意事项？🔥

- **在 `+load` 中执行**（理由见[第 7 题](#7-method-swizzling-应该在-load-还是-initialize-中执行为什么-)）
- 放在 `+load` 里本来就只执行一次，`dispatch_once` 属于**防御性编程**而非必需
- **先尝试 `class_addMethod`**，避免误交换到父类的方法
- swizzled 方法里**用 swizzled 的方法名**调用原实现（不是看起来该用的那个名字）

第 3、4 点需要展开——这是最容易写错的地方：

```objc
+ (void)load {
    Method original  = class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method swizzled  = class_getInstanceMethod(self, @selector(xxx_viewWillAppear:));

    // 如果该方法其实定义在父类上，直接 exchange 会把父类的实现也换掉，
    // 影响所有兄弟类。先尝试添加到本类：
    BOOL added = class_addMethod(self,
                                 @selector(viewWillAppear:),
                                 method_getImplementation(swizzled),
                                 method_getTypeEncoding(swizzled));
    if (added) {
        // 添加成功说明本类原来没有该方法，把 swizzled 的实现替换成父类的
        class_replaceMethod(self,
                            @selector(xxx_viewWillAppear:),
                            method_getImplementation(original),
                            method_getTypeEncoding(original));
    } else {
        method_exchangeImplementations(original, swizzled);
    }
}

- (void)xxx_viewWillAppear:(BOOL)animated {
    [self xxx_viewWillAppear:animated];   // ← 看着像递归，其实调的是原实现
    // 埋点逻辑
}
```

最后那行不是递归：交换之后 `xxx_viewWillAppear:` 这个 selector 对应的 IMP 已经是**原来的实现**了。

→ [原文：runtime](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runtime.md)

### 100. Runtime 有哪些实际应用？

**① 字典转模型** —— `class_copyIvarList` / `class_copyPropertyList` 拿到所有属性，配合 KVC 自动映射。MJExtension、YYModel 的核心思路，详见[第 106 题](#106-oc-的字典转模型是怎么通过反射实现的)。

**② 防数组越界崩溃** —— Method Swizzling hook `NSArray` 类簇私有子类 `__NSArrayI` 的 `objectAtIndex:`，调用前加边界检查，越界返回 nil。

⚠️ **建议只在 Release 启用**，Debug 仍然抛异常，否则问题会被一直藏着。

**③ 无侵入埋点（AOP）** —— hook `UIViewController` 的 `viewDidAppear:` 等生命周期方法，不改业务代码就给所有页面加上 PV 统计。埋点逻辑集中在一个 Category 里，与业务完全解耦。

**④ 多播代理** —— 用完整转发阶段实现一对多分发，多个对象同时监听同一事件源。可基于 `NSProxy`（透明）或 `NSObject` 子类（更灵活）。

→ [原文：runtime](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runtime.md)

### 101. NSProxy 和 NSObject 的区别？🔥

两个都是 ObjC 的**根类**，但设计目的完全不同。

| | `NSObject` | `NSProxy` |
| --- | --- | --- |
| 转发流程 | 三阶段（动态解析 → 快速转发 → 完整转发） | **跳过前两阶段，直接进完整转发** |
| 基础方法 | 实现了一大堆（`retain`、`release`、`isKindOfClass:`、`respondsToSelector:`…） | **几乎什么都不实现** |
| 伪装能力 | 弱——内省方法被自己消费掉，不会转发 | 强——几乎所有消息都转给真实对象 |

**内省方法的表现差异是关键：**

```objc
// NSObject 子类做代理
DogProxyA *proxyA = ...;                        // 继承 NSObject，内部持有 Dog
[proxyA bark];                                  // ✅ 未实现 → 转发 → Dog 处理
[proxyA isKindOfClass:[Dog class]];             // ❌ NO —— NSObject 自己实现了，直接答了
[proxyA respondsToSelector:@selector(bark)];    // ❌ NO —— 同上

// NSProxy 子类做代理
DogProxyB *proxyB = ...;                        // 继承 NSProxy，内部持有 Dog
[proxyB bark];                                  // ✅ 转发 → Dog 处理
[proxyB isKindOfClass:[Dog class]];             // ✅ 转发 → Dog 答 YES
[proxyB respondsToSelector:@selector(bark)];    // ✅ 转发 → Dog 答 YES
```

**所以 `NSProxy` 才是真正「透明」的代理**——外界分不出它和真实对象。这也是 `NSProxy` 被用来解决 `NSTimer` 循环引用的原因（见[第 17 题](#17-timer-的使用注意事项有哪些-)）：做一个弱引用真实 target 的 NSProxy 中间层，timer 强引用 proxy，proxy 弱引用 target，环就断了。

`NSProxy` 子类只需重写 `methodSignatureForSelector:` 和 `forwardInvocation:` 两个方法。

→ [原文：runtime](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runtime.md)

### 102. Category 可以添加实例变量、实例方法、类方法吗？🔥

**实例方法和类方法：可以。** 运行时会合并到类对象的 `class_rw_t` 方法列表（类方法合并到元类的）。注意 Category 的方法被**插到列表前面**，所以同名时会先找到 Category 的——**表现上像"覆盖"，但原方法仍然在列表里，没有被替换或删除。**

**实例变量：不能。** 原因要从三层元数据结构说起：`objc_class` → `class_rw_t` → `class_ro_t`。

| | `class_rw_t` | `class_ro_t` |
| --- | --- | --- |
| 读写 | 运行时**可读可写** | 编译期确定，**只读** |
| 创建时机 | 运行时 realize 时创建 | **编译期生成** |
| 方法列表 | 合并后的完整列表（类本身 + 分类） | 只有类本身编译期定义的 `baseMethodList` |
| **实例变量** | **不包含** | **包含 `ivars`，决定实例内存布局** |

关键：**ivar 信息在只读的 `class_ro_t` 里，编译后改不了。** Category 是运行时加载的，若允许它改 ivar 布局，就会改变 `instanceSize` 和 `ivars`，**导致所有已创建对象的内存结构失效**——更要命的是所有已编译子类的 ivar 偏移量全部作废。

所以 Category 只能加**行为**（方法），不能改**结构**（ivar）。想存东西用关联对象，见下题。

> ✅ **实测**（[objc-category-and-ivar.m](ios-snippets/objc-category-and-ivar.m)）两条都验证了：
>
> ```
> == 分类不能加实例变量 ==
>   Person 的 ivar 列表：
>       （空）—— @property 在分类里没有生成任何 ivar
> ```
>
> 注意：分类里写 `@property` **能编译通过**，但它只生成 setter/getter 的**声明**，不生成 ivar，也不生成实现——不自己实现就会运行时崩溃。
>
> ```
> == 分类方法「覆盖」主类方法的真相 ==
>   调用 [p whoAmI]：
>     分类的实现
>   方法列表里两个实现都还在，分类的被插到了前面：
>       第 2 个方法是 whoAmI，IMP=0x104a0cab4  <- 先找到这个
>       第 3 个方法是 whoAmI，IMP=0x104a0c9c8
> ```
>
> **两个 IMP 都在方法列表里**，地址不同，只是分类那个排在前面。这就证明了「不是替换，是插队」。

→ [原文：Objective-C 底层原理-NSObject](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C底层原理-NSObject.md)

### 103. 如何给分类添加成员变量？🔥

编译期的 `category_t` 结构体里**没有 `ivar_list`**，所以加不了。用**关联对象**间接实现：

```objc
#import <objc/runtime.h>

static const void *kNameKey = &kNameKey;   // 用变量自身地址当 key，保证唯一

@implementation UIView (Extension)
- (void)setName:(NSString *)name {
    objc_setAssociatedObject(self, kNameKey, name, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)name {
    return objc_getAssociatedObject(self, kNameKey);
}
@end
```

**存储结构**——关联对象**不在对象本身的内存里**，而是 runtime 维护的全局哈希表：

```
AssociationsManager
  └─ AssociationsHashMap:   { 对象指针 → ObjectAssociationMap }
                                          └─ { key → ObjcAssociation(policy, value) }
```

| API | 做什么 |
| --- | --- |
| `objc_setAssociatedObject` | 以对象指针为 key 找到（或创建）`ObjectAssociationMap`，再以传入的 key 存 value 和内存管理策略 |
| `objc_getAssociatedObject` | 同路径取出 |
| `objc_removeAssociatedObjects` | 移除该对象**所有**关联对象 |

✅ **不会内存泄漏**：对象 `dealloc` 时 runtime 会自动检查并清理它的所有关联对象（这也是[第 82 题](#82-weak-变量在对象释放后为什么能自动变成-nil)里 `objc_destructInstance` 干的活之一）。

> ✅ **实测**（[objc-category-and-ivar.m](ios-snippets/objc-category-and-ivar.m)）
>
> ```
>   p.nickname = 小明  <- 存在全局 AssociationsManager 哈希表里，不在对象内存布局中
> ```
>
> 对照上一题的输出：`class_copyIvarList` 仍然返回空——关联对象**确实没有进入对象的内存布局**。

→ [原文：runtime](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/runtime.md)

### 104. iOS 中有哪些反射机制？OC 和 Swift 的反射有什么区别？🔥

两套，能力差得很远。

**ObjC Runtime 反射——完整的动态反射（可读可写可改）**

运行时能拿到属性列表、方法列表、ivar 列表、协议列表，还能**动态创建类、加方法、改方法实现（Swizzling）、用字符串创建对象**（`NSClassFromString`）。元数据在 `class_rw_t` / `class_ro_t` 里。**只支持 ObjC 类。**

**Swift Mirror 反射——有限的只读内省**

`Mirror(reflecting:)` 能拿类型名、存储属性名和值、`displayStyle`，还能用 `superclassMirror` 遍历继承链。底层依赖编译器写进 Mach-O 的 `__swift5_fieldmd`、`__swift5_reflstr`。支持所有 Swift 类型（struct/class/enum/tuple），但**不能改属性、不能拿方法列表、不能动态调用方法**。

**核心区别：OC 反射追求最大灵活性，Swift 反射追求编译期安全。**

继承自 `NSObject` 的 Swift 类两套可以共存，但 **ObjC Runtime 只看得见标了 `@objc` 的成员**。

> ✅ **实测**（[swift-reflection-codable.swift](ios-snippets/swift-reflection-codable.swift)）Mirror 的能力边界：
>
> ```
>   displayStyle = struct
>   subjectType  = User
>   children:
>       id  :  Int  =  7
>       name  :  String  =  Ann
>       tags  :  Array<String>  =  ["a", "b"]
>       secret  :  String  =  hidden        ← private 属性也被列出来了
> ```
>
> 两条值得注意：
>
> 1. **`private` 属性照样能被 Mirror 读到** —— 它看的是内存布局，不受访问控制影响。别拿 `private` 当安全措施
> 2. **计算属性不在里面** —— 实测 `WithComputed` 的 children 只有 `["stored"]`。因为计算属性没有存储，不在布局里

→ [原文：iOS 反射](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS反射.md)

### 105. Swift 的 Mirror 底层是怎么实现的？

依赖编译器写进 Mach-O 的反射元数据，涉及四个 section：

| Section | 存什么 |
| --- | --- |
| `__swift5_fieldmd` | Field Descriptor：字段数量、每个字段的名称引用和类型引用 |
| `__swift5_reflstr` | 字段名称的字符串常量 |
| `__swift5_types` | Type Descriptor：类型名、泛型参数、字段数量、Field Descriptor 的相对偏移 |
| `__swift5_typeref` | 字段类型的 Mangled Name 引用 |

**创建 `Mirror(reflecting:)` 时**：通过值的类型元数据指针找到 Type Descriptor → 通过其中的 Field Descriptor 引用定位字段描述 → 逐个读字段名（从 `__swift5_reflstr`）和字段偏移量（从元数据的 Field Offset Vector）→ 从值的内存地址加偏移量处读出字段值 → 构建 `Mirror.Child` 数组。

**逃生口**：类型若遵循 `CustomReflectable`，Mirror 会优先调 `customMirror` 属性，跳过默认流程。

> 💡 这几个 section 正是[第 1 题](#1-app-启动的详细流程是什么-)里 Pre-main 第 ⑤ 步注册的那些。那一步只登记指针不解析，**首次 `Mirror(reflecting:)` 才触发真正的字段描述符解析**——两题可以串起来答。

→ [原文：iOS 反射](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS反射.md)

### 106. OC 的字典转模型是怎么通过反射实现的？

五步：

1. `class_copyPropertyList`（或 `class_copyIvarList`）拿属性列表
2. 遍历，用 `property_getName` 取属性名
3. 以属性名为 key 从字典取值
4. `setValue:forKey:`（KVC）设进模型对象
5. `free` 释放属性列表的内存 ← **别忘了，`copy` 开头的 runtime API 都要手动 free**

实际框架（MJExtension、YYModel）还要处理：类型转换（字符串转数字）、嵌套模型递归、数组元素类型识别（靠约定的类方法返回）、属性名与 JSON key 的映射、`NSNull` 处理。

YYModel 为了性能还做了两件事：**用 `objc_msgSend` 直接调 setter 而不走 KVC**，以及**缓存属性类型信息**避免重复解析。

> 对比 Swift 的 Codable（[第 56 题](#56-codable-的底层原理是什么-)）：那边是编译期合成、类型安全、失败会精确报错；这边是运行时反射、灵活但通常静默失败。

→ [原文：iOS 反射](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS反射.md)

### 107. `NSClassFromString` 在什么场景下使用？有什么注意事项？

**场景**

1. **路由系统** —— 组件化架构里 URL → 类名字符串 → `NSClassFromString` → 创建对象，实现模块解耦
2. **动态加载** —— 按配置或服务端下发的类名创建不同的 VC / 策略对象
3. **避免硬依赖** —— 要用某个类但不想 import 它的头文件（如可选依赖的 SDK）

**注意事项**

- 类不存在返回 `nil` **不崩溃**，所以**必须判空**
- ⚠️ **Swift 类的命名空间**：Swift 类在 runtime 里的名字**带模块名前缀**（`MyApp.MyViewController`），必须传完整的 `"模块名.类名"`，否则返回 nil。标了 `@objc(CustomName)` 的则用括号里的名字
- 别在性能敏感路径里频繁调用——它要做全局类表的哈希查找

这个模块名前缀的问题，根子在[第 25 题](#25-objc-和-swift-的符号名有什么区别)：Swift 符号包含模块信息，ObjC 不包含。

→ [原文：iOS 反射](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS反射.md)

---

## 九、语言特性

### Objective-C

### 108. `#include`、`#import ""`、`#import <>`、`@import` 的区别？🔥

| 写法 | 本质 | 主要搜索范围 | 防重复 | 自动链接 Framework |
| --- | --- | --- | --- | --- |
| `#include` | C 预处理器**文本包含** | 看引号还是尖括号 | ❌ 要自己写 include guard | ❌ |
| `#import "A.h"` | ObjC 文本包含 | Includer 目录 + Quoted + Angled + System | ✅ | ❌ |
| `#import <A.h>` | ObjC 文本包含 | Angled + System | ✅ | ❌ |
| `@import UIKit;` | **Clang Module 导入** | Module Map + Framework 搜索路径 + 编译器内置 Module | ✅ | **✅** |

前三个都是文本包含，只有 `@import` 是真正不同的机制——它导入的是预编译好的模块，不是复制头文件文本。

**六种搜索路径**（能说清楚这个就够了）：

| 路径 | 编译器参数 | Xcode 设置 | 谁能用 |
| --- | --- | --- | --- |
| Includer 目录 | — | — | **只有双引号形式** |
| Quoted | `-iquote` | User Header Search Paths | 只有双引号形式 |
| Angled | `-I` | Header Search Paths | 双引号和尖括号都搜 |
| System | `-isystem` | System Header Search Paths | 两者都搜 |
| Framework | `-F` | Framework Search Paths | 查 `X.framework/Headers/` 和 `X.framework/Modules/module.modulemap` |
| Module | `-fmodule-map-file` | — | modulemap、Framework 里的 `Modules/module.modulemap`、编译器内置 |

注意 `#import <Framework/Header.h>` 这种形式**也会查 `-F` 路径**。

→ [原文：Objective-C 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C中import详解.md)

### 109. Clang Module 只能通过 `@import` 使用吗？

**不是。**

- `#import <Framework/Header.h>` 在启用 Modules 后会**自动转换成 Module 引用**
- `#import "FrameworkHeader.h"` 经 Header Map 映射后也可能触发 Module 引用

所以项目里没写过一个 `@import`，不代表没用到 Module。

→ [原文：Objective-C 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C中import详解.md)

### 110. Clang Module 的作用是什么？解决了什么问题？🔥

把头文件预编译成高效的二进制格式（`.pcm`），编译器直接加载，不用每次重新解析文本头文件。

解决五个问题：

1. **编译效率** —— 传统 `#include`/`#import` 每次编译都重新解析。Module 编译一次缓存成 `.pcm`，多个源文件复用
2. **宏污染** —— 传统方式下头文件 A 定义的宏会影响后面引入的头文件 B。**Module 有隔离性**，内部的宏不泄露到外部，反之亦然
3. **编译顺序依赖** —— 传统方式下头文件引入顺序可能影响编译结果。Module 是独立编译单元，**不受顺序影响**
4. **手动链接** —— `@import` 自动链接对应 Framework，不用在 Build Phases 里手动加
5. **PCH 的局限**：

   | | PCH | Module |
   | --- | --- | --- |
   | 数量 | **只能有一个** | 多个独立缓存 |
   | 依赖形式 | 只支持线性依赖 | 支持 **DAG** |
   | 增量编译 | 改任何头文件都要全部重新生成 | 高效得多 |

→ [原文：Objective-C 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C中import详解.md)

### 111. 为什么修改 PCH 后编译很慢？

PCH 是**单一的**预编译文件，包含所有放进去的头文件的完整 AST。任何一个头文件改了：

1. 整个 PCH 要重新生成
2. **所有依赖这个 PCH 的源文件都要重新编译**

这就是 PCH 最大的缺点。三条建议：

- 只把**几乎不会改**的头文件放进 PCH
- **项目自己的头文件不要放进 PCH**（这是最常见的错误用法）
- 考虑迁移到 Clang Modules

→ [原文：Objective-C 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C中import详解.md)

### 112. CocoaPods 是如何支持 Clang Module 的？

CocoaPods **默认不给静态库 Pod 生成 modulemap**。三种启用方式：

```ruby
use_modular_headers!                          # 全局启用
pod 'AFNetworking', :modular_headers => true  # 单个 Pod 启用
use_frameworks!                               # 构建为 Framework，自动支持
```

实现机制不同：

- **`use_frameworks!`** —— Pod 构建为 Framework，Framework 本身就支持 Module（设 `DEFINES_MODULE = YES`，modulemap 在 Framework 目录结构里）
- **`use_modular_headers!`** —— Pod 仍是静态库 `.a`，CocoaPods 生成 `module.modulemap` 和 Umbrella Header，然后在**使用方**的 xcconfig 里加 `-fmodule-map-file` 指向它。所以 Pod 自身的 `DEFINES_MODULE` 保持 NO，但使用方仍能按 Module 引用

配合[第 27 题](#27-cocoapods-有哪些库的链接方式各有什么优缺点)的链接方式表一起看。

→ [原文：Objective-C 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C中import详解.md)

### 113. 为什么 `#import ""` 也能引用到 Pod 库里的 Objective-C 文件？

`pod install` 时做了两件事：

1. 在 `Pods/Headers/Public/` 下为每个 Pod 的公开头文件创建**符号链接**
2. 在生成的 xcconfig 里加 `HEADER_SEARCH_PATHS`：

```
HEADER_SEARCH_PATHS = $(inherited) "${PODS_ROOT}/Headers/Public" "${PODS_ROOT}/Headers/Public/AFNetworking"
```

于是写 `#import "AFNetworking.h"` 时：Clang 先在 includer 目录找（找不到）→ 遍历 SearchDirs，在 `${PODS_ROOT}/Headers/Public/AFNetworking/` 找到符号链接 → 顺着链接定位到真实头文件。

→ [原文：Objective-C 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C中import详解.md)

### 114. `nil`、`Nil`、`NULL`、`NSNull` 有什么区别？🔥

| 符号 | 类型 | 含义 | 用在哪 |
| --- | --- | --- | --- |
| `nil` | `id` | 空对象指针 | ObjC 对象为空 |
| `Nil` | `Class` | 空类指针 | 类对象为空 |
| `NULL` | `void *` | C 风格空指针 | 任意 C 指针为空 |
| `NSNull` | `NSNull *` | **单例对象**，表示"空值" | 放进集合里占位 |

**前三个的值都是 0，区别纯粹在语义和类型上。** `NSNull` 完全不同——它是个**真实存在的对象**。

> ✅ **实测**（[objc-value-semantics.m](ios-snippets/objc-value-semantics.m)）
>
> ```
>   nil    = 0x0  用于对象指针 (id)
>   Nil    = 0x0  用于类对象 (Class)
>   NULL   = 0x0  用于 C 指针
>   NSNull = NSNull，是个真实对象，指针 = 0x1f2035688
>   容器不能装 nil，只能用 NSNull 占位：( 1, "<null>", 3 )
>   [NSNull null] 自身非空：真
> ```
>
> 最后一行是重点：`if ([NSNull null])` 判断结果是**真**。从字典里取值忘了判 `NSNull` 而只判 `nil`，就会拿着一个 `NSNull` 对象当正常值用，然后在后面某个地方 `unrecognized selector` 崩掉——这是 OC 里非常常见的线上崩溃来源。

**向 nil 发消息不崩溃**是 ObjC 的重要特性（见[第 97 题](#97-objc_msgsend-的执行流程-)第 1 步），但代价是某些 bug 会**静默失败**而不暴露。

### 115. `@synthesize` 和 `@dynamic` 分别是什么？

| 关键字 | 含义 |
| --- | --- |
| `@synthesize` | 让编译器**自动生成** getter/setter 实现 |
| `@dynamic` | 告诉编译器**别生成**，我自己提供（或运行时提供） |

```objc
@implementation MyClass
@synthesize name = _name;   // 指定 ivar 名为 _name
@dynamic createdAt;         // 常用于 Core Data 的 NSManagedObject 子类
@end
```

现代 ObjC（Xcode 4.4+）里 `@property` 会**自动**合成 getter/setter 和带下划线的 ivar，所以一般不用显式写 `@synthesize`。

`@dynamic` 的典型用途就是 Core Data：属性访问器由 `NSManagedObject` 在运行时动态提供，编译期生成反而会覆盖掉。

### 116. `[self class]` 和 `[super class]` 结果一样吗？🔥

**一样。** 这是个经典陷阱题。

```objc
// B 继承自 A
@implementation B
- (void)test {
    NSLog(@"%@", [self class]);    // B
    NSLog(@"%@", [super class]);   // B —— 不是 A！
}
@end
```

**`super` 的本质是：消息接收者仍然是 `self`，只是告诉编译器从父类的方法列表开始查找。**

`NSObject` 的 `-class` 实现大致是：

```objc
- (Class)class { return object_getClass(self); }
```

它拿到的 `self` 仍是当前对象，按对象的 isa 取真实类型，结果自然还是 `B`。

> ✅ **实测**（[objc-value-semantics.m](ios-snippets/objc-value-semantics.m)）
>
> ```
>   [self class]      = Sub
>   [self superclass] = Super
>   [super class]     = Sub   <- 仍是 Sub！
>   [super superclass]= Super
> ```
>
> 四个组合一起看就清楚了：**变的是「从哪开始找方法」，不变的是「接收者是谁」。** `[super superclass]` 也返回 `Super` 而不是 `Super` 的父类，同理。

⚠️ 唯一的例外：如果当前类**重写了 `-class`**，两者就会不同——`[super class]` 会跳过当前类的实现。

### 117. `NSString` 用 `==` 和 `isEqualToString:` 有什么区别？🔥

`==` 比**指针地址**，`isEqualToString:` 比**内容**。

> ✅ **实测**（[objc-value-semantics.m](ios-snippets/objc-value-semantics.m)）
>
> ```
>   a == b                    -> YES  (同一份编译期常量，指针相同)
>   a == c                    -> NO   (运行时构造，另一块内存)
>   [a isEqualToString:c]     -> YES  (内容相同)
>   a=__NSCFConstantString  c=NSTaggedPointerString
> ```
>
> 最后一行解释了为什么 `a == b` 是 YES 而 `a == c` 是 NO：两个字面量 `@"hello"` 被编译器合并成了**同一个** `__NSCFConstantString`；而运行时 `stringWithFormat:` 构造的是 `NSTaggedPointerString`，完全另一个对象。
>
> ⚠️ **正因为常量有时会让 `==` 恰好返回 YES，这个 bug 特别隐蔽**——测试时用字面量一切正常，线上换成服务端下发的字符串就全错了。比较字符串永远用 `isEqualToString:`。

### 118. `NSArray` 和 `NSMutableArray` 的 `copy` 和 `mutableCopy` 有什么区别？🔥

| 源对象 | `copy` | `mutableCopy` |
| --- | --- | --- |
| 不可变 `NSArray` | **返回自身**，不产生新对象 | 新的 `NSMutableArray` |
| 可变 `NSMutableArray` | 新的 `NSArray` | 新的 `NSMutableArray` |

**规律：只有「不可变对象 `copy`」会直接返回自身，其余三种都产生新对象。**

> ✅ **实测**（[objc-value-semantics.m](ios-snippets/objc-value-semantics.m)）
>
> ```
>   [不可变 copy]        新对象? 否  类型=NSConstantArray
>   [不可变 mutableCopy] 新对象? 是  类型=__NSArrayM
>   [可变   copy]        新对象? 是  类型=__NSArrayI
>   [可变   mutableCopy] 新对象? 是  类型=__NSArrayM
> ```

⚠️ **这里要纠正一个流传很广的说法。** 常见资料会写「对可变对象 `copy` 是深拷贝」——**这是错的**。它确实产生了新的不可变数组，但**仍然是浅拷贝**：新数组里装的还是原来那些元素对象本身，没有复制它们。

> ✅ **实测**：
>
> ```
>   都是浅拷贝——元素本身不复制：
>   改了原始元素后，拷贝里也变了：( x, y )
> ```
>
> 对 `outer = @[inner]` 做 `copy` 得到 `shallow`，然后往 `inner` 里 `addObject:@"y"`，`shallow[0]` 跟着变成了 `(x, y)`。**「产生新容器」和「深拷贝」是两回事。**

真正的深拷贝要用 `initWithArray:copyItems:YES`（仍只深一层）或归档/反归档。

### 119. `self.xxx` 和 `_xxx` 有什么区别？🔥

```objc
self.name = @"Tom";   // 调 setter，走属性修饰符逻辑
_name = @"Tom";       // 直接访问 ivar，不走 setter
```

| | `self.xxx` | `_xxx` |
| --- | --- | --- |
| 本质 | 调 getter/setter **方法** | 直接访问**成员变量** |
| KVO 通知 | ✅ 触发 | ❌ 不触发 |
| 属性修饰符（如 `copy`） | ✅ 生效 | ❌ 不生效 |
| 懒加载 | ✅ 触发 | ❌ 不触发 |
| 性能 | 略慢（方法调用） | 略快 |

**使用原则**

| 场景 | 用哪个 | 为什么 |
| --- | --- | --- |
| 外部访问 | `self.xxx` | 没得选 |
| `init` 方法里 | **`_xxx`** | 避免触发子类重写的 setter——此时子类还没初始化完 |
| `dealloc` 里 | **`_xxx`** | 对象正在销毁，走 setter 可能访问到已释放的东西 |
| 其他内部方法 | `self.xxx` | 保证 KVO 和懒加载正常工作 |

「KVO 不触发」那一条和[第 19 题的实测](#19-kvo-的底层实现原理是什么-)是同一件事：直接写 ivar 绕过了被 KVO 替换的 setter。

### 120. static 局部变量和普通局部变量有什么区别？

| | 普通局部变量 | `static` 局部变量 |
| --- | --- | --- |
| 存储位置 | **栈** | **数据段**（.data / .bss） |
| 初始化次数 | 每次函数调用 | **仅一次**（程序启动时） |
| 生命周期 | 函数调用期间 | 整个进程 |
| 默认初值 | 不确定（垃圾值） | 0 / nil / NULL |
| 作用域 | 函数内 | 函数内（**不变**） |

注意最后一行：`static` 改变的是**生命周期和链接属性**，**不改变作用域**。

> ✅ **实测**（[objc-value-semantics.m](ios-snippets/objc-value-semantics.m)）
>
> ```
>   第 1 次调用  static=1  普通=1
>   第 2 次调用  static=2  普通=1
>   第 3 次调用  static=3  普通=1
> ```

**Block 捕获时的差异**（接[第 20 题](#20-oc-中的-block-是函数指针还是对象底层怎么实现的-)）：

| | 普通局部变量 | `static` 局部变量 |
| --- | --- | --- |
| 捕获方式 | 值拷贝（const copy） | **指针捕获** |
| Block 内可改 | ❌ 需要 `__block` | **✅ 可以** |
| 原因 | 值已拷进 Block 结构体 | 地址固定在数据段，直接通过指针访问 |

→ [原文：static 关键字详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/static关键字详解.md)

### 121. 不同 `.m` 文件中定义了同名的 static 全局变量会冲突吗？

**不会。** 核心在于 `static` 改变了变量的**链接属性（Linkage）**：

| | 不加 `static` | 加 `static` |
| --- | --- | --- |
| 链接属性 | **external linkage** | **internal linkage** |
| 符号表 | 导出到全局符号表 | 标记为**本地符号**，不导出 |
| 同名后果 | 链接器合并 `.o` 时发现重复 → `duplicate symbol` 错误 | 各文件的同名变量在符号表里是**各自独立的条目**，链接器不会尝试合并，内存中也是独立存储 |

这正是[第 25 题](#25-objc-和-swift-的符号名有什么区别)里 ObjC 类名冲突的同一套机制——只不过类符号 `_OBJC_CLASS_$_X` 没法加 `static`，所以只能靠前缀约定。

→ [原文：static 关键字详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/static关键字详解.md)

### Swift

### 122. 为什么同一 Target 下的 Swift 文件不需要 import？

因为 **Swift 以「模块」而非「源文件」作为基本的编译和可见性单元。**

Xcode 里每个 Build Target（App 或 Framework）就是一个模块。同模块内所有 `.swift` 文件共享统一命名空间，编译器把它们当一个整体分析。

Swift 默认访问级别是 `internal`，它的定义就是**「模块内可见」**。所以 `FileA.swift` 里定义的 `class MyClass`（没标访问级别），在同模块的 `FileB.swift` 里直接就能用。

这和 ObjC 的「以源文件为单位、靠头文件声明」是完全不同的模型。

→ [原文：Swift 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift中import详解.md)

### 123. Swift `import` 和 OC `@import` 有什么区别？

**区别只有两点**：

**① 可导入的模块类型不同**

- `@import` —— **只能**导入 Clang Module（需要 `module.modulemap` 定义）
- `import` —— 既能导入 Swift 模块（`.swiftmodule`），也能通过 **ClangImporter** 导入 Clang 模块

**② Swift 支持声明级别导入**

```swift
import class UIKit.UIViewController    // 只导入特定类型，可用于解决命名冲突
import struct Darwin.size_t
```

`@import` 只能导入整个模块或子模块，精确不到单个类型。

**相同点**：都在**语义分析阶段**处理（不是预处理器）、都支持自动链接、都支持子模块导入、都享受模块缓存的编译加速。

→ [原文：Swift 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift中import详解.md)

### 124. Swift Module 和 Clang Module 有什么区别？

| | Clang Module | Swift Module |
| --- | --- | --- |
| **定义方式** | 要**手写** `module.modulemap` | 编译器**自动**序列化公开 API |
| **文件格式** | `.pcm`，只含 AST 和类型信息 | `.swiftmodule`，除 AST 外还含 **SIL 和内联函数体**，支持跨模块优化 |
| **ABI 稳定** | 二进制格式，强依赖编译器版本，**无法跨版本共享** | 额外提供 `.swiftinterface` **文本**格式，支持 Library Evolution，可跨编译器版本 |

**互操作是单向的**：

- Swift → Clang：✅ 通过 ClangImporter 直接解析 `.pcm` 和 `module.modulemap`
- Clang → Swift：❌ Clang **无法**直接解析 `.swiftmodule`。OC 导入 Swift Framework 时，实际是通过 Xcode 自动生成的 `module.modulemap`（引用 `-Swift.h` 头文件）实现的，**本质上 Clang 读的仍然是 OC 头文件**

`.swiftinterface` 那一条是[第 48 题](#48-swift-二进制兼容带来的好处是什么)里「模块稳定性」的具体载体。

→ [原文：Swift 中 import 详解](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift中import详解.md)

### 125. Swift 中 Copy-on-Write 的底层原理是什么？🔥

COW 是 Swift 在**值语义**和**性能**之间的平衡。按值语义，`Array`/`Dictionary`/`Set` 赋值后应该彼此独立；但每次赋值都深拷贝，大集合成本高得离谱。COW 的思路：**赋值时先共享底层存储，真正修改时才拷贝。**

关键在于 `Array` **不是**把元素都塞进栈上的变量本身。外层 `Array` 是个很小的结构体，里面存着指向**堆上 buffer** 的引用 + 元素数量 + 容量。赋值时复制的只是这个小结构体，两个变量暂时指向同一块堆存储。

修改时（`append`、`remove`、下标赋值）先检查底层存储是否被多个变量共享：

```swift
struct MyArray<Element> {
    private var storage: ArrayStorage<Element>

    mutating func append(_ element: Element) {
        if !isKnownUniquelyReferenced(&storage) {   // ← 核心
            storage = storage.copy()
        }
        storage.append(element)
    }
}
```

`isKnownUniquelyReferenced(&storage)` 判断这块 class 形式的底层存储**是否只有当前这一个强引用**。唯一 → 直接原地改；不唯一 → 先复制一份新 storage 再改。

四步概括：创建变量持有堆 buffer → 赋值只复制外层结构体，buffer 共享 → 修改前检查唯一性 → 必要时才拷贝。

> ✅ **实测**（[swift-memory-arc.swift](ios-snippets/swift-memory-arc.swift)）直接把缓冲区地址打出来了：
>
> ```
>   arr1 缓冲区 = 0x0000000bdfdf5100
>   arr2 缓冲区 = 0x0000000bdfdf5100   <- 和 arr1 相同，还没复制
>   arr2.append(6) 之后：
>   arr1 缓冲区 = 0x0000000bdfdf5100
>   arr2 缓冲区 = 0x0000000be2d97ac0   <- 变了，此刻才真复制
>   arr1 = [1, 2, 3, 4, 5]
>   arr2 = [1, 2, 3, 4, 5, 6]
> ```
>
> 以及 `isKnownUniquelyReferenced` 本身：
>
> ```
>   唯一引用时 isKnownUniquelyReferenced = true
>   多一个引用后                        = false
> ```
>
> **赋值时地址相同、`append` 后才变**——「值语义但不真复制」在这两行地址里看得清清楚楚。

→ [原文：值类型和引用类型的区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/值类型和引用类型的区别.md)

### 126. Swift 宏解决的核心问题是什么？

**编译期代码生成**：让开发者写一段「会生成 Swift 代码的代码」，由编译器在**类型检查前**展开成真正的 Swift 源码，再继续走类型检查、SIL 生成和优化。

在宏出现之前，Swift 的元编程工具各有明显边界：

| 工具 | 能做 | 做不到 |
| --- | --- | --- |
| `@propertyWrapper` | 给**单个属性**加读写行为（`@State`、`@Published`） | 生成新方法、让类型自动遵循协议、批量改写成员 |
| `@resultBuilder` | 把闭包里的表达式收集成 DSL（`ViewBuilder`） | 只作用于闭包内部，**改造不了类型声明** |
| `Mirror` / KeyPath | 运行时反射或半反射 | 性能、类型安全、可维护性都不适合大量生成样板 |
| `Codable` 自动合成 | —— | **属于编译器魔法，普通开发者写不出同等能力** |
| Sourcery / SwiftGen | 生成代码 | 在编译器**之外**运行，只能做文本级处理，缺少语法树上下文，和 IDE / 增量编译 / 诊断结合不自然 |

宏的价值是：**把「只有编译器能做的源码变换」开放给了开发者**，同时保留 Swift 的强类型、作用域、诊断和 IDE 展开体验。它不是运行时反射，也不是字符串模板，而是**基于 SwiftSyntax 的语法树变换**。

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### 127. Swift 宏和 OC 的 `#define` 有什么本质区别？

都叫「宏」，本质完全不同。

| | `#define` | Swift 宏 |
| --- | --- | --- |
| **执行阶段** | 预处理阶段（编译器还没理解代码） | 编译流程**内部**，类型检查**前**展开 |
| **操作对象** | **文本 / token** | **SwiftSyntax 语法节点** |
| **输入输出** | 字符串 → 字符串 | **语法树 → 语法树** |
| **类型安全** | 替换时完全不知道类型 | 宏的声明签名参与类型检查，展开结果必须是合法 Swift |
| **卫生性** | 无，容易变量名冲突、重复求值 | 有部分卫生机制，可用 `context.makeUniqueName`，附加宏还要通过 `names:` 声明生成的外部名字 |
| **调试** | 展开结果对 IDE 和调试器不友好 | Xcode 可 **Expand Macro** 看展开后代码，有诊断系统定位错误 |
| **运行模型** | 预处理器 | 第三方宏以**独立编译器插件进程**运行，通过 JSON-RPC 与 `swiftc` 通信 |

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### 128. Swift 宏分为哪两大类？附加宏有哪些常见 role？

**独立宏（Freestanding）** —— 以 `#` 开头，不依附任何声明：

- **表达式宏**：生成表达式，如 `#stringify(1 + 2)` 展开成 `(1 + 2, "1 + 2")`
- **声明宏**：生成声明，如 SwiftUI 的 `#Preview`

**附加宏（Attached）** —— 以 `@` 开头，附着在已有声明上，按 role 决定能生成/改写什么：

| role | 作用 | 例子 |
| --- | --- | --- |
| `peer` | 在被标注声明的**同级**生成新声明 | 给 completionHandler 风格方法生成 `async` 重载 |
| `member` | 给类型内部**新增成员** | `@Observable` 生成 `_$observationRegistrar`、`access`、`withMutation` |
| `accessor` | 给属性**生成访问器** | `@ObservationTracked` 改写 getter/setter 做依赖收集 |
| `memberAttribute` | 给类型里的成员**批量加属性** | `@Observable` 给存储属性加 `@ObservationTracked` |
| `extension` | 生成扩展，通常用于**自动遵循协议** | Swift 5.10 后协议遵循能力并入此 role |
| `body` | 生成或替换**函数体** | Swift Testing 的 `@Test` |
| `preamble` | 在函数体**开头**插代码 | 轻量日志、埋点、权限检查 |

**一个宏可以同时有多个 role**，`@Observable` 就是典型，见[第 131 题](#131-observable-大致做了什么为什么说它体现了宏的组合能力)。

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### 129. Swift 宏的执行流程是什么？为什么宏不能直接拿到完整类型信息？

**流程七步**：

1. 编译器读源文件，解析成 Swift 语法结构
2. **类型检查前**遇到宏调用（`#stringify` / `@Observable`）
3. `swiftc` 启动或复用对应的宏插件进程
4. 通过 **JSON-RPC** 把宏调用节点、被标注声明节点等语法信息发给插件
5. 插件用 SwiftSyntax 分析输入，构造新的 `ExprSyntax` / `DeclSyntax`
6. 插件把展开后的 Swift 代码片段返回
7. 编译器拼回源码对应位置，继续类型检查、SIL、优化

**关键就在第 2 步：宏在类型检查前展开。** 所以宏实现里看到的是**语法**，不是已解析完成的**类型语义**。

宏能看到源码写了 `var items: [Item]`，拿到的是 `VariableDeclSyntax`、`TypeSyntax` 这类节点。它知道字面上写了 `[Item]`，但**无法可靠判断**：

- `Item` 到底是哪个模块里的类型
- 泛型 `T` 最终会被推导成什么
- 某个类型是否**真的**遵循 `Codable` / `Sendable`
- 某个表达式重载解析后会调用哪个函数

**所以宏适合基于「声明形状」生成代码**——这个 struct 有哪些属性、这个函数最后一个参数是不是叫 completion、这个属性有没有显式类型标注。**不适合做类型系统推理**，比如「如果属性类型遵循某协议就生成 A 否则生成 B」。

工程上的分工：**宏负责把代码写出来，类型系统负责证明这些代码是否合法。**

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### 130. 为什么第三方宏要跑在独立进程里？这对工程有什么影响？

**三个原因：**

1. **安全** —— 宏本质是**编译期可执行代码**，第三方宏包可以包含任意 Swift 逻辑。直接跑在编译器进程里风险太大。独立进程配沙盒可以限制文件、网络能力。Xcode 首次用第三方宏时弹的 `Trust & Enable` 就是在提醒你：**你正在允许这个包在编译期执行代码**
2. **崩溃隔离** —— 宏作者写崩了、死循环了，不该把整个 `swiftc` 带崩
3. **演进和复用** —— 宏插件作为 Swift Package 的 `.macro` target 独立编译分发，业务 target 只依赖暴露宏声明的普通 library target，不用直接接触 SwiftSyntax 细节

**工程代价：**

- 启动插件进程 + JSON-RPC 通信，**宏用多了会增加编译耗时**
- 第三方宏依赖 `swift-syntax`，而它的**主版本必须和 Swift 编译器版本匹配**——升 Xcode 时容易牵一发动全身
- CI 上必须管理宏的信任和供应链安全，锁 `Package.resolved`，谨慎用 `--skip-macro-validation`
- 宏插件**不进入 App 运行时产物**，但影响编译期行为，所以 **code review 不能只看业务代码**

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### 131. `@Observable` 大致做了什么？为什么说它体现了宏的组合能力？

开发者只写：

```swift
@Observable
class UserViewModel {
    var name: String = ""
    var age: Int = 0
}
```

宏做了三类事：

1. **生成观察所需的隐藏成员** —— `_$observationRegistrar`，以及 `access(keyPath:)`、`withMutation(keyPath:_:)` 辅助方法，用于记录读取和包裹写入
2. **给存储属性加追踪能力** —— 通过 `memberAttribute` 给属性加 `@ObservationTracked`；而 `@ObservationTracked` 本身是 **accessor 宏**，把普通存储属性改写成带 getter/setter 的形式
3. **让类型遵循框架协议** —— 生成扩展使其遵循 `Observable`，进入 SwiftUI/Observation 的依赖追踪体系

简化展开：

```swift
class UserViewModel {
    @ObservationIgnored
    private let _$observationRegistrar = ObservationRegistrar()

    @ObservationTracked
    var name: String = "" {
        get {
            access(keyPath: \.name)
            return _name
        }
        set {
            withMutation(keyPath: \.name) { _name = newValue }
        }
    }
    private var _name: String
}

extension UserViewModel: Observable {}
```

**组合能力体现在**：它不是简单生成一段代码，而是**同时用了 `member` + `memberAttribute` + `extension` 三个 role，还配合另一个 accessor 宏改写属性访问**。把过去依赖 runtime、KVO、属性包装器和手写样板的机制，全部迁到了编译期生成的强类型 Swift 代码。

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### 132. 使用 Swift 宏会带来哪些工程风险？什么时候不应该写宏？

**四类风险：**

1. **编译性能** —— 要编译宏插件、启动进程、通信、解析和生成 SwiftSyntax。少量没问题，**大型项目里大量使用复杂宏会明显拖慢 clean build 和增量编译**
2. **版本耦合** —— `swift-syntax` 版本必须和 Swift 编译器版本匹配。Xcode 一升，宏包依赖的 `swift-syntax` 还停在旧主版本就可能**直接编译失败**。要把 Xcode、Swift tools version、swift-syntax、宏库版本**一起管理**
3. **可读性和调试成本** —— 宏让源文件里「看见的代码」少于「实际参与编译的代码」。**调用端简洁、维护端痛苦**是宏 API 设计不好时的典型症状
4. **安全与供应链** —— 编译期执行代码，第三方宏包需要被信任

**不适合写宏的场景：**

- 普通函数、泛型、协议扩展就能清楚表达的逻辑
- **只是为了少写几行代码，却显著降低可读性**
- 需要大量类型语义推理的（见[第 129 题](#129-swift-宏的执行流程是什么为什么宏不能直接拿到完整类型信息)）
- 生成代码过于复杂、调用方很难通过 `Expand Macro` 理解实际行为
- 性能敏感的大型工程里，高频、复杂、无法明确 `names:` 的宏

**适合的场景有共同特征**：样板代码重复、生成规则稳定、输入可从语法结构判断、展开结果容易解释、且生成代码能**显著改善调用端 API**。例如模型代码、测试断言、依赖注入样板、Mock/Spy 生成、预览声明、属性访问追踪。

→ [原文：Swift 宏](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Swift宏.md)

### OC 与 Swift 对比

### 133. Objective-C 与 Swift 有什么主要区别？🔥

> ⚠️ 源仓库这一题只有标题和链接、**没有正文**，以下是我自己整理的。

| 维度 | Objective-C | Swift |
| --- | --- | --- |
| **类型系统** | 动态类型为主，`id` 可指向任意对象，编译期检查弱 | 强静态类型 + 类型推断，编译期检查严格 |
| **空安全** | 无。`nil` 可以随便传，给 nil 发消息静默失败 | **Optional 强制显式处理**，编译期消除大部分空指针问题 |
| **值类型** | 几乎全是对象（堆分配） | struct / enum 是一等公民，**优先栈分配 + COW** |
| **方法派发** | 几乎全走 `objc_msgSend` 消息派发 | 四种派发（见[第 38 题](#38-swift-有哪些方法派发方式-)），大量静态派发可内联 |
| **内存管理** | ARC，引用计数在 isa/SideTable | ARC，纯 Swift 类引用计数内联在对象头；编译器优化更激进 |
| **错误处理** | `NSError **` 出参 + `@try/@catch`（少用） | `throws` / `try` / `Result`，编译器强制处理 |
| **泛型** | 仅轻量泛型（`NSArray<NSString *> *`），**运行时被擦除** | 真泛型，支持特化，零成本抽象 |
| **协议** | 只能定义方法/属性要求 | 可带**默认实现**、关联类型、条件遵循，支持面向协议编程 |
| **运行时能力** | 极强：Swizzling、动态加类加方法、完整反射 | 弱：Mirror 只读；要动态能力得 `@objc dynamic` 退回 ObjC runtime |
| **命名空间** | **无**，靠类名前缀（NS/UI/AF） | 有，模块名自动区分 |
| **并发** | GCD / NSOperation + 手动加锁 | 额外有 async/await、actor、结构化并发、编译期数据竞争检查 |
| **枚举** | 就是整数常量 | 可带关联值、可有方法、可遵循协议 |
| **字符串** | `NSString`，UTF-16，下标按 code unit | `String`，Unicode 正确性优先，按 Character 迭代 |
| **函数式** | 有限（Block） | 一等函数、闭包、`map`/`filter`/`reduce`、模式匹配 |

**取舍的一句话总结**：ObjC 把安全性让给了灵活性——它的动态能力（Swizzling、字典转模型、热修复思路）Swift 原生给不了；Swift 把灵活性让给了安全性和性能——编译期能消除的问题更多，生成的代码也更快。

**混编时要注意的几点**：

- Swift 类要被 ObjC 用，必须继承 `NSObject` 或标 `@objc`，且成员类型要是 **ObjC 可表示**的（struct、enum 带关联值、泛型都传不过去）
- ObjC 的 `nullable`/`nonnull` 标注直接决定 Swift 侧是不是 Optional——**没标注就全是隐式解包 `!`**，很容易崩
- `NSClassFromString` 对 Swift 类要带模块名前缀（见[第 107 题](#107-nsclassfromstring-在什么场景下使用有什么注意事项)）

→ [原文：Objective-C 与 Swift 区别](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/Objective-C与Swift区别.md)

---

## 十、数据持久化

### 134. SQLite 的 WAL 模式是什么？为什么推荐使用？

**WAL**（Write-Ahead Logging）是 SQLite 的一种日志模式。与默认的回滚日志模式相反：

| | 回滚日志（默认） | WAL |
| --- | --- | --- |
| 写入去向 | 先把**原数据**备份到日志，再**直接改数据库文件** | 修改**先写 WAL 文件**，不动数据库主文件 |
| 读写并发 | 写会阻塞读 | **读写可并发** |

核心优势是读写并发：**读取者看到的是最近一次提交前的一致性快照，写入者不阻塞读取者。** iOS 上推荐开 WAL 换更好的并发性能。

→ [原文：iOS 中的数据库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的数据库.md)

### 135. Core Data 的 `NSManagedObjectContext` 为什么不能跨线程使用？

因为它内部维护了**注册对象的缓存、变更追踪**等状态，**这些状态不是线程安全的**。跨线程访问会数据竞争，导致崩溃或数据损坏。

Core Data 给了两种并发模式：

- `mainQueueConcurrencyType` —— 绑定主队列
- `privateQueueConcurrencyType` —— 绑定私有串行队列

并通过 `perform(_:)` / `performAndWait(_:)` 确保操作在正确的队列上执行。

⚠️ **`performAndWait` 嵌套会死锁**——它本质是串行队列的同步执行，见[第 90 题场景 ⑤](#90-ios-中死锁的常见场景有哪些-)。

→ [原文：iOS 中的数据库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的数据库.md)

### 136. 数据库索引为什么能加速查询？什么时候不该建索引？🔥

**为什么快**：没索引就只能全表扫描，O(N)。索引本质是一棵独立的 **B-Tree**，把被索引列的值按顺序组织成树。由于 B-Tree 每个节点能容纳**数百个 Key**，树高度极低——**百万级数据通常只有 3~4 层**，查找任意值只需 3~4 次节点比较，O(log N)。

具体对比：100 万行数据，全表扫描最坏 100 万次比较，B-Tree 查找只需约 20 次。

**什么时候不该建**：

| 情况 | 为什么 |
| --- | --- |
| **低选择性的列** | 如 `is_deleted` 只有 0 和 1，索引无法有效缩小范围 |
| **数据量很小的表** | 全表扫描本身就很快 |
| **写多读少的表** | 每次写入都要维护索引 B-Tree |
| **频繁更新的列** | 每次 UPDATE 都触发索引重排 |
| **查询条件对列用了函数** | `WHERE LOWER(name) = 'test'` —— **索引存的是原始值，命不中** |

最后一条最容易踩：索引建了却因为写法不对完全没生效。

→ [原文：iOS 中的数据库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的数据库.md)

### 137. Realm 的零拷贝是怎么实现的？

用 **mmap** 把数据文件映射到进程虚拟地址空间。Realm 对象的属性访问实际上是**计算属性**，直接读取 mmap 区域中对应偏移量的数据。

这就消除了传统 ORM 的多次内存拷贝：

```
传统 ORM：读取行 → 解析 → 创建对象 → 赋值属性     （多次拷贝）
Realm：   属性访问 → 按偏移量直读映射区            （0 次拷贝）
```

原理见[第 29 题](#29-mmap-有哪些优势适用于哪些场景-)的「零拷贝」和「按需加载」两条。

→ [原文：iOS 中的数据库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的数据库.md)

### 138. MMKV 相比 UserDefaults 的性能优势在哪里？🔥

| | UserDefaults | MMKV |
| --- | --- | --- |
| 写入方式 | **整个 plist 字典重新序列化并写盘** | **增量追加**到文件末尾 |
| 单次写入耗时 | 与**总数据量**成正比 | 与**本次写入数据量**成正比，与总量无关 |
| 底层 | 普通文件 IO | mmap + protobuf 序列化 |

差异的本质在那一行加粗的地方：UserDefaults 存了 10MB 数据，改一个 Bool 也要把 10MB 重新序列化写一遍；MMKV 只追加那几个字节。

mmap 还顺带减少了频繁文件 IO 和用户态拷贝，已写入的映射页由内核管理，进程崩溃后通常比普通用户态缓冲更容易恢复。

⚠️ 但**别把它当强持久化**：mmap 不保证数据一定落盘，关键数据仍需要校验、重放或合适的同步策略。这和[第 29 题](#29-mmap-有哪些优势适用于哪些场景-)里「崩溃现场可恢复」那条的注意事项是一回事。

→ [原文：iOS 中的数据库](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/iOS中的数据库.md)

---

## 十一、计算机网络

> 本章和 [02-deep-dive.md 的 HTTP 章](02-deep-dive.md#http-协议)主题重叠：那边是链接索引（偏前端视角的 HTTPS、状态码、报文、Token），这里是成文答案（偏网络分层与协议细节）。两边互补，可以对照着看。

### 139. OSI 七层模型与 TCP/IP 四层模型的对应关系是什么？各层的作用？

```
OSI 七层              TCP/IP 四层
──────────────────────────────────
应用层  ┐
表示层  ├──────────→  应用层        HTTP、DNS、FTP
会话层  ┘
传输层  ───────────→  传输层        TCP、UDP
网络层  ───────────→  网络层        IP、ICMP、ARP
数据链路层 ┐
物理层     ┴────────→  网络接口层    Ethernet、Wi-Fi
```

| 层 | 干什么 |
| --- | --- |
| **物理层** | 比特流的物理传输，定义电气特性、传输介质（光纤、双绞线） |
| **数据链路层** | 帧的封装与 **MAC 寻址**，负责**相邻节点间**的可靠传输 |
| **网络层** | 路由选择与 **IP 寻址**，负责**跨网络的端到端**数据包传输 |
| **传输层** | **端到端可靠传输**，提供**进程级**通信（靠端口号区分进程） |
| **应用层** | 给应用程序提供网络服务 |

记忆要点：数据链路层是**相邻节点**，网络层是**跨网络端到端**，传输层是**进程到进程**。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 140. 数据从发送方到接收方经历了怎样的封装与解封装过程？

以一次 HTTP 请求为例，**发送方逐层加头**：

| 层 | 做什么 | 产物 |
| --- | --- | --- |
| 应用层 | 构造 HTTP 报文（请求行 + 头 + 体） | 原始数据 |
| 传输层 | 前面加 **TCP 首部**（源/目的端口、序列号、确认号）。超过 **MSS**（通常 1460 字节）要**分段** | TCP 段 Segment |
| 网络层 | 前面加 **IP 首部**（源/目的 IP、TTL、协议类型）。超过 **MTU**（通常 1500 字节）要**分片** | IP 数据包 Packet |
| 数据链路层 | 前加**帧头**（源/目的 MAC、类型），后加**帧尾**（FCS 校验） | 帧 Frame |
| 物理层 | 转成比特流（电信号 / 电磁波） | — |

**接收方完全相反**：物理层还原成帧 → 链路层校验 FCS 并剥帧头尾 → 网络层校验并剥 IP 首部 → 传输层校验、剥 TCP 首部、**重组数据** → 应用层解析 HTTP。

注意 MSS 和 MTU 的关系：MSS = MTU − IP 首部 − TCP 首部 = 1500 − 20 − 20 = 1460。

**分层的核心价值是各层独立演进**：应用层可以换（HTTP → gRPC），传输层可以换（TCP → UDP），只要接口契约不变，其他层不受影响。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 141. TCP 三次握手的过程是怎样的？为什么需要三次而不是两次？🔥

```
客户端                                      服务端
  │  ① SYN=1, seq=x                          │
  ├─────────────────────────────────────────→│
  │  SYN_SENT                        SYN_RCVD│
  │  ② SYN=1, ACK=1, seq=y, ack=x+1          │
  │←─────────────────────────────────────────┤
  │  ③ ACK=1, seq=x+1, ack=y+1               │
  ├─────────────────────────────────────────→│
  │  ESTABLISHED                  ESTABLISHED│
```

**目的**：同步双方的序列号和确认号，并交换 TCP 窗口大小信息。

**为什么不能两次？** 关键场景是**滞留的历史 SYN**：

1. 客户端发的某个 SYN 在网络里**滞留**了
2. 客户端超时重发 SYN，正常建连、传数据、关闭
3. 此后那个滞留的 SYN 才到达服务端
4. 服务端以为是新连接请求，返回 SYN+ACK

**如果只有两次握手**，服务端此刻就进入 ESTABLISHED、**分配资源等数据**——但客户端根本不会发数据，造成资源浪费。

三次握手下，客户端不会确认这个过期的 SYN+ACK，服务端收不到第三次 ACK 就不会建立连接。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 142. TCP 四次挥手的过程是怎样的？为什么需要 TIME_WAIT？🔥

```
客户端                                      服务端
  │  ① FIN                                   │
  ├─────────────────────────────────────────→│
  │  FIN_WAIT_1                    CLOSE_WAIT│  ← 此时服务端可能还有数据要发
  │  ② ACK                                   │
  │←─────────────────────────────────────────┤
  │  FIN_WAIT_2                              │
  │  ③ FIN                                   │
  │←─────────────────────────────────────────┤
  │                                  LAST_ACK│
  │  ④ ACK                                   │
  ├─────────────────────────────────────────→│
  │  TIME_WAIT（等 2MSL）              CLOSED│
```

**为什么是四次而不是三次**：TCP 是**全双工**的，每个方向要单独关闭。客户端发 FIN 只表示「我不发了」，服务端可能还有数据要发，所以服务端的 **ACK 和 FIN 必须分开发**（中间那段时间用来发完剩余数据）。

**TIME_WAIT 等 2MSL 的两个原因**：

1. **确保最后的 ACK 到达服务端** —— 如果 ACK 丢了，服务端会重发 FIN，客户端必须还在 TIME_WAIT 里才能重发 ACK
2. **让旧连接的报文在网络中消失** —— 防止残留报文干扰新连接（新连接可能复用相同的四元组）

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 143. TCP 如何保证可靠传输？🔥

四大机制：

**① 序列号与确认应答** —— 每个字节都有唯一序列号，接收方用 ACK 确认。发送方超时未收到 ACK 就重传。

**② 滑动窗口（流量控制）** —— 窗口大小由**接收方**通过 TCP 头部的窗口字段通告，发送方据此控制发送速率，避免**接收方缓冲区溢出**。

**③ 拥塞控制（四个算法）** —— 注意这是为了避免**网络**拥塞，和流量控制解决的问题不同：

| 算法 | 做什么 |
| --- | --- |
| **慢启动** | 连接初期 cwnd 从 1 个 MSS 开始，每收一个 ACK 翻倍（**指数增长**） |
| **拥塞避免** | cwnd 到达 ssthresh 后，每个 RTT 增加 1 个 MSS（**线性增长**） |
| **快速重传** | 收到 **3 个重复 ACK** 就立即重传丢失的段，不等超时 |
| **快速恢复** | 快速重传后 `ssthresh = cwnd/2`，`cwnd = ssthresh + 3`，直接进拥塞避免 |

**④ 校验和** —— TCP 首部的校验和字段检测传输错误。

**流量控制 vs 拥塞控制**是常见追问：前者由接收方驱动（怕撑死对方），后者由网络状况驱动（怕堵死网络）。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 144. TCP 与 UDP 的区别是什么？各自适用什么场景？

| 特性 | TCP | UDP |
| --- | --- | --- |
| 连接 | 面向连接 | 无连接 |
| 可靠性 | 可靠（确认、重传、排序） | 不可靠 |
| 传输方式 | **字节流** | **数据报** |
| 首部大小 | 20–60 字节 | **8 字节** |
| 流量控制 | 有（滑动窗口） | 无 |
| 拥塞控制 | 有 | 无 |
| 连接模式 | 一对一 | 一对一、一对多、多对多 |

- **TCP** —— 文件传输、网页浏览、邮件，需要可靠传输的
- **UDP** —— 视频流、DNS 查询、实时游戏，实时性优先、能容忍少量丢包的

「字节流 vs 数据报」这一行是后面[第 152 题粘包](#152-什么是-tcp-粘包拆包如何解决-)的根源：UDP 天然有消息边界，TCP 没有。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 145. GET 与 POST 的区别是什么？

| | GET | POST |
| --- | --- | --- |
| 参数位置 | URL 的 Query String | 请求体 |
| 参数长度 | 受 URL 长度限制（**浏览器限制，不是协议限制**） | 无限制 |
| 缓存 | 可被缓存 | 一般不缓存 |
| 幂等性 | **幂等** | 非幂等 |
| 语义 | 只读，不改资源 | 可能修改资源 |
| TCP 包 | 通常 1 个（header 和 data 一起发） | 可能 2 个（先发 header，收到 `100 Continue` 再发 data） |

**幂等性**：同一请求执行多次，效果与执行一次相同。GET 幂等（多次查询结果一致），POST 非幂等（多次创建产生多个资源）。

⚠️ 两个常见误解：

- 「GET 不安全因为参数在 URL 里」—— 这和 GET/POST 无关，HTTPS 下整个请求（含 URL path 和 query）都是加密的；真正的问题是 URL 会被记进**日志、浏览器历史、Referer**
- 「GET 有长度限制是协议规定的」—— **不是**，HTTP 协议没规定 URL 长度上限，是浏览器和服务器各自的实现限制

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 146. HTTP/1.1、HTTP/2、HTTP/3 的主要区别和演进是什么？🔥

**HTTP/1.1**

- **持久连接**（Keep-Alive）：默认复用 TCP 连接
- **管道化**（Pipelining）：可连续发多个请求，但**响应必须按顺序返回** → **队头阻塞**
- 分块传输编码、`Host` 头支持虚拟主机

**HTTP/2**

- **二进制分帧层**：把 HTTP 消息切成更小的帧
- **多路复用**：一个 TCP 连接上并行交错收发多个请求响应 → **解决了 HTTP 层的队头阻塞**
- **头部压缩 HPACK**：静态表 + 动态表 + Huffman 编码
- **服务器推送**、**流优先级**

**HTTP/3**

- 基于 **QUIC**（跑在 UDP 之上）→ **解决了 TCP 层的队头阻塞**
- 内置 **TLS 1.3**，加密默认开启
- **0-RTT 连接建立**：已知服务器时第一个数据包就能带应用数据
- **连接迁移**：用 **Connection ID** 而非四元组标识连接，**网络切换（Wi-Fi ↔ 蜂窝）无需重建连接**

**演进主线是「队头阻塞」被层层消灭**：

```
HTTP/1.1  HTTP 层队头阻塞 ✗   TCP 层队头阻塞 ✗
HTTP/2    HTTP 层队头阻塞 ✓   TCP 层队头阻塞 ✗   ← 一个包丢了，该连接上所有流都卡住
HTTP/3    HTTP 层队头阻塞 ✓   TCP 层队头阻塞 ✓   ← 换掉 TCP 才根治
```

对移动端来说，**连接迁移**是 HTTP/3 最实际的收益——地铁里 Wi-Fi 切蜂窝不用重新握手。

> 现有的 [02-deep-dive.md 第 6 题](02-deep-dive.md#http-协议)讲的就是这条主线的前半段。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 147. HTTP 断点续传的原理是什么？

基于 HTTP/1.1 的**范围请求（Range Request）**。

| 头部 | 作用 |
| --- | --- |
| `Accept-Ranges: bytes` | 服务端声明支持范围请求 |
| `Range: bytes=1024-2047` | 客户端请求指定字节范围 |
| `Content-Range: bytes 1024-2047/10240` | 响应说明这段内容在整个资源中的位置 |
| `If-Range` | 携带 ETag 或 Last-Modified，**条件性**发起范围请求 |

**流程**：

1. 首次请求，服务端返回 `Accept-Ranges: bytes` 和 `ETag`
2. 下载中断，客户端记录已下载字节数和 ETag
3. 恢复时发 `Range: bytes=已下载-` 和 `If-Range: ETag值`
4. ETag **匹配**（资源没变）→ `206 Partial Content`，从断点继续
5. ETag **不匹配**（资源变了）→ `200 OK`，**重新下载**

`If-Range` 是关键：没有它的话，资源在中断期间被替换了，续传会拼出一个损坏的文件。

**大文件分片上传同理**：切成固定大小分片逐片上传，记录进度，中断后从未完成的分片继续，最后合并。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 148. HTTPS 与 HTTP 的区别是什么？🔥

**一句话：`HTTPS = HTTP + TLS`。** HTTPS 本质仍是 HTTP，只是在 HTTP 与 TCP 之间加了一层 TLS/SSL，传输的是加密后的 HTTP 报文。

| | HTTP | HTTPS |
| --- | --- | --- |
| 安全性 | 明文，易窃听/篡改/伪装 | TLS 加密 + 身份认证 + 完整性校验 |
| 协议层次 | HTTP 直接在 TCP 上 | HTTP → TLS → TCP |
| 默认端口 | 80 | 443 |
| 连接建立 | TCP 三次握手后即可发 | 三次握手后**还要 TLS 握手** |
| 性能开销 | 低 | 多了握手和加解密，但 **TLS 1.3 + 会话恢复 + 硬件加速**已把影响降得很低 |
| 证书 | 不需要 | 需要服务端证书，由 CA 信任链验证 |

**解决 HTTP 的三个安全问题**：

1. **机密性** —— 用 AES、ChaCha20 等**对称加密**加密应用数据，抓包也读不出内容
2. **身份认证** —— 通过证书链验证域名、有效期、CA 签名、吊销状态，确认访问的确实是目标站点
3. **完整性** —— 用哈希 / MAC / AEAD 认证标签校验，篡改会在解密或校验时被发现

#### 一次 HTTPS 请求的流程

1. **DNS 解析** → 拿到 IP
2. **TCP 三次握手** → 和 HTTP 相同
3. **TLS 握手** → 核心目标是**参数协商、身份认证、密钥交换**。以 TLS 1.3 的 ECDHE 为例：

   | 步骤 | 内容 |
   | --- | --- |
   | **ClientHello** | 支持的 TLS 版本、密码套件列表、**Client Random**、ECDHE 临时公钥 |
   | **ServerHello** | 选定的版本和套件、**Server Random**、服务端 ECDHE 临时公钥 |
   | **证书认证** | 服务端发证书链，客户端校验过期/域名/CA 签名/吊销状态 |
   | **密钥生成** | 双方各用「自己的 ECDHE 私钥 + 对方的公钥」算出**相同**的 Pre-Master Secret，再结合两个 Random 派生会话密钥。**这个会话密钥从不在网络上传输** |
   | **Finished** | 双方用派生密钥校验握手消息摘要，确认握手未被篡改，切换到加密通信 |

4. **加密传输 HTTP 数据** —— 后续请求响应都用会话密钥**对称加密**

最值得记住的一点：**非对称加密只用来协商密钥，实际数据传输用的是对称加密**——因为非对称加密慢得多。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 149. WebSocket 的握手过程？帧格式？为什么客户端发送的帧必须掩码？🔥

连接建立涉及三层：**TCP 连接 → TLS 握手（wss 才有）→ WebSocket 握手**。

#### 握手（HTTP Upgrade）

1. 客户端发 HTTP GET，带特殊头部：

   ```
   Upgrade: websocket
   Connection: Upgrade
   Sec-WebSocket-Key: <16 字节随机值的 Base64>
   Sec-WebSocket-Version: 13
   ```

2. 服务端返回 **`101 Switching Protocols`**，带 `Sec-WebSocket-Accept`
3. 计算方式：`Base64(SHA1(Sec-WebSocket-Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))`

⚠️ **这个验证机制的目的不是安全性**，而是三件事：确认服务端确实理解 WebSocket 协议；防止 HTTP 缓存代理把握手响应缓存并重放；阻止非 WebSocket 客户端意外建立连接。

#### WebSocket 与 HTTP 的关系

**两者是平级的应用层协议。** WebSocket 只在**握手阶段**「借用」了 HTTP（靠 Upgrade 机制），一旦收到 101，底层 TCP 连接就**不再承载 HTTP 报文**，改为承载 WebSocket 帧。

两者共用 80/443 端口，这让 WebSocket 能穿透大多数防火墙和代理。

#### 帧格式

紧凑的二进制格式，**帧头仅 2–14 字节**（对比 HTTP 头部通常几百字节到几 KB）：

| 字段 | 位数 | 说明 |
| --- | --- | --- |
| **FIN** | 1 | 标记是不是消息的最后一帧 |
| **Opcode** | 4 | `0x1` 文本 / `0x2` 二进制 / `0x8` 关闭 / `0x9` Ping / `0xA` Pong |
| **MASK** | 1 | **客户端 → 服务端必须为 1** |
| **Payload Length** | 7（可扩展到 16 或 64） | 载荷长度 |
| **Masking Key** | 4 字节 | MASK=1 时存在 |

#### 为什么客户端帧必须掩码

防**缓存投毒攻击（Cache Poisoning）**。

恶意网页里的 JS 通过 WebSocket 向目标服务器发精心构造的数据。如果中间有**不理解 WebSocket 协议的 HTTP 代理**，它可能把 WebSocket 帧误认为 HTTP 请求/响应并**缓存**下来。掩码让每次发送的帧在比特层面都不同，代理就无法把它和 HTTP 流量混淆。

```
masked_payload[i] = original_payload[i] XOR masking_key[i % 4]
```

⚠️ **这不是加密**——Masking Key 就在帧里明文传输。纯粹是协议层面的防护。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 150. SSE、WebSocket 与 Streamable HTTP 的区别？各自适用什么场景？

| | SSE | WebSocket | Streamable HTTP |
| --- | --- | --- | --- |
| **定位** | 服务端**单向**推送 | **双向**实时通信 | HTTP 请求/响应 + **按需**流式响应 |
| 协议基础 | 标准 HTTP | 独立协议，经 HTTP Upgrade | 标准 HTTP，复杂场景可升级为 SSE 流 |
| 方向 | 服务端 → 客户端 | 客户端 ↔ 服务端 | 客户端请求为主，服务端可流式返回 |
| 连接模型 | 一个持久 HTTP 连接 | 一个持久 TCP 连接 | 简单请求可短连接，**流式请求才保持** |
| 数据格式 | 纯文本（UTF-8） | 文本 + 二进制 | 普通 JSON 或 `text/event-stream` |
| 自动重连 | **内置**（Last-Event-ID） | 要自己实现 | 可按请求粒度恢复 |
| 代理友好度 | 友好 | 可能要额外配置 | **最友好**，请求可独立路由 |
| 典型场景 | AI 流式输出、通知、实时日志 | 即时通讯、协同编辑、实时游戏 | MCP 工具调用、Agent 流式响应 |

**SSE** 胜在简单：基于普通 HTTP，浏览器原生支持 `EventSource`，**自带断线重连和事件 ID 追踪**，代理友好。代价是单向 + 只支持文本。

**WebSocket** 胜在全双工和二进制支持，实时性强。代价是**自动重连、心跳、鉴权续期、消息确认全都要业务自己实现**。

**Streamable HTTP** 是渐进式设计，MCP 协议用它替代了旧的 HTTP+SSE 方案。核心思想：**简单场景就是普通 HTTP 请求/响应，复杂场景再按需升级为 SSE 流式响应。** 它解决旧方案的四个问题：

- **部署更简单** —— 旧方案要维护 POST 通道 + SSE 推送通道两条，它只暴露一个端点
- **简单请求更轻量** —— 不必为一个普通请求先建 SSE 长连接
- **负载均衡更友好** —— 请求可独立路由，不依赖长连接亲和性
- **恢复更自然** —— 每个请求边界明确，可按请求粒度重试

**选择建议**：只需单向推送 → SSE；需要双向高频交互 → WebSocket；以请求/响应为主、部分需要流式返回 → Streamable HTTP。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 151. DNS 解析的完整流程是怎样的？

1. **本地缓存查找** —— 浏览器 DNS 缓存 → 操作系统 DNS 缓存（**macOS/iOS 用 mDNSResponder**）→ hosts 文件。任一层命中直接返回
2. **查 LocalDNS**（递归查询）—— LocalDNS 自己有缓存就返回
3. **查根 DNS 服务器**（迭代查询）—— 根服务器返回 TLD 服务器地址
4. **查 TLD DNS 服务器** —— `.com` TLD 服务器返回权威 DNS 服务器地址
5. **查权威 DNS 服务器** —— 返回最终 IP
6. **返回并按 TTL 缓存**

**递归 vs 迭代**是常见追问：

| | 谁问谁 | 特点 |
| --- | --- | --- |
| **递归查询** | 客户端 → LocalDNS | 客户端只发一次请求，**DNS 服务器负责追查到底** |
| **迭代查询** | LocalDNS → 根 / TLD / 权威 | DNS 服务器只返回「**下一步去找谁**」 |

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 152. 什么是 DNS 劫持？有哪些防御手段？🔥

攻击者篡改 DNS 解析过程，让域名被解析到错误的 IP。

**常见劫持方式**

| 方式 | 说明 |
| --- | --- |
| **LocalDNS 劫持** | 运营商篡改解析结果，插广告或用自家缓存服务器 |
| **DNS 欺骗** | 监听 DNS 查询报文，抢先伪造响应（**UDP 无身份验证，先到先得**） |
| **路由器 DNS 劫持** | 入侵路由器改 DNS 服务器设置 |
| **hosts 文件篡改** | 恶意软件改本地 hosts |
| **DNS 缓存投毒** | 向 LocalDNS 注入伪造记录，**影响所有用户** |

**防御手段**

| 手段 | 原理 |
| --- | --- |
| **HTTPDNS** | 通过 HTTP/HTTPS 直接拿解析结果，**绕过 LocalDNS**（iOS 推荐） |
| **DoH**（DNS over HTTPS） | DNS 查询封在 HTTPS 里，加密防篡改 |
| **DoT**（DNS over TLS） | 封在 TLS 里（端口 853） |
| **DNSSEC** | DNS 记录数字签名，验证真实性 |
| **证书校验** | HTTPS 证书验证能在应用层发现域名与证书不匹配 |

**iOS 开发的实用组合：HTTPDNS + 证书校验。** 前者绕开运营商 LocalDNS，后者兜底——就算 IP 被换了，证书对不上也连不通。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 153. TCP Socket 通信的完整流程是怎样的？

Socket 是操作系统提供的网络通信 API。TCP Socket 用 `SOCK_STREAM`，**面向连接、可靠、有序、基于字节流**，一个连接用五元组标识：`(协议, 本地IP, 本地端口, 远端IP, 远端端口)`。

**服务端**

| 调用 | 做什么 |
| --- | --- |
| `socket()` | 创建监听 Socket，`socket(AF_INET, SOCK_STREAM, 0)`，返回文件描述符 |
| `bind()` | 绑定固定端口，客户端才找得到。常绑 `INADDR_ANY` 监听所有网卡 |
| `listen()` | 从主动模式切到**被动模式**。内核维护两个队列：**SYN 队列**（半连接，已回 SYN+ACK 等客户端 ACK）和 **Accept 队列**（全连接，三次握手已完成等 `accept()` 取走） |
| `accept()` | 从 Accept 队列取出一个连接，返回**新的已连接 Socket**。队列空时默认阻塞 |
| `send()`/`recv()` | 用 `accept()` 返回的新 Socket 通信，**监听 Socket 本身不传数据** |
| `close()`/`shutdown()` | `close()` 关 fd，无其他引用时触发四次挥手；`shutdown(fd, SHUT_WR)` 可以只关写端做**半关闭** |

**客户端**：`socket()` → `connect()`（内核自动分配临时端口并触发三次握手）→ 握手完成 `connect()` 返回 → `send()`/`recv()` → `close()`。

**四个关键点**：

1. **`accept()` 不负责三次握手** —— 握手由内核在 `connect()` 触发后完成，`accept()` 只是从已完成队列里取
2. **监听 Socket ≠ 已连接 Socket** —— 前者继续收新连接，后者专门和某个客户端通信
3. **TCP 是字节流** —— `send()` 不保证一次写完，`recv()` 不保证一次读到完整消息，见下题
4. **高并发要用 I/O 多路复用** —— 一个监听 Socket + 大量已连接 Socket，用 select/poll/epoll/kqueue 监控，而不是一连接一线程

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 154. 什么是 TCP 粘包/拆包？如何解决？🔥

**根源：TCP 是字节流协议，没有消息边界。**

发送方两次 `send("Hello")`、`send("World")`，接收方一次 `recv()` 可能读到 `"HelloWorld"`（**粘包**），也可能分多次读到 `"Hel"`、`"loWorld"`（**拆包**）。

**产生原因**

- 发送方：**Nagle 算法**把多个小包合并发送
- 接收方：应用读取速度与数据到达速度不同步
- **MSS/MTU 限制**：大消息被 TCP 分成多个段

**解决方案**

| 方案 | 原理 | 例子 |
| --- | --- | --- |
| 固定长度 | 每条消息固定 N 字节，不足补零 | 每条 1024 字节 |
| 分隔符 | 特殊字符标记边界 | HTTP 用 `\r\n\r\n` 分隔头部和正文 |
| **长度前缀** | 头部携带消息体长度 | 前 4 字节为长度，后续为消息体 |
| 自描述协议 | 用有自描述能力的序列化格式 | Protobuf、JSON |

实践中 **长度前缀（TLV 格式）最常用**：先读固定长度的头部解析出消息体长度，再精确读对应字节数。

⚠️ **UDP 没有这个问题**——它是数据报协议，天然保留消息边界（见[第 144 题](#144-tcp-与-udp-的区别是什么各自适用什么场景)）。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 155. 什么是 I/O 多路复用？select / poll / epoll 的区别是什么？

**一个线程同时监控多个 Socket**，哪个有数据可读/可写再去处理，避免「一连接一线程」的高开销。

| 机制 | 最大连接数 | 实现方式 | 复杂度 |
| --- | --- | --- | --- |
| `select` | **1024**（FD_SETSIZE） | 遍历整个 fd 集合 | O(n) |
| `poll` | 无限制 | 遍历整个 fd 数组 | O(n) |
| `epoll` | 无限制 | **事件驱动（回调）** | **O(1)** 就绪事件 |

**epoll 高效的核心**：内核通过回调机制维护**就绪列表**，`epoll_wait()` 只返回有事件的 Socket，**不需要每次遍历全部连接**。

**两种触发模式**

| | LT（水平触发） | ET（边缘触发） |
| --- | --- | --- |
| 何时通知 | 只要缓冲区有数据**每次**都通知 | 仅在**状态变化**时通知一次 |
| 编程 | 简单，不易丢数据 | 复杂，**必须一次读完所有数据** |
| 用途 | 默认选择 | 配合非阻塞 I/O，是 Nginx 等高性能服务器的标准做法 |

📱 **iOS 相关**：macOS/iOS 用的是 **kqueue**，功能与 epoll 类似。RunLoop 底层的 `mach_msg` 等待机制、GCD 的事件源，都建立在这类内核事件通知之上。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 156. REST 与 RPC 的区别是什么？各自适用什么场景？

| | REST | RPC |
| --- | --- | --- |
| **核心抽象** | **资源**（名词）：对资源做 CRUD | **动作**（动词）：调用远程函数 |
| API 风格 | `GET /users/123` | `getUser(123)` |
| 协议 | 基于 HTTP 语义 | 协议无关（HTTP、TCP、UDP） |
| 数据格式 | 通常 JSON/XML（文本） | 二进制（Protobuf）或文本 |
| 耦合度 | 松 | 紧（需知道函数签名） |
| 性能 | 一般 | 高（二进制序列化、长连接复用） |

**选择**：对外公开 API → REST（通用性强，客户端不用特殊 SDK）；内部微服务通信 → RPC（性能高、类型安全、接口定义严格）。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

### 157. gRPC 的核心特性是什么？Protobuf 为什么比 JSON 高效？

**gRPC 核心特性**

- 基于 **HTTP/2**：多路复用、头部压缩、双向流
- **Protocol Buffers**：高效二进制序列化
- **IDL 定义接口**：`.proto` 文件定义服务，自动生成各语言代码
- **四种通信模式**：一元 RPC、服务端流、客户端流、双向流

**Protobuf 比 JSON 高效的四个原因**

| 原因 | 说明 |
| --- | --- |
| **字段编号代替字段名** | `name = 2`，编码时只传数字 `2` 而不是字符串 `"name"` |
| **Varint 编码** | 整数变长编码，小整数占更少字节。值为 1 只占 **1 字节**，而 JSON 的 `"user_id": 1` 占 **14 字节** |
| **二进制格式** | 直接按二进制偏移读，无需文本解析 |
| **体积** | 通常是 JSON 的 **30%~50%** |

同一份用户数据：JSON 约 68 字节，Protobuf 约 30 字节。加上 HTTP/2 的头部压缩和连接复用，gRPC 在微服务间通信性能通常是 REST 的 **2~10 倍**。

→ [原文：计算机网络](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-basics/计算机网络.md)

---

## 十二、架构设计

### 158. 为什么 iOS 中的 MVC 容易变成 Massive View Controller？如何改进？🔥

**根源有两条**：Apple 的 MVC 里 View 和 Model 不能直接通信，所有交互都得经 Controller 中转；而 `UIViewController` **本身**又负责生命周期、View 层级、系统交互、导航、弹窗。

于是实际开发中它很容易同时干这些活：

- 接收用户事件（按钮点击、列表选择、输入变化）
- 管理 UI 布局和状态
- 调网络请求、数据库、缓存
- 处理业务逻辑和数据校验
- Model → View 的转换
- 页面跳转、弹窗、权限申请
- 实现 `UITableViewDataSource` / `Delegate` 和各种自定义 Delegate

**四个后果**：代码难读、逻辑难复用、依赖 UIKit 导致单元测试困难、改一个功能容易影响别的。

**六条改进**

| 做法 | 怎么做 |
| --- | --- |
| **抽 Service 层** | 网络/缓存/数据库访问挪到 `UserService`、`OrderService`、`Repository` |
| **抽 DataSource/Delegate** | 复杂列表把 `UITableViewDataSource` 封成独立对象，VC 只做协调 |
| **抽 View** | 复杂 UI 封成自定义 `UIView`，VC 只调 `configure` 或绑数据 |
| **抽数据转换** | Model → 展示文案/颜色/按钮状态的逻辑放到 ViewModel 或 Presenter 式小对象 |
| **拆子 VC** | 复杂页面拆成多个子模块，容器 VC 负责组合 |
| **导航交给 Router/Coordinator** | 减少 VC 之间直接创建和强依赖 |

**关键认识**：**MVC 本身不是错的，问题是 ViewController 缺少约束时容易变成所有逻辑的容器。** 改进的重点是让它回到**协调者**角色，而不是业务逻辑的承载者。

页面继续复杂下去再考虑演进到 MVP / MVVM / MVI / VIPER。

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 159. MVP 和 MVVM 有什么区别？Presenter 和 ViewModel 分别应该持有哪些对象？🔥

两者都为解决 VC 职责过重，但**通信方式和依赖关系不同**。

#### MVP：核心是 Presenter

View 是**被动**的，只负责展示和事件转发。Presenter 负责业务逻辑、展示逻辑、调用 Model/Service，并**通过协议**调用 View 方法更新 UI。

**引用关系**：

```
ViewController  ──强持有──→  Presenter
Presenter       ──弱持有──→  View 协议          ← 关键：弱引用，否则循环
Presenter       ──强持有──→  Service / Model
Presenter       ──弱持有──→  Router / Coordinator 协议（如果有导航）
```

好处是 Presenter **只依赖协议不依赖具体 View**，可以用 Mock View 做单元测试。缺点是 View 协议容易随页面复杂度膨胀，View 和 Presenter 仍是明确的双向通信，导航逻辑不单独抽离也容易乱。

#### MVVM：核心是 ViewModel

**ViewModel 不持有 View，也不依赖 UIKit。** 它负责状态管理、数据转换、展示逻辑，通过可观察属性/闭包/Combine/RxSwift 向 VC 输出状态。

**引用关系**：

```
ViewController  ──强持有──→  View、ViewModel
ViewModel       ──强持有──→  Service / Model
ViewModel       ──✗ 不持有──  ViewController / View     ← 关键
ViewController  ──绑定观察──→ ViewModel 输出，并把用户事件转发过去
```

#### 对比

| | MVP | MVVM |
| --- | --- | --- |
| 核心对象 | Presenter | ViewModel |
| View 更新方式 | Presenter **调用** View 协议方法 | View **绑定** ViewModel 状态 |
| 是否持有 View | **弱持有** View 协议 | **完全不持有** |
| View 角色 | 更强调 Passive View | 通过绑定响应状态变化 |
| 测试重点 | 测 Presenter 是否调用了正确的 View 方法 | 测 ViewModel 的输入输出和状态变化 |
| 常见问题 | View 协议膨胀、导航归属不清 | 绑定复杂、ViewModel 膨胀、内存管理 |

**选择**：想要明确的命令式 UI 更新、团队不想引入响应式绑定 → MVP；状态驱动 UI、团队有 SwiftUI 或响应式经验 → MVVM。

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 160. MVVM 相比 MVC 的优势是什么？

核心是**把展示逻辑、状态管理、数据转换从 VC 里抽出来**，让 VC 回到轻量的页面协调者角色。

**分工**：

- **View/ViewController** —— UI 展示、生命周期、View 层级、建立绑定、转发用户事件
- **ViewModel** —— 展示逻辑、状态管理、输入输出转换、调 Model/Service 取数据
- **Model/Service** —— Model 是业务数据结构，Service 负责网络/缓存/数据库和业务规则

**六个优势**

1. **减轻 VC 职责** —— VC 只负责绑定、转发和 UIKit 生命周期
2. **提高可测试性** —— ViewModel 通常不依赖 UIKit，可以直接构造 Mock Service 测。比如「邮箱和密码合法时登录按钮是否可用」不需要启动真实页面
3. **展示逻辑更易复用** —— 格式化文案、按钮状态、空页面判断、错误提示映射封装在 ViewModel 里，同一套输出可被 UIKit 页面、SwiftUI 页面复用
4. **更适合状态驱动 UI** —— ViewModel 暴露 `isLoading`、`users`、`errorMessage`、`isLoginEnabled` 等可观察状态，减少「某个分支忘了刷 UI」「loading 和 error 同时出现」的问题
5. **View 与 Model 解耦更彻底** —— `firstName + lastName`、日期格式化、价格展示都由 ViewModel 统一产出，View 不关心原始 Model 结构
6. **更适配响应式和 SwiftUI** —— 天然契合 Combine、RxSwift、`ObservableObject`、`@Published`、`@Observable`

⚠️ **但 MVVM 不是免费的**：简单页面用它会增加不必要的 ViewModel 和绑定代码；复杂页面把所有业务规则塞进 ViewModel 就变成 **Massive ViewModel**——只是把 MVC 的问题平移了。

继续拆分的方向：复杂业务规则下沉到 Service/UseCase/Domain 层；数据访问放 Repository；复杂导航交给 Coordinator（MVVM-C）；状态特别复杂时演进到 MVI 或 TCA。

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 161. MVI 相比 MVVM 解决了什么问题？Reducer 为什么要设计成纯函数？🔥

MVI 是**单向数据流**架构：

```
View → Intent/Action → Store → Reducer → State → View
```

界面由**一个完整的 State** 描述，用户操作、生命周期事件、网络结果都建模成 Action。所有状态变化都进 Reducer，由它根据「当前 State + Action」算出新 State，View 再按新 State 重新渲染。

**解决 MVVM 的三个问题**

| 问题 | MVVM 的毛病 | MVI 怎么解 |
| --- | --- | --- |
| **状态一致性** | ViewModel 有多个独立属性（`users`、`isLoading`、`error`、`selectedIndex`），在不同方法里被改，入口一多就容易漏。比如重试时设了 `isLoading = true` 却忘了清上次的 `error` | 状态集中到**一个 State 对象**，在 Reducer 里统一处理转换 |
| **变化难追踪** | 状态可能从 ViewModel 任意方法被改 | 所有变化必须通过 Action 进 Reducer，于是能记录「**哪个 Action 让 State 从 A 变成 B**」，支持日志、调试、时间旅行 |
| **副作用分散** | 网络、数据库、定时器散落在各方法里 | Reducer **只做状态计算**，副作用放 Store 或 Effect 层，完成后再发新 Action 回 Reducer |

**Reducer 为什么必须是纯函数**

纯函数意味着：输入相同的 `State + Action`，输出一定相同；不发网络、不读写数据库、不改全局变量、不操作 UI、不依赖当前时间和随机数。

**这是 MVI 可预测和可测试的关键**——测 Reducer 不需要 Mock 网络或 UIKit，只要构造旧 State 和 Action，断言新 State 是否符合预期。

Swift 里通常用 `struct State` 配值语义：

```swift
var newState = state
newState.isLoading = true
return newState
```

虽然属性是 `var`，但 `struct` 是值类型，语义上仍是「旧 State 生成新 State」，不会改到外部持有的旧 State。

⚠️ **要避免**：用 `class` 做 State，或用 `inout` 直接改外部状态——那样会破坏可追溯性。

**代价**：样板代码更多，State、Action、Reducer 都要显式定义。简单页面属于过度设计；但对**复杂状态、多入口、多异步副作用**的页面收益明显。

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 162. TCA 和普通 MVI 有什么关系？TCA 的各个概念分别是什么？

**TCA（The Composable Architecture）可以理解为 Swift 生态里对 MVI/Redux/Elm 思想的成熟实现。** 同样基于单向数据流，但提供了更完整的工程化能力：Effect 系统、依赖注入、Feature 组合、导航状态管理、TestStore。

**七个核心概念**

| 概念 | 是什么 |
| --- | --- |
| **State** | 描述某 Feature 当前所需的**全部**状态，通常是值类型结构体。应**尽量最小化**，只保留渲染 UI 和驱动业务必要的数据 |
| **Action** | 枚举，描述所有可能发生的事件。命名应描述「**发生了什么**」，如 `loginButtonTapped`、`userResponse` |
| **Reducer** | 接收 State 和 Action，**同步**更新 State，并返回 Effect。业务逻辑的核心位置 |
| **Store** | 持有 State，接收 View 发的 Action，驱动 Reducer，把 State 变化通知 View |
| **Effect** | 封装异步操作和副作用（网络、定时器、文件）。完成后可以继续发 Action 回 Reducer |
| **Dependency** | 内置依赖注入，把网络、数据库、UUID、日期等外部依赖替换成生产/测试/预览实现 |
| **Scope** | 把父 Feature 的一部分 State 和 Action 映射成子 Feature 的 Store，实现**组合** |

**一次典型数据流**：`store.send(.buttonTapped)` → Store 交给 Reducer → Reducer 同步改 State → State 变化驱动 View 重渲染 → Reducer 返回的 Effect 被 Store 执行 → Effect 完成后发新 Action，再次进 Reducer。

**相比手写 MVI 的五个优势**

1. **组合能力强** —— `Scope` 组合固定子 Feature，`forEach` 组合列表项，`ifLet` 组合可选子 Feature
2. **副作用标准化** —— Effect 支持异步、合并、串联、**取消**，适合搜索防抖、轮询、长连接
3. **依赖注入完善** —— `@Dependency` 替换外部依赖，测试时显式注入 Mock
4. **测试能力强** —— TestStore 可断言发送 Action 后 State 如何变化、Effect 会回传什么 Action，支持**穷尽式测试**
5. **SwiftUI/UIKit 都能用** —— Reducer 层与 UI 框架无关

**缺点也很明确**：学习曲线高，代码风格和普通 UIKit/MVVM 差异大，简单页面显得重，团队需要统一理解。

**TCA 不是 MVVM 的简单替代品，而是一套强约束的状态管理和模块组合框架**，适合状态复杂、测试要求高、Feature 需要组合的大中型项目。

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 163. VIPER 每一层的职责是什么？适合什么场景，缺点是什么？

五层：View、Interactor、Presenter、Entity、Router。核心目标是**单一职责和高可测试性**。

| 层 | 职责 |
| --- | --- |
| **View** | UI 展示，接收用户输入转发给 Presenter。通常由 `UIViewController` 实现 View 协议 |
| **Presenter** | 展示逻辑。接 View 事件 → 调 Interactor → 把 Entity 转成 ViewModel → 调 View 协议更新 UI |
| **Interactor** | 业务逻辑和数据获取，**完全不知道 UI 存在** |
| **Entity** | 纯数据模型，不含 UI 逻辑 |
| **Router** | 模块组装和页面导航 |

**数据流**：View 触发事件 → Presenter → Interactor → Service 取数据回调 Presenter → Presenter 转成 ViewModel → 调 View 协议更新 UI →（需跳转时）Presenter 调 Router。

**适合**：

- 金融、交易、医疗等业务复杂且测试要求高的模块
- 团队规模大，需要多人并行开发同一模块的不同层
- 模块生命周期长，**后续维护成本比初始开发速度更重要**
- 页面逻辑、业务逻辑、导航逻辑都复杂，需要清晰边界

**缺点是代码量大**：一个简单页面也要创建多个协议和类，样板代码明显增加；模块间通信要通过 Router/Delegate/闭包设计清楚，否则很繁琐。**对简单页面用 VIPER 通常是过度设计。**

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 164. iOS 组件化中常见的组件通信方案有哪些？🔥

**目标**：让业务组件之间不直接依赖。首页组件不该直接 `import UserModule` 再创建 `UserProfileViewController`——否则用户组件一改就影响首页组件编译，模块边界也没了。

#### ① URL Router

通过 URL 注册和打开页面或服务，如 `user://profile?id=123`。

**原理**：维护一张**路由表**，Key 是 URL Pattern，Value 是 Handler 闭包或页面工厂。组件启动时注册自己能处理的 URL；调用方把 URL 交给 Router，Router 解析 scheme/host/path/query，匹配 Pattern 执行 Handler。**调用方只依赖 Router。**

- ✅ 简单直观、支持跨 App 跳转、适合服务端下发动态路由
- ❌ **参数依赖字符串，类型不安全**，复杂对象传递不优雅，URL 维护成本高
- 适合：页面跳转、H5 与 Native 统一路由、动态化跳转

#### ② Target-Action

通过 Runtime 根据字符串找目标类和方法，代表是 CTMediator。

**原理**：约定目标组件暴露固定命名的 Target 类和 Action 方法，如 `Target_User` 类实现 `Action_profileWithParams:`。调用方传 `target = "User"`、`action = "profile"` 和参数字典，Mediator 内部拼类名方法名，用 `NSClassFromString`、`NSSelectorFromString`、`perform` 动态调用。通常还会给 Mediator 写 Category 把字符串调用包装成有明确方法名的 API。

- ✅ **无需启动时注册**，编译期无直接依赖
- ❌ 依赖字符串和 Runtime，**Swift 纯项目需额外处理**（见[第 107 题](#107-nsclassfromstring-在什么场景下使用有什么注意事项)的模块名前缀问题），运行时才发现错误
- 适合：希望减少注册成本、以 ObjC 兼容为基础的项目

#### ③ Protocol-Class

定义独立的**协议层** + **服务容器**。

**原理**：协议层只放对外接口（`UserRouterProtocol`、`UserServiceProtocol`），调用方依赖这些协议；用户组件内部提供 `UserRouterImpl`，启动时把 `UserRouterProtocol → UserRouterImpl` 注册到容器。调用方通过 `getService(UserRouterProtocol.self)` 取出实例。**编译期依赖的是抽象协议，不是具体业务组件。**

- ✅ **类型安全**、接口清晰、便于 Mock 测试
- ❌ 需维护独立 Protocol 组件，服务需显式注册，协议变更影响多个组件
- 适合：中大型项目、重视类型安全和测试

#### ④ DI（依赖注入）

Protocol-Class 的增强版。不仅按协议解析实现，还能**自动构建依赖树**并管理生命周期（单例、瞬态、作用域）。

**原理**：对象创建权交给 DI 容器。各模块注册「协议 → 实现、如何构造、生命周期」。需要 `UserServiceProtocol` 时不自己 new，由容器解析注入；如果 `UserServiceImpl` 又依赖 `UserRepositoryProtocol`，后者又依赖 `NetworkServiceProtocol`，**容器会递归解析整条依赖链**。

- ✅ 依赖关系清晰、测试替换 Mock 方便、复杂依赖链好维护
- ❌ 学习和配置成本高，**过度使用会让依赖来源变得不直观**
- 适合：依赖复杂、需要生命周期管理、测试体系成熟的大型项目

**四者递进关系**：URL Router（最松散、最动态）→ Target-Action（免注册）→ Protocol-Class（类型安全）→ DI（自动依赖树）。

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)

### 165. 如何从 0 到 1 实现 APM 系统？🔥

> 这是本章篇幅最大的一题，源仓库给了非常完整的方案。这里保留主干和关键决策点，细节（ClickHouse 表结构、完整 JSON schema、mermaid 架构图）请看原文。

#### 整体形态

```
C 端 iOS SDK              服务端数据平台              B 端治理平台
低开销采集真实现场    →    接入/清洗/聚合/存储/    →    发现/定位/分发/
                          符号化/告警/配置下发         修复/验证/防劣化
```

#### 第一步：定义指标体系

**核心原则：不能只看平均值**，要按 P50/P90/P99 × 版本/机型/OS/网络/地域/渠道/页面/业务模块切分。

| 维度 | 指标 |
| --- | --- |
| 稳定性 | Crash Rate、Watchdog Rate、FOOM Rate、总异常退出率 |
| 流畅性 | FPS、掉帧率、卡顿率、Freeze 率 |
| 启动 | 冷/温/热启动、首屏、TTI |
| 网络 | DNS、TCP、TLS、TTFB、总耗时、错误率、慢请求率、流量 |
| 页面体验 | 加载 P90、秒开率、首屏、白屏率 |
| 资源 | 内存峰值、CPU、磁盘 IO、电量、热状态 |

面向管理层的汇总口径：

```
Abnormal Exit Rate = Crash Rate + Watchdog Rate + FOOM Rate
Crash-free Users   = 1 - crashed_users / active_users
Slow Resource Rate = slow_resource_count / total_resource_count
View Blank Rate    = blank_view_count / total_view_count
```

#### 第二步：设计 C 端 SDK

SDK 和业务 App **共进程**，所以原则是：低开销、可控制、可降级、可追责、可合规。**架构上必须插件化，而不是一个巨大单例**：

```swift
protocol APMPlugin {
    var name: String { get }
    var defaultEnabled: Bool { get }
    func start(context: APMContext, config: APMPluginConfig)
    func stop()
    func update(config: APMPluginConfig)
}
```

分层：SDK Core（初始化、生命周期、远程配置、插件调度、自监控）/ Context Manager（各类 ID）/ Event Processor（标准化、脱敏、采样、去重、优先级）/ Local Store（分级落盘）/ Uploader（批量、压缩、加密、重试、幂等、熔断）。

⚠️ **初始化要拆成两阶段**：Crash handler、上次运行状态、最小上下文、本地配置**尽早**启动；FPS、网络 hook、历史包扫描、批量上报、MemoryGraph 这类有开销的放到**首帧后或空闲时**。

**SDK 自己也要被监控**：初始化耗时、队列大小、丢弃数、上报失败率、禁用插件列表、SDK 自身 Crash 率。

#### 第三步：核心采集能力

**Crash** —— 同时覆盖 Mach Exception、Unix Signal、NSException / C++ terminate。崩溃现场**只能做 async-signal-safe 的最小写入**：不能 `malloc`、不能调 ObjC/Swift、不能发网络、不能符号化，**下次启动再转成标准事件上报**。

```c
void crash_handler(int sig, siginfo_t *info, void *ucontext) {
    static char buffer[65536];
    int fd = open("/path/to/apm_crash.log", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    write_header(fd, buffer, sig, info);
    write_thread_states(fd);
    write_backtraces(fd);
    write_image_infos(fd);
    fsync(fd); close(fd);
    raise(sig);
}
```

⚠️ Mach 端口注册时**要保存旧 handler 并转发**，否则会破坏 Bugly、Sentry 等其它 SDK。详见[第 168–169 题](#168-mach-异常和-unix-信号有什么关系为什么崩溃-sdk-通常两者都捕获-)。

**Watchdog / 卡死** —— 不能只抓一次堆栈。RunLoop Observer + 子线程 Ping 检测主线程长时间停在 `beforeSources` 或 `afterWaiting`，触发后**每 500ms 多次采样**主线程栈，并记录线程状态、CPU、最近页面、最近操作、网络和磁盘现场。服务端聚合多次采样找出现频率最高或阻塞最长的关键帧。死锁场景可以扫描等待锁的线程，解析锁 owner tid，**构建「等待 → 持有」有向图找环**（呼应[第 91 题](#91-死锁如何治理)）。

**FOOM** —— 系统没有回调，只能**排除法**。每次启动保存上次运行状态，下次启动时判断：

```swift
func suspectedFOOM(last: LastState, current: LastState) -> Bool {
    if last.didCrash || last.didExitNormally { return false }
    if last.appVersion != current.appVersion { return false }   // 排除升级
    if last.osVersion  != current.osVersion  { return false }   // 排除系统重启
    if last.batteryLevel < 0.02 { return false }                // 排除电量耗尽
    return last.isForeground                                     // 必须在前台
}
```

FOOM 详情**没有崩溃栈**，所以必须保存内存水位、页面路径、大对象 TopN、机型内存档位和 MetricKit memory diagnostics。

**卡顿/FPS** —— 见[第 73 题](#73-如何检测-ios-应用的卡顿有哪些检测方案-)。⚠️ ProMotion 机型要注意自适应刷新率，**静止页面低 FPS 不一定是卡顿**，要区分 FPS、掉帧、单帧耗时和滚动场景。

**网络** —— 优先用 `URLSessionTaskMetrics` 拿 DNS/TCP/TLS/TTFB/download/total 分段耗时。要拦截内容可用 `NSURLProtocol`（注意防重复拦截）。WKWebView 走独立 WebContent 进程，需要**注入 JS SDK** 采集 Navigation Timing、Resource Timing、Paint、Long Task。

**MetricKit** —— 必接，作为低开销系统基线。但它**缺少业务上下文，不能替代实时 SDK**。

#### 第四步：统一 RUM 数据模型

**别让 Crash、网络、页面、卡顿各自孤立上报**，要用 RUM 把用户链路串起来：

```
Application → Release/Build/Env → User/Device → Session → View
                                                            ├─ Action
                                                            ├─ Resource
                                                            ├─ Error
                                                            ├─ LongTask/Freeze
                                                            └─ Custom Event
```

所有事件用统一 envelope，payload 按类型扩展。三个关键字段：`event_id` 用于**幂等去重**（重试时不能变）、`event_time` 是端侧时间（服务端另写 `receive_time`）、`schema_version` 支撑长期演进。

**上报按数据价值分级**：

| 级别 | 内容 | 策略 |
| --- | --- | --- |
| Critical | Crash、Watchdog、FOOM | 尽量全量、可靠落盘 |
| Important | 网络错误、慢请求、核心页面性能 | 较高采样 |
| Sampled | 普通 FPS、CPU、资源请求 | 低采样 |
| Debug | MemoryGraph、Coredump、Zombie | 只灰度或触发式开启 |

⚠️ **采样必须按设备或用户 hash 稳定采样**，不能每条事件随机——否则一个用户的页面、网络、错误会被切碎，B 端还原不出用户故事：

```swift
func sampled(deviceId: String, key: String, rate: Double, day: String) -> Bool {
    let seed = "\(deviceId)-\(key)-\(day)"
    let hash = UInt64(seed.hashValue.magnitude)
    return Double(hash % 10_000) / 10_000.0 < rate
}
```

上传用 protobuf + gzip/zstd + HTTPS。失败重试用**指数退避 + jitter**；4xx schema 错误不重试，401/403 刷新配置或停传，413 拆包，429 遵守 `Retry-After`，5xx 重试。

⚠️ **APM 自身的请求、文件和线程都要打白名单**，防止网络/磁盘/CPU 监控产生**回环**。

#### 第五步：服务端数据平台

**接入网关只做轻逻辑**：鉴权、限流、解压解密、Schema 校验、大小限制、租户隔离、时间校正、快速 ACK，然后写 Kafka/Pulsar。

**清洗层**：decode、PII 脱敏、normalize、维度补全、去重、路由。维度补全包括 IP→地域运营商、机型→性能档位、版本→Git commit 和灰度批次、URL→path template 和接口 owner、栈帧→模块和团队。

**存储不能只靠 MySQL**：

| 数据 | 选型 |
| --- | --- |
| 明细事件、多维聚合 | ClickHouse / Doris |
| 指标时序 | TSDB |
| 堆栈和错误文本 | Elasticsearch / OpenSearch |
| dSYM、原始包、MemoryGraph、Coredump | 对象存储 |
| 项目配置、权限、Issue 元数据 | PostgreSQL / MySQL |
| 热点缓存、限流 | Redis |

**符号化服务**：CI 自动上传 dSYM、BCSymbolMap 和源码版本，按 `release + build + UUID` 绑定。客户端上报 image UUID、slide、PC address、architecture、OS version，服务端用 `atos` 或 `llvm-symbolizer` 符号化，支持 Swift demangle、系统符号库和**历史重符号化**。**没有 dSYM 的 Crash 平台只能统计，不能定位。**

**Issue 聚合是治理的最小单元**。平台不该把每条 Crash 都丢给研发，而要按 fingerprint 聚成 Issue：

| Issue 类型 | fingerprint 怎么算 |
| --- | --- |
| Crash | 异常类型 + signal + 崩溃线程标记 + **前几个 in-app frame** |
| Watchdog | 多次采样的公共栈 + 阻塞类型 |
| 慢接口 | host + path template + status/error |
| FOOM | 页面 + 内存峰值特征 + 机型档位 + 模块特征 |

Issue 还要维护状态、Owner、影响用户、趋势、首现版本、最近版本、样本事件、关联 Session、修复版本、重复/噪声标记。

#### 第六步：B 端治理平台

**B 端不是把数据画成图，而是服务工作流。**

首页只放能代表用户体验和发布风险的指标，且**所有异常项都要能一键下钻**到 Issue/Session/版本/机型/页面/接口。

**Issue 详情页要回答六个问题**：影响多少人、从什么时候开始、在哪些版本机型页面发生、疑似原因是什么、谁负责、修复后是否恢复。

**Session 页**按时间线串起页面、操作、网络、错误和长任务：

```
10:01:02  Session Start  cold_launch
10:01:03  View Home appear
10:01:04  Resource GET /home 340ms 200
10:01:08  Action tap_product
10:01:09  View ProductDetail appear
10:01:10  Resource GET /product/{id} 1.2s 200
10:01:12  LongTask main 680ms
10:01:15  Action tap_buy
10:01:16  Resource POST /order 3.2s 500
10:01:17  Error EXC_BAD_ACCESS
```

**告警要少而准、可行动**。内容必须包含：发生了什么、影响多少用户、从何时开始、影响哪些版本/机型/地区、疑似 Top 维度、Owner、下一步入口。要做同 Issue 合并、静默窗口、升级策略、恢复通知、误报反馈。**不可行动的指标只进报表，不进告警。**

**发布防劣化是 APM 的高价值场景**：灰度阶段用**同时间窗口、同机型、同 OS、同网络、同地域、同渠道**做新旧版本对照，门禁指标包括 Crash-free users、FOOM rate、Watchdog rate、Launch P90、View slow rate、Network error rate、关键路径成功率。显著劣化就暂停放量。

#### 落地路线

| 阶段 | 目标 | 做什么 |
| --- | --- | --- |
| **L1** | 能看到 | MetricKit、Crash、启动、基础网络错误、最小质量大盘 |
| **L2** | 覆盖完整 | Watchdog、FOOM、卡顿、页面耗时、业务 Trace、RUM ID |
| **L3** | 能归因 | 符号化、Issue 聚类、Session 时间线、共性维度、主线程采样、火焰图 |
| **L4** | 能闭环 | Owner、工单、IM、告警、修复版本、灰度验证 |
| **L5** | 能治理 | SLO、发布门禁、自动拦截、质量报表、业务结果关联 |

#### 四个最容易失败的点

1. **指标口径不统一**，只采技术点、没有 RUM 关联 ID → B 端无法还原用户故事
2. **SDK 过重**，Hook、高频采样、写盘、上报把 App 自己拖慢 → 必须远程配置、灰度、熔断、自监控
3. **服务端只存原始日志**，没有实时聚合、符号化、Issue 聚类、多模存储 → 查不快、告不准、无法重放
4. **B 端只有看板**，没有 Owner、告警、工单、修复验证、发布门禁 → 最后没人真正治理

→ [原文：iOS 架构概述](https://github.com/ChaselAn/awesome-ios-interview/blob/master/articles/ios-advanced/architecture/iOS架构概述.md)
