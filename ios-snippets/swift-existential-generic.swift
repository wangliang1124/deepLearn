// 存在类型（any P）vs 泛型约束（some P / <T: P>）：内存布局与性能差异从哪来
//
// 运行：
//   swift swift-existential-generic.swift

import Foundation

func title(_ s: String) { print("\n== \(s) ==") }

protocol Shape {
    func area() -> Double
}

struct Small: Shape {                    // 1 个 Double = 8 字节，能塞进内联缓冲区
    var r: Double
    func area() -> Double { .pi * r * r }
}

struct Large: Shape {                    // 5 个 Double = 40 字节，超过 3 word，必须堆分配
    var a = 0.0, b = 0.0, c = 0.0, d = 0.0, e = 0.0
    func area() -> Double { a + b + c + d + e }
}

// ───────────────────────────────────────────────────────────
title("存在类型容器的固定大小")

print("  MemoryLayout<Small>.size           = \(MemoryLayout<Small>.size) 字节")
print("  MemoryLayout<Large>.size           = \(MemoryLayout<Large>.size) 字节")
print("  MemoryLayout<any Shape>.size       = \(MemoryLayout<any Shape>.size) 字节  <- 恒定")
print("  MemoryLayout<any Shape>.stride     = \(MemoryLayout<any Shape>.stride) 字节")
print("""

  这 \(MemoryLayout<any Shape>.size) 字节 = 5 个 word：
      word 0-2  内联值缓冲区（inline buffer）
      word 3    类型元数据指针（type metadata）
      word 4    协议见证表指针（protocol witness table）

  值 ≤ 3 word 时直接内联存放；超过就在堆上分配，缓冲区只存指针。
  所以 Small(\(MemoryLayout<Small>.size) 字节) 内联，Large(\(MemoryLayout<Large>.size) 字节) 触发堆分配。
""")

// ───────────────────────────────────────────────────────────
title("同一份数据，两种传参方式")

@inline(never) func viaExistential(_ s: any Shape) -> Double { s.area() }
@inline(never) func viaGeneric<T: Shape>(_ s: T)   -> Double { s.area() }

let small = Small(r: 1)
print("  viaExistential(small) = \(viaExistential(small))")
print("  viaGeneric(small)     = \(viaGeneric(small))")
print("""

  区别：
    any Shape   每次调用都要装箱成存在容器，area() 通过见证表间接调用，
                编译器看不到具体类型，无法内联、无法特化。
    <T: Shape>  编译器为每个用到的 T 生成特化版本（-O 下的 generic specialization），
                area() 变成直接调用甚至内联，装箱也消失。
""")

// ───────────────────────────────────────────────────────────
// ⚠️ 这一段务必用 -O 跑，否则结论是反的：
//      swiftc -O swift-existential-generic.swift -o /tmp/eg && /tmp/eg
//   实测（Apple Silicon, Swift 6.2.3, n=300000）：
//      -O      存在类型 5.3 ms / 泛型 0.5 ms  -> 10.31x
//      -Onone  存在类型 30.8 ms / 泛型 24.2 ms -> 1.27x
//   泛型特化是**优化器**的功能，-Onone 下根本不发生，所以 -Onone 的基准测试没有意义。
title("粗略计时（务必用 -O 跑，见上方注释）")

let n = 300_000
var shapes: [any Shape] = []
var smalls: [Small] = []
for i in 0..<n { shapes.append(Small(r: Double(i % 10))); smalls.append(Small(r: Double(i % 10))) }

var t = CFAbsoluteTimeGetCurrent()
var sum1 = 0.0
for s in shapes { sum1 += viaExistential(s) }
let tExist = CFAbsoluteTimeGetCurrent() - t

t = CFAbsoluteTimeGetCurrent()
var sum2 = 0.0
for s in smalls { sum2 += viaGeneric(s) }
let tGeneric = CFAbsoluteTimeGetCurrent() - t

print(String(format: "  存在类型 any Shape : %.1f ms", tExist * 1000))
print(String(format: "  泛型约束 <T: Shape>: %.1f ms", tGeneric * 1000))
print(String(format: "  比值 = %.2fx", tExist / tGeneric))
print("  （校验：两边结果一致 \(abs(sum1 - sum2) < 0.001)）")

// ───────────────────────────────────────────────────────────
title("any / some 的语义差别")

func returnsAny(_ flag: Bool) -> any Shape { flag ? Small(r: 1) : Large() }
func returnsSome(_ flag: Bool) -> some Shape { Small(r: flag ? 1 : 2) }

print("  any Shape  —— 可以在运行时返回不同的具体类型（上面 flag 决定 Small 还是 Large）")
print("  some Shape —— 必须**始终**返回同一个具体类型，只是对调用方隐藏了它")
print("  所以 some 是「反向泛型」：类型由被调用方确定，但仍是编译期单一确定的类型。")
print("  returnsAny(true)  area = \(returnsAny(true).area())")
print("  returnsSome(true) area = \(returnsSome(true).area())")

title("类型擦除包装器的原理：把方法存成闭包")

struct AnyShape: Shape {
    private let _area: () -> Double
    init<T: Shape>(_ s: T) { _area = s.area }   // 捕获具体类型，对外只留函数签名
    func area() -> Double { _area() }
}
let erased = AnyShape(Small(r: 2))
print("  AnyShape(Small(r:2)).area() = \(erased.area())")
print("  MemoryLayout<AnyShape>.size = \(MemoryLayout<AnyShape>.size) 字节（一个闭包 = 2 word）")
print("  这正是标准库 AnySequence / AnyPublisher 的做法。")
