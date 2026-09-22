# ios-snippets

[ios-interview.md](../ios-interview.md) 里标了「✅ 实测」的结论，验证代码都在这里。每个文件都能独立编译运行，不依赖 Xcode 工程。

## 怎么跑

```bash
./run-all.sh              # 全部跑一遍
./run-all.sh objc-kvo     # 只跑名字匹配的
```

单独跑：

```bash
clang -fobjc-arc -framework Foundation objc-kvo-internals.m -o /tmp/a && /tmp/a
swift swift-dispatch.swift
```

需要 Xcode 命令行工具（`xcode-select --install`）。本目录的输出均在以下环境实测：

| | |
| --- | --- |
| 机器 | Apple Silicon |
| Swift | 6.2.3（swiftlang-6.2.3.3.21, clang-1700.6.3.2） |
| 目标 | arm64-apple-macosx26.0 |

## 为什么能在 macOS 上验证 iOS 的题

Objective-C runtime（`objc_msgSend`、isa、方法列表、关联对象、weak 表）和 Swift runtime（元数据、见证表、ARC）在 macOS 和 iOS 上是**同一套实现**，所以语言层、Runtime 层、内存层、并发层的结论可以直接在 macOS 上验证。

跑不了的是 UIKit：macOS 只有 AppKit。所以 `UIView`/`CALayer`/Auto Layout/触摸事件/VC 生命周期这些题，笔记里标的是「📖 据文档」而不是「✅ 实测」。

## 文件一览

### Objective-C / Runtime

| 文件 | 验证了什么 |
| --- | --- |
| [objc-isa-metaclass.m](objc-isa-metaclass.m) | 实例/类/元类的 isa 与继承双链，根元类的两个闭环 |
| [objc-tagged-pointer.m](objc-tagged-pointer.m) | 什么会被 tag、编译期常量的例外、retainCount 恒为 LONG_MAX |
| [objc-load-initialize.m](objc-load-initialize.m) | `+load` 顺序；`+initialize` 因继承被调用多次 |
| [objc-msgsend-forwarding.m](objc-msgsend-forwarding.m) | 消息转发三阶段 + `doesNotRecognizeSelector:` 的真实异常 |
| [objc-weak-and-arc.m](objc-weak-and-arc.m) | weak 自动置 nil、野指针、weakSelf/strongSelf、autorelease pool |
| [objc-kvo-internals.m](objc-kvo-internals.m) | `NSKVONotifying_` 子类重写的 4 个方法、isa 偷换与还原 |
| [objc-category-and-ivar.m](objc-category-and-ivar.m) | 分类加不了 ivar、关联对象、"覆盖"其实是插队 |
| [objc-block-internals.m](objc-block-internals.m) | Block 的 isa 与 invoke 字段、三种 Block、`__block` |
| [objc-value-semantics.m](objc-value-semantics.m) | nil/Nil/NULL/NSNull、`[super class]`、copy/mutableCopy 矩阵 |
| [runloop-modes.m](runloop-modes.m) | Observer 看到的完整状态流转、Mode 隔离、Timer 精度 |

### Swift

| 文件 | 验证了什么 |
| --- | --- |
| [swift-dispatch.swift](swift-dispatch.swift) | 四种派发；协议扩展/类扩展是静态派发（附 SIL 佐证） |
| [swift-memory-arc.swift](swift-memory-arc.swift) | 循环引用、weak vs unowned、COW 的缓冲区地址变化 |
| [swift-existential-generic.swift](swift-existential-generic.swift) | `any P` 恒 40 字节；`-O` 下泛型比存在类型快 10x |
| [swift-concurrency.swift](swift-concurrency.swift) | 数据竞争丢计数、actor、`async let` 并行、GCD 死锁条件 |
| [swift-reflection-codable.swift](swift-reflection-codable.swift) | Mirror 的能力边界、Codable 是编译期合成 |

## 两个需要注意的坑

**`swift xxx.swift` 是 `-Onone`。** 任何和性能相关的结论都必须用 `-O` 重新编译再测，否则结论会反过来。最典型的是泛型特化——它是优化器的功能，`-Onone` 下压根不发生：

```
             存在类型    泛型约束    比值
  -O          5.3 ms     0.5 ms    10.31x
  -Onone     30.8 ms    24.2 ms     1.27x
```

**ARC 会悄悄插入 `_Block_copy`。** 想观察 `__NSStackBlock__`，把 block 转成裸结构体指针才行；用 `__unsafe_unretained` 在 ARC 下依然会被 copy 成 `__NSMallocBlock__`。
