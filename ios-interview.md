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
