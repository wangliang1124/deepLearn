// 引用计数、weak 自动置 nil、weak vs assign、autorelease pool
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-weak-and-arc.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>

@interface Probe : NSObject
@property (nonatomic, copy) NSString *tag;
@end

@implementation Probe
- (instancetype)initWithTag:(NSString *)t { if (self = [super init]) _tag = [t copy]; return self; }
- (void)dealloc { printf("    [dealloc] %s\n", _tag.UTF8String); }
@end

static long RC(id obj) { return obj ? CFGetRetainCount((__bridge CFTypeRef)obj) : 0; }

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);

    printf("== 引用计数随强引用增减 ==\n");
    @autoreleasepool {
        Probe *p = [[Probe alloc] initWithTag:@"A"];
        printf("  刚创建                 rc=%ld\n", RC(p));
        Probe *strong2 = p;
        printf("  多一个强引用            rc=%ld\n", RC(p));
        __weak Probe *w = p;
        printf("  再加一个 weak           rc=%ld  <- weak 不增加引用计数\n", RC(p));
        (void)strong2; (void)w;
    }

    printf("\n== weak 在对象销毁后自动置 nil ==\n");
    __weak Probe *weakRef = nil;
    @autoreleasepool {
        Probe *p = [[Probe alloc] initWithTag:@"B"];
        weakRef = p;
        printf("  出作用域前 weakRef = %s\n", weakRef ? weakRef.tag.UTF8String : "nil");
    }
    printf("  出作用域后 weakRef = %s  <- runtime 在 dealloc 时清空了 weak 表\n",
           weakRef ? weakRef.tag.UTF8String : "nil");

    printf("\n== assign（unsafe_unretained）不会置 nil，变成野指针 ==\n");
    __unsafe_unretained Probe *unsafeRef = nil;
    @autoreleasepool {
        Probe *p = [[Probe alloc] initWithTag:@"C"];
        unsafeRef = p;
    }
    printf("  出作用域后 unsafeRef 指针 = %p（非 nil，已指向已释放内存）\n", unsafeRef);
    printf("  此处若再 [unsafeRef tag] 就是访问野指针，可能 EXC_BAD_ACCESS\n");

    printf("\n== weakSelf / strongSelf：block 里把弱引用提升为强引用 ==\n");
    __weak Probe *weakP = nil;
    @autoreleasepool {
        Probe *p = [[Probe alloc] initWithTag:@"D"];
        weakP = p;

        void (^onlyWeak)(void) = ^{
            printf("    只用 weakSelf：进入 block 时 %s\n", weakP ? "还活着" : "已经是 nil");
        };
        void (^weakThenStrong)(void) = ^{
            Probe *strongP = weakP;          // 提升
            if (!strongP) { printf("    strongSelf 提升失败，安全退出\n"); return; }
            printf("    strongSelf 提升成功，rc=%ld —— 在 block 执行期间对象不会被释放\n", RC(strongP));
        };
        onlyWeak();
        weakThenStrong();
    }
    printf("  对象已释放后再调用：\n");
    void (^afterDealloc)(void) = ^{
        Probe *strongP = weakP;
        printf("    strongSelf = %s\n", strongP ? "非 nil" : "nil（这就是提升的意义：判空后安全返回）");
    };
    afterDealloc();

    printf("\n== autorelease pool 决定延迟释放的时机 ==\n");
    printf("  进入外层 pool\n");
    @autoreleasepool {
        __weak Probe *wp = nil;
        @autoreleasepool {
            Probe *p = [[Probe alloc] initWithTag:@"E"];
            // 把它放进 autorelease 池：ARC 下用 __autoreleasing 或桥接来构造
            __autoreleasing Probe *auto1 = p;
            wp = auto1;
            printf("  内层 pool 中，对象存活 rc=%ld\n", RC(p));
        }
        printf("  内层 pool 结束后 wp = %s\n", wp ? "仍存活" : "nil（已随 pool drain 释放）");
    }
    printf("  外层 pool 结束\n");

    return 0;
}
