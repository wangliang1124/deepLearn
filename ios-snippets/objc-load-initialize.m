// +load 与 +initialize：调用时机、顺序、调用次数
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-load-initialize.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define LOG(fmt, ...) printf("  " fmt "\n", ##__VA_ARGS__)

// ---------- +load ----------
@interface Base : NSObject @end
@interface Child : Base @end
@interface Grandchild : Child @end
@interface Base (Ext) @end
@interface NoLoad : NSObject @end   // 故意不实现 +load / +initialize

@implementation Base
+ (void)load        { LOG("+load       Base"); }
+ (void)initialize  { LOG("+initialize %s （self=%s）", class_getName(self), class_getName(self)); }
@end

@implementation Child
+ (void)load { LOG("+load       Child"); }
// 故意不实现 +initialize —— 会继承父类的
@end

@implementation Grandchild
+ (void)load { LOG("+load       Grandchild"); }
@end

@implementation Base (Ext)
+ (void)load { LOG("+load       Base (Ext) 分类 —— 没有覆盖主类的 +load"); }
@end

@implementation NoLoad
@end

int main(void) {
    @autoreleasepool {
        printf("\n(以上是 main 之前由 dyld 触发的 +load)\n");

        printf("\n== +initialize 是懒的：第一次收到消息才触发 ==\n");
        LOG("即将第一次给 Base 发消息…");
        [Base class];              // [Base class] 本身就是一条消息，会触发 +initialize

        printf("\n== 子类没实现 +initialize 会继承父类的，导致父类的被调用多次 ==\n");
        LOG("即将第一次给 Child 发消息…");
        [Child new];               // Child 没有 +initialize -> 沿继承链找到 Base 的，self 却是 Child
        LOG("即将第一次给 Grandchild 发消息…");
        [Grandchild new];

        printf("\n== 再次发消息不会重复触发 ==\n");
        LOG("再给 Base 发一次消息…（下面应该没有 +initialize 输出）");
        [Base new];

        printf("\n== 没实现 +load 的类，main 之前不会有任何输出 ==\n");
        LOG("NoLoad 直到这里才被碰到：%s", class_getName([NoLoad class]));
    }
    return 0;
}
