// 数据竞争、actor、结构化并发、GCD 死锁
//
// 运行（数据竞争那段需要关优化才容易复现）：
//   swift swift-concurrency.swift
//
// 想看 runtime 直接报错，用 TSan：
//   swiftc -sanitize=thread swift-concurrency.swift -o /tmp/tsan && /tmp/tsan

import Foundation

func title(_ s: String) { print("\n== \(s) ==") }

// ───────────────────────────────────────────────────────────
title("1. 没有保护的共享可变状态 = 数据竞争")

final class UnsafeCounter: @unchecked Sendable {
    var value = 0
    func increment() { value += 1 }          // 读-改-写三步，不是原子的
}

let unsafe = UnsafeCounter()
let iterations = 100_000
DispatchQueue.concurrentPerform(iterations: iterations) { _ in
    unsafe.increment()
}
print("  期望 \(iterations)，实际 \(unsafe.value)")
print("  丢失了 \(iterations - unsafe.value) 次自增" +
      (unsafe.value == iterations ? "（这次恰好没丢，多跑几次就会丢）" : ""))

// ───────────────────────────────────────────────────────────
title("2. 加锁修好")

final class LockedCounter: @unchecked Sendable {
    private var v = 0
    private let lock = NSLock()
    func increment() { lock.lock(); v += 1; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return v }
}
let locked = LockedCounter()
DispatchQueue.concurrentPerform(iterations: iterations) { _ in locked.increment() }
print("  期望 \(iterations)，实际 \(locked.value)")

// ───────────────────────────────────────────────────────────
title("3. actor：把「别忘了加锁」变成编译期保证")

actor SafeCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}

// ───────────────────────────────────────────────────────────
title("4. 结构化并发：async let 并行，作用域结束自动收敛")

func work(_ id: Int, ms: UInt64) async -> Int {
    try? await Task.sleep(nanoseconds: ms * 1_000_000)
    return id
}

let sem = DispatchSemaphore(value: 0)
Task {
    let counter = SafeCounter()
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<1000 { group.addTask { await counter.increment() } }
    }
    print("  actor 计数：期望 1000，实际 \(await counter.value)")

    print("\n  串行 await（累加耗时）：")
    var t = CFAbsoluteTimeGetCurrent()
    let s1 = await work(1, ms: 100)
    let s2 = await work(2, ms: 100)
    let s3 = await work(3, ms: 100)
    print(String(format: "    结果 %d %d %d，耗时 %.0f ms", s1, s2, s3,
                 (CFAbsoluteTimeGetCurrent() - t) * 1000))

    print("\n  async let（并行，取最长那个）：")
    t = CFAbsoluteTimeGetCurrent()
    async let p1 = work(1, ms: 100)
    async let p2 = work(2, ms: 100)
    async let p3 = work(3, ms: 100)
    let r = await (p1, p2, p3)
    print(String(format: "    结果 %d %d %d，耗时 %.0f ms", r.0, r.1, r.2,
                 (CFAbsoluteTimeGetCurrent() - t) * 1000))

    print("\n  任务取消会沿结构向下传播：")
    let parent = Task {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do { try await Task.sleep(nanoseconds: 2_000_000_000) }
                catch { print("    子任务感知到取消并退出") }
            }
        }
    }
    try? await Task.sleep(nanoseconds: 100_000_000)
    parent.cancel()
    _ = await parent.result
    sem.signal()
}
sem.wait()

// ───────────────────────────────────────────────────────────
title("5. GCD 死锁：在串行队列上同步派发回自己")

print("""
  DispatchQueue.main.sync { }            // 在主线程上执行 -> 必死锁
  serialQueue.sync { serialQueue.sync {} } // 同一串行队列嵌套 sync -> 必死锁

  原因：sync 要求「当前线程阻塞等待 block 在目标队列上跑完」，
       而目标队列正被当前线程占用，block 永远排不上 -> 互相等待。

  不会死锁的情况：
       DispatchQueue.main.sync 在**非**主线程调用
       并发队列上嵌套 sync（并发队列不要求串行执行，能另开线程）
""")

let serial = DispatchQueue(label: "demo.serial")
let concurrent = DispatchQueue(label: "demo.concurrent", attributes: .concurrent)

concurrent.sync { concurrent.sync { print("  并发队列嵌套 sync：跑通了，没死锁") } }

serial.async {
    print("  串行队列 async 里再 sync 同一个队列 —— 这就是死锁写法，此处只打印不执行")
}
serial.sync { print("  从外部线程 sync 进串行队列：正常") }

print("\n  提示：想让 runtime 直接把数据竞争报出来，用 ThreadSanitizer：")
print("        swiftc -sanitize=thread swift-concurrency.swift -o /tmp/tsan && /tmp/tsan")
