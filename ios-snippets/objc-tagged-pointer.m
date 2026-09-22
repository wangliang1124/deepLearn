// Tagged Pointer：值直接塞在指针里，没有堆对象
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-tagged-pointer.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// arm64 上 Tagged Pointer 的标志位在最高位（bit 63），x86_64 在最低位（bit 0）。
// _objc_isTaggedPointer 是 runtime 内部实现，这里按平台手写等价判断。
static BOOL IsTagged(id obj) {
#if __arm64__
    return ((uintptr_t)obj >> 63) & 1;
#else
    return (uintptr_t)obj & 1;
#endif
}

// 注意：printf 的 %-Ns 按字节数补齐，中文是 3 字节/字，直接用会错位。
// 这里把标签单独一行打，避免对不齐。
static void dump(const char *label, id obj) {
    printf("  %s\n      ptr=0x%016lx  tagged=%-3s class=%s\n",
           label, (unsigned long)obj,
           IsTagged(obj) ? "YES" : "no",
           class_getName(object_getClass(obj)));
}

int main(void) {
    @autoreleasepool {
        printf("== 什么会变成 Tagged Pointer ==\n");
        dump("@1  （编译期字面量）",              @1);
        dump("[NSNumber numberWithInt:1] （运行时构造）", [NSNumber numberWithInt:1]);
        dump("@(arc4random()%100) （运行时求值）", @(arc4random() % 100));
        dump("@1234567890123456789 （编译期字面量，值再大也走常量对象）", @1234567890123456789);
        // 要验证「位宽放不下就不 tag」，必须用运行时构造的大数，绕开编译期常量优化
        long long big = 1234567890123456789LL + (arc4random() % 2);
        dump("numberWithLongLong:~1.2e18 （运行时构造的大数）",
             [NSNumber numberWithLongLong:big]);
        dump("@\"abc\"  （编译期字面量）",          @"abc");

        NSString *shortStr = [NSString stringWithFormat:@"%s", "abc"];
        NSString *longStr  = [NSString stringWithFormat:@"%s", "abcdefghijklmnopqrstuvwxyz"];
        dump("运行时短字符串（3 字符）",  shortStr);
        dump("运行时长字符串（26 字符）", longStr);

        printf("\n== 值相同的 Tagged Pointer 是同一个指针 ==\n");
        NSNumber *a = [NSNumber numberWithInt:42];
        NSNumber *b = [NSNumber numberWithInt:42];
        printf("a == b（指针相等）? %s\n", a == b ? "是" : "否");

        printf("\n== retain / release 对 Tagged Pointer 是空操作 ==\n");
        NSNumber *t = [NSNumber numberWithInt:7];
        printf("tagged 对象 retainCount = %ld（恒为最大值，不走 SideTable）\n",
               (long)CFGetRetainCount((__bridge CFTypeRef)t));

        printf("\n== Tagged Pointer 可以被 weak 引用吗 ==\n");
        __weak NSNumber *w = t;
        printf("  weak 赋值后仍可读：%s\n", w.description.UTF8String);
        printf("  能赋值，但它不是堆对象、没有 dealloc，weak 永远不会被置 nil。\n");
    }
    return 0;
}
