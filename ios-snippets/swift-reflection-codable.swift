// 反射：Swift 的 Mirror vs ObjC 的 Runtime 反射；Codable 的合成机制
//
// 运行：
//   swift swift-reflection-codable.swift

import Foundation

func title(_ s: String) { print("\n== \(s) ==") }

// ───────────────────────────────────────────────────────────
title("Swift Mirror：只读，不能改、不能按名字调方法")

struct User {
    let id: Int
    var name: String
    var tags: [String]
    private var secret = "hidden"

    // 有 private 成员时，编译器合成的逐成员 init 也是 private 的，所以手写一个
    init(id: Int, name: String, tags: [String]) {
        self.id = id; self.name = name; self.tags = tags
    }
}

let u = User(id: 7, name: "Ann", tags: ["a", "b"])
let m = Mirror(reflecting: u)

print("  displayStyle = \(m.displayStyle!)")
print("  subjectType  = \(m.subjectType)")
print("  children:")
for c in m.children {
    print("      \(c.label ?? "?")  :  \(type(of: c.value))  =  \(c.value)")
}
print("  注意 private 属性也被列出来了 —— Mirror 看的是内存布局，不受访问控制影响")

print("""

  Mirror 能做什么：遍历存储属性的名字、类型、值（只读）
  Mirror 不能做什么：
      × 修改属性值
      × 按字符串名字调用方法
      × 拿到计算属性（它没有存储，不在布局里）
      × 拿到方法列表
  底层：读编译期写进 __swift5_fieldmd 段的 Field Descriptor（字段名 + 类型 mangled name），
       和运行时的 type metadata 配合算出每个字段的偏移，再从内存里取值。
""")

// 计算属性确实不在里面
struct WithComputed {
    var stored = 1
    var computed: Int { stored * 2 }
}
print("  验证：WithComputed 的 children = \(Mirror(reflecting: WithComputed()).children.map { $0.label ?? "?" })")

// ───────────────────────────────────────────────────────────
title("对比：ObjC 的反射能做到 Swift 做不到的事")

print("""
  ObjC Runtime 提供的是**可写**的反射：
      class_copyIvarList / object_getIvar / object_setIvar   读写成员变量
      class_copyMethodList / class_addMethod / method_exchangeImplementations
      NSClassFromString / NSSelectorFromString + performSelector   按字符串调方法
      class_copyPropertyList                                  读属性
  这也是 OC「字典转模型」能靠 runtime 自动完成的原因：
      遍历 property list -> 用 KVC setValue:forKey: 逐个赋值。

  纯 Swift 类型没有这套能力（没有 objc runtime 元数据），
  所以 Swift 的 JSON 解析走的是**编译期代码生成**（Codable），不是运行时反射。
  给 Swift 类加 @objc / 继承 NSObject 后，才能用回 ObjC 那套。
""")

// ───────────────────────────────────────────────────────────
title("Codable：编译期合成，不是反射")

struct Article: Codable, Equatable {
    let id: Int
    var title: String
    var publishedAt: Date?
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case publishedAt = "published_at"   // 改映射名
        case tags
    }
}

let article = Article(id: 1, title: "Hello", publishedAt: Date(timeIntervalSince1970: 0), tags: ["ios"])

let enc = JSONEncoder()
enc.outputFormatting = [.prettyPrinted, .sortedKeys]
enc.dateEncodingStrategy = .iso8601
let data = try! enc.encode(article)
print("  编码结果：")
print(String(data: data, encoding: .utf8)!.split(separator: "\n").map { "      \($0)" }.joined(separator: "\n"))

let dec = JSONDecoder()
dec.dateDecodingStrategy = .iso8601
let back = try! dec.decode(Article.self, from: data)
print("  解码回来相等？ \(back == article)")

print("""

  机制：编译器在类型满足条件时**自动合成**
      init(from decoder: Decoder) throws
      func encode(to encoder: Encoder) throws
      enum CodingKeys（若未手写）
  合成出来的就是普通 Swift 代码，逐字段调 container.decode(_:forKey:)。
  所以它是零反射、类型安全、可被优化器内联的；代价是不能在运行时动态决定字段。
""")

// ───────────────────────────────────────────────────────────
title("Codable 的常见坑：多出/缺失字段")

let jsonExtra = #"{"id":2,"title":"T","published_at":null,"tags":[],"unknown":123}"#
print("  多出未知字段 -> 忽略，正常解码：\(((try? dec.decode(Article.self, from: Data(jsonExtra.utf8))) != nil))")

let jsonMissingOptional = #"{"id":3,"title":"T","tags":[]}"#
print("  缺失 Optional 字段 -> 正常（变 nil）：\(((try? dec.decode(Article.self, from: Data(jsonMissingOptional.utf8))) != nil))")

let jsonMissingRequired = #"{"title":"T","tags":[]}"#
do {
    _ = try dec.decode(Article.self, from: Data(jsonMissingRequired.utf8))
    print("  缺失非 Optional 字段 -> 居然成功了？")
} catch let DecodingError.keyNotFound(key, _) {
    print("  缺失非 Optional 字段 -> 抛 keyNotFound(\(key.stringValue))，不会静默给默认值")
} catch {
    print("  缺失非 Optional 字段 -> \(error)")
}

let jsonWrongType = #"{"id":"not-a-number","title":"T","tags":[]}"#
do {
    _ = try dec.decode(Article.self, from: Data(jsonWrongType.utf8))
} catch let DecodingError.typeMismatch(type, _) {
    print("  类型不匹配 -> 抛 typeMismatch(期望 \(type))")
} catch {
    print("  类型不匹配 -> \(error)")
}
print("  这是和 OC 字典转模型最大的行为差异：Swift 默认**严格**，OC 那套通常静默失败。")
