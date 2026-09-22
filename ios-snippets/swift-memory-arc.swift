// Swift 内存：ARC、循环引用、weak vs unowned、Copy-on-Write
//
// 运行：
//   swift swift-memory-arc.swift

import Foundation

func title(_ s: String) { print("\n== \(s) ==") }

// ───────────────────────────────────────────────────────────
title("ARC：引用计数归零即刻销毁（不是等 GC）")

class Node {
    let name: String
    init(_ n: String) { name = n; print("    + init \(n)") }
    deinit { print("    - deinit \(name)") }
}

do {
    let a = Node("A")
    print("    rc(A) = \(CFGetRetainCount(a))")
    let b = a
    print("    多一个强引用后 rc(A) = \(CFGetRetainCount(a))")
    _ = b
    print("    即将离开作用域…")
}
print("    已离开作用域")

// ───────────────────────────────────────────────────────────
title("循环引用：两个 strong 互指，谁都释放不掉")

class Parent { var child: Child?; deinit { print("    - deinit Parent") } }
class Child  { var parent: Parent?; deinit { print("    - deinit Child") } }

do {
    let p = Parent(); let c = Child()
    p.child = c
    c.parent = p          // strong <-> strong
    print("    构造完毕，即将离开作用域（下面应该没有任何 deinit）")
}
print("    离开了——两个对象都泄漏了")

// ───────────────────────────────────────────────────────────
title("用 weak 打破循环")

class Parent2 { var child: Child2?; deinit { print("    - deinit Parent2") } }
class Child2  { weak var parent: Parent2?; deinit { print("    - deinit Child2") } }

do {
    let p = Parent2(); let c = Child2()
    p.child = c; c.parent = p
    print("    构造完毕，即将离开作用域")
}
print("    离开了")

// ───────────────────────────────────────────────────────────
title("weak vs unowned")

class Owner { let name = "owner"; deinit { print("    - deinit Owner") } }

class WeakHolder   { weak    var ref: Owner?; init(_ o: Owner) { ref = o } }
class UnownedHolder { unowned var ref: Owner;  init(_ o: Owner) { ref = o } }

var weakHolder: WeakHolder!
var unownedHolder: UnownedHolder!
do {
    let o = Owner()
    weakHolder    = WeakHolder(o)
    unownedHolder = UnownedHolder(o)
    print("    对象存活时：weak = \(weakHolder.ref == nil ? "nil" : "非 nil")")
}
print("    对象销毁后：weak = \(weakHolder.ref == nil ? "nil（自动置空，安全）" : "非 nil")")
print("    unowned 此时访问会直接崩溃（Fatal error: Attempted to read an")
print("    unowned reference but object 0x… was already deallocated），所以这里不演示。")
print("""
    选择：生命周期可能比自己短 -> weak（Optional，有运行时开销）
         保证不短于自己       -> unowned（非 Optional，更快，但错了就崩）
""")

// ───────────────────────────────────────────────────────────
title("Copy-on-Write：值语义，但不真复制")

var arr1 = [1, 2, 3, 4, 5]
var arr2 = arr1                       // 这里没有复制

func bufferAddress<T>(_ a: [T]) -> String {
    a.withUnsafeBufferPointer { "\($0.baseAddress!)" }
}

print("    arr1 缓冲区 = \(bufferAddress(arr1))")
print("    arr2 缓冲区 = \(bufferAddress(arr2))   <- 和 arr1 相同，还没复制")
arr2.append(6)                        // 写入时才复制
print("    arr2.append(6) 之后：")
print("    arr1 缓冲区 = \(bufferAddress(arr1))")
print("    arr2 缓冲区 = \(bufferAddress(arr2))   <- 变了，此刻才真复制")
print("    arr1 = \(arr1)")
print("    arr2 = \(arr2)")

print("\n    判断依据是 isKnownUniquelyReferenced：")
final class Box { var v = 0 }
var box1 = Box()
print("    唯一引用时 isKnownUniquelyReferenced = \(isKnownUniquelyReferenced(&box1))")
let box2 = box1
print("    多一个引用后                        = \(isKnownUniquelyReferenced(&box1))")
_ = box2

print("""

    自己实现 COW 的骨架：
      struct MyBuffer {
          private var storage: Storage
          mutating func write(_ x: Int) {
              if !isKnownUniquelyReferenced(&storage) { storage = storage.copy() }
              storage.data = x
          }
      }
""")
