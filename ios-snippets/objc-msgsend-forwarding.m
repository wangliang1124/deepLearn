// objc_msgSend 找不到方法之后：消息转发的三个阶段
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-msgsend-forwarding.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define STAGE(s) printf("  [%s]\n", s)

// ---------- 阶段一：动态方法解析 ----------
@interface Stage1 : NSObject
- (void)dynamicMethod;
@end

static void dynamicMethodIMP(id self, SEL _cmd) {
    printf("    -> 运行时加进来的 IMP 执行了，sel=%s\n", sel_getName(_cmd));
}

@implementation Stage1
- (void)dynamicMethod { }   // 只声明不实现会警告，这里给个空壳，下面用 runtime 替换
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(notImplemented)) {
        STAGE("阶段一 resolveInstanceMethod: 动态加方法");
        class_addMethod(self, sel, (IMP)dynamicMethodIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
@end

// ---------- 阶段二：快速转发（换个对象来处理）----------
@interface Helper : NSObject
- (void)sayHi;
@end
@implementation Helper
- (void)sayHi { printf("    -> Helper 代收了 sayHi\n"); }
@end

@interface Stage2 : NSObject @end
@implementation Stage2
+ (BOOL)resolveInstanceMethod:(SEL)sel { return NO; }   // 阶段一放弃
- (id)forwardingTargetForSelector:(SEL)sel {
    if (sel == @selector(sayHi)) {
        STAGE("阶段二 forwardingTargetForSelector: 转给 Helper");
        return [Helper new];
    }
    return nil;
}
@end

// ---------- 阶段三：完整转发（可改签名、可改参数）----------
@interface Stage3 : NSObject @end
@implementation Stage3
+ (BOOL)resolveInstanceMethod:(SEL)sel { return NO; }
- (id)forwardingTargetForSelector:(SEL)sel { return nil; }
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (sel == @selector(add:to:)) {
        STAGE("阶段三 methodSignatureForSelector: 给出签名");
        return [NSMethodSignature signatureWithObjCTypes:"i@:ii"];
    }
    return [super methodSignatureForSelector:sel];
}
- (void)forwardInvocation:(NSInvocation *)inv {
    STAGE("阶段三 forwardInvocation: 拿到 NSInvocation，可读改参数与返回值");
    int a = 0, b = 0;
    [inv getArgument:&a atIndex:2];   // 0 是 self，1 是 _cmd
    [inv getArgument:&b atIndex:3];
    int sum = a + b;
    printf("    -> 截获参数 a=%d b=%d，手动写回返回值 %d\n", a, b, sum);
    [inv setReturnValue:&sum];
}
@end

// ---------- 兜底：三阶段都不处理 ----------
// 注意：不能重写 doesNotRecognizeSelector: 然后正常返回 —— runtime 断言它绝不返回，
// 那样会直接 SIGTRAP。正确做法是让它照常抛异常，在调用处 @try/@catch 接住。
@interface Unhandled : NSObject @end
@implementation Unhandled
@end

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);   // 不缓冲，崩溃时也不会丢输出
    @autoreleasepool {
        printf("== 阶段一：动态方法解析 ==\n");
        Stage1 *s1 = [Stage1 new];
        ((void (*)(id, SEL))objc_msgSend)(s1, @selector(notImplemented));

        printf("\n== 阶段二：快速转发 ==\n");
        Stage2 *s2 = [Stage2 new];
        ((void (*)(id, SEL))objc_msgSend)(s2, @selector(sayHi));

        printf("\n== 阶段三：完整转发 ==\n");
        Stage3 *s3 = [Stage3 new];
        int r = ((int (*)(id, SEL, int, int))objc_msgSend)(s3, @selector(add:to:), 3, 4);
        printf("    调用方拿到的返回值 = %d\n", r);

        printf("\n== 三个阶段都不接：doesNotRecognizeSelector: 抛异常 ==\n");
        Unhandled *u = [Unhandled new];
        @try {
            ((void (*)(id, SEL))objc_msgSend)(u, @selector(nobodyHandlesThis));
        } @catch (NSException *e) {
            printf("    -> 捕获到 %s\n", e.name.UTF8String);
            printf("    -> %s\n", e.reason.UTF8String);
        }

        printf("\n== respondsToSelector: 只看前两步之前的方法表 ==\n");
        printf("  s2 respondsToSelector:@selector(sayHi) = %s"
               "  <- 转发能跑通，但这里仍是 NO\n",
               [s2 respondsToSelector:@selector(sayHi)] ? "YES" : "NO");
    }
    return 0;
}
