// KVO 的底层：运行时生成 NSKVONotifying_ 子类并偷换 isa
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-kvo-internals.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Account : NSObject
@property (nonatomic, assign) int balance;
@property (nonatomic, assign) int notObserved;
@end
@implementation Account
@end

@interface Watcher : NSObject
@end
@implementation Watcher
- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)obj
                        change:(NSDictionary *)change context:(void *)ctx {
    printf("    [回调] %s: %s -> %s\n", kp.UTF8String,
           [change[NSKeyValueChangeOldKey] description].UTF8String,
           [change[NSKeyValueChangeNewKey] description].UTF8String);
}
@end

static void dumpIdentity(const char *when, Account *a) {
    Class isaCls   = object_getClass(a);    // 真实 isa
    Class claimed  = [a class];             // KVO 子类重写了 -class 来撒谎
    printf("  %s\n", when);
    printf("      object_getClass() = %-28s (真实 isa)\n", class_getName(isaCls));
    printf("      [obj class]       = %-28s (对外宣称)\n", class_getName(claimed));
    IMP setter = class_getMethodImplementation(isaCls, @selector(setBalance:));
    IMP other  = class_getMethodImplementation(isaCls, @selector(setNotObserved:));
    printf("      setBalance: IMP   = %p\n", setter);
    printf("      setNotObserved:   = %p\n", other);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    @autoreleasepool {
        Account *acc = [Account new];
        Watcher *w   = [Watcher new];

        printf("== 添加观察者之前 ==\n");
        dumpIdentity("初始状态：", acc);

        [acc addObserver:w forKeyPath:@"balance"
                 options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                 context:NULL];

        printf("\n== 添加观察者之后 ==\n");
        dumpIdentity("isa 被换成动态子类：", acc);

        printf("\n  动态子类的 superclass = %s  <- 就是原来的类\n",
               class_getName(class_getSuperclass(object_getClass(acc))));

        printf("\n  动态子类重写了哪些方法：\n");
        unsigned int n = 0;
        Method *ms = class_copyMethodList(object_getClass(acc), &n);
        for (unsigned int i = 0; i < n; i++)
            printf("      %s\n", sel_getName(method_getName(ms[i])));
        free(ms);

        printf("\n== 赋值触发回调 ==\n");
        acc.balance = 100;
        acc.balance = 250;

        printf("\n== 没被观察的属性不触发 ==\n");
        acc.notObserved = 999;
        printf("    （无回调输出）\n");

        printf("\n== 直接改成员变量绕过 setter，不触发 KVO ==\n");
        Ivar iv = class_getInstanceVariable([Account class], "_balance");
        *(int *)((__bridge void *)acc + ivar_getOffset(iv)) = 777;
        printf("    balance 已被直接改成 %d，但没有回调\n", acc.balance);

        printf("\n== 手动触发：willChange / didChange ==\n");
        [acc willChangeValueForKey:@"balance"];
        [acc didChangeValueForKey:@"balance"];

        [acc removeObserver:w forKeyPath:@"balance"];
        printf("\n== 移除观察者之后 ==\n");
        dumpIdentity("isa 换回来了：", acc);
    }
    return 0;
}
