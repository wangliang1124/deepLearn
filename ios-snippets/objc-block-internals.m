// Block 是对象吗？三种 Block 类型、__block 的捕获与修改
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-block-internals.m -o /tmp/a && /tmp/a
//
// 想看编译器生成的 C 结构体：
//   clang -rewrite-objc objc-block-internals.m -o /tmp/rewrite.cpp   （注意：非 ARC 语义，仅供看结构）

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Block 在运行时的真实结构（摘自 libclosure 的 Block_private.h，简化）
struct BlockLayout {
    void *isa;                 // <- 有 isa，所以 Block 确实是对象
    int   flags;
    int   reserved;
    void *invoke;              // 函数指针：真正的代码在这里
    void *descriptor;
    // 捕获的变量依次排在后面
};

static const char *BlockKind(id blk) { return class_getName(object_getClass(blk)); }

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    @autoreleasepool {
        printf("== Block 是函数指针还是对象？==\n");
        void (^simple)(void) = ^{ printf("hi\n"); };
        struct BlockLayout *layout = (__bridge struct BlockLayout *)simple;
        printf("  Block 的 isa    = %s\n", BlockKind(simple));
        printf("  Block 的 invoke = %p  <- 真正的函数指针在这个字段里\n", layout->invoke);
        printf("  结论：Block 是一个**带有函数指针字段的对象**，不是裸函数指针。\n");
        printf("       它的类继承自 NSBlock，最终继承自 NSObject。\n");
        Class c = object_getClass(simple);
        printf("  继承链：");
        for (; c; c = class_getSuperclass(c)) printf("%s%s", class_getName(c), class_getSuperclass(c) ? " -> " : "\n");

        printf("\n== 三种 Block ==\n");
        // 1) 不捕获任何外部变量 -> 全局 Block，放在数据段
        void (^global)(void) = ^{ printf("nothing captured\n"); };
        printf("  不捕获外部变量        : %s\n", BlockKind(global));

        // 2) 捕获了变量 -> 栈上构造；ARC 下赋给 strong 变量会自动 copy 到堆
        int captured = 42;
        void (^heap)(void) = ^{ printf("%d\n", captured); };
        printf("  捕获变量 + 赋给强引用 : %s  <- ARC 自动 copy 到堆了\n", BlockKind(heap));

        // 3) 想看到 NSStackBlock 没那么容易：ARC 下只要把 block 当作 ObjC 指针
        //    传递/赋值，编译器就会插入 _Block_copy，结果永远是 NSMallocBlock。
        //    实测：__unsafe_unretained 也不行（ARC 在赋值处就 copy 了）。
        //    唯一可靠的观察方式是转成裸结构体指针，绕开 ObjC 指针转换。
        __unsafe_unretained void (^unsafeRef)(void) = ^{ printf("%d\n", captured); };
        printf("  捕获变量 + __unsafe_unretained : %s  <- ARC 下仍被 copy 了\n",
               BlockKind(unsafeRef));

        struct BlockLayout *stackBlk = (__bridge struct BlockLayout *)^{ printf("%d\n", captured); };
        printf("  捕获变量 + 转裸结构体指针      : %s  <- 这才看到栈 Block\n",
               class_getName((__bridge Class)stackBlk->isa));
        printf("\n  NSGlobalBlock : 无外部变量捕获，编译期确定，全局唯一\n"
               "  NSStackBlock  : 捕获了变量且未被 copy，随栈帧销毁（返回它就是悬垂）\n"
               "  NSMallocBlock : 栈 Block 被 copy 到堆，可安全跨作用域持有\n");

        printf("\n== 普通捕获是「值拷贝」，捕获那一刻就定死了 ==\n");
        int normal = 1;
        void (^readOnly)(void) = ^{ printf("    block 里看到 normal = %d\n", normal); };
        normal = 999;
        printf("  block 外把 normal 改成了 %d\n", normal);
        readOnly();
        printf("  -> block 里仍是捕获时的值：编译器把它当 const 值拷进了 block 结构体\n");

        printf("\n== __block 让变量可被修改 ==\n");
        __block int mutable_ = 1;
        void (^writer)(void) = ^{ mutable_ += 100; };
        printf("  调用前 mutable_ = %d\n", mutable_);
        writer();
        printf("  调用后 mutable_ = %d\n", mutable_);
        printf("  原理：__block 变量被包进一个 __Block_byref_ 结构体，\n");
        printf("       block 和外部作用域都通过 __forwarding 指针访问同一份存储。\n");

        printf("\n== 捕获对象：block 会强引用它 ==\n");
        __weak NSObject *weakProbe = nil;
        void (^holder)(void) = nil;
        @autoreleasepool {
            NSObject *o = [NSObject new];
            weakProbe = o;
            holder = ^{ (void)o; };      // block 持有 o
        }
        printf("  出作用域后对象还活着吗？%s  <- 被 block 强引用着\n",
               weakProbe ? "是" : "否");
        holder = nil;
        printf("  block 置 nil 后呢？      %s\n", weakProbe ? "是" : "否");
    }
    return 0;
}
