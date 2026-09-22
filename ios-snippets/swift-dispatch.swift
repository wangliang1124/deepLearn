// Swift 的四种方法派发：直接派发 / 函数表派发 / 见证表派发 / 消息派发
// 重点演示两个最容易踩的坑：协议扩展方法、类扩展方法都是**静态派发**
//
// 运行：
//   swift swift-dispatch.swift

import Foundation

func title(_ s: String) { print("\n== \(s) ==") }

// ───────────────────────────────────────────────────────────
title("坑一：协议扩展里的「非协议要求」方法是静态派发")

protocol Greeter {
    func inProtocol()          // 是协议要求 -> 进见证表 -> 动态派发
}
extension Greeter {
    func inProtocol()    { print("    默认实现 inProtocol()") }
    func onlyInExtension() { print("    默认实现 onlyInExtension()") }   // 不是协议要求！
}

struct EnglishGreeter: Greeter {
    func inProtocol()      { print("    EnglishGreeter.inProtocol()") }
    func onlyInExtension() { print("    EnglishGreeter.onlyInExtension()") }
}

let concrete = EnglishGreeter()
let asProtocol: Greeter = EnglishGreeter()

print("  用具体类型调用（编译期就知道类型，都走自己的实现）：")
concrete.inProtocol()
concrete.onlyInExtension()

print("  用协议类型调用：")
asProtocol.inProtocol()        // 见证表 -> 找到 EnglishGreeter 的实现
asProtocol.onlyInExtension()   // 静态派发 -> 直接调 extension 的默认实现！
print("  ↑ 同一个对象，onlyInExtension() 的结果随「变量的静态类型」而变，")
print("    因为它不在协议要求里，没有见证表条目，编译期就绑死了。")

// ───────────────────────────────────────────────────────────
title("坑二：类扩展里的方法也是静态派发，不能被动态覆盖")

class Base {
    func inClassBody() { print("    Base.inClassBody()") }
}
extension Base {
    func inExtension() { print("    Base.inExtension()") }
}
class Derived: Base {
    override func inClassBody() { print("    Derived.inClassBody()") }
    // 不能写 override func inExtension() —— 编译器报错
    // 只能重新声明一个同名方法，但那是遮蔽（shadow），不是覆盖
}

let obj: Base = Derived()
print("  声明为 Base、实际是 Derived：")
obj.inClassBody()    // 函数表派发 -> Derived 的
obj.inExtension()    // 静态派发 -> Base 的

// ───────────────────────────────────────────────────────────
title("final / @objc dynamic 的影响")

class Dyn: NSObject {
    @objc dynamic func viaObjC() { print("    Dyn.viaObjC()  <- 走 objc_msgSend，可被 swizzle") }
    final func viaFinal()        { print("    Dyn.viaFinal() <- final，直接派发，可被内联") }
    func viaVTable()             { print("    Dyn.viaVTable()<- 函数表派发") }
}
let d = Dyn()
d.viaObjC(); d.viaFinal(); d.viaVTable()

print("""

  归纳：
    值类型（struct/enum）的所有方法        -> 直接派发
    协议「要求」的方法                     -> 见证表派发
    协议扩展里的非要求方法                 -> 直接派发   ← 坑
    类在 class body 里声明的方法           -> 函数表派发
    类扩展里的方法                         -> 直接派发   ← 坑
    标了 final / private 的方法            -> 直接派发
    标了 @objc dynamic 的方法              -> 消息派发（objc_msgSend）
""")

// ───────────────────────────────────────────────────────────
title("用 swiftc -emit-sil 可以直接看出派发方式")
print("""
    swiftc -emit-sil swift-dispatch.swift | grep -E 'class_method|witness_method|function_ref|objc_method'

      function_ref    -> 直接派发
      class_method    -> 函数表派发
      witness_method  -> 见证表派发
      objc_method     -> 消息派发
""")
