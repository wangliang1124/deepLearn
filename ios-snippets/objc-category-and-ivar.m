// 分类能加什么、不能加什么；用关联对象补上「成员变量」
// 以及分类方法覆盖主类方法的真相
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-category-and-ivar.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Person : NSObject
- (void)whoAmI;
@end
@implementation Person
- (void)whoAmI { printf("    主类的实现\n"); }
@end

// 分类：可以加实例方法、类方法、属性声明，不能加实例变量
@interface Person (Nickname)
@property (nonatomic, copy) NSString *nickname;   // 只生成 setter/getter 声明，不生成 ivar
+ (void)classMethodFromCategory;
- (void)whoAmI;                                   // 故意和主类同名
@end

@implementation Person (Nickname)

static const void *kNicknameKey = &kNicknameKey;

- (void)setNickname:(NSString *)nickname {
    objc_setAssociatedObject(self, kNicknameKey, nickname, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)nickname {
    return objc_getAssociatedObject(self, kNicknameKey);
}
+ (void)classMethodFromCategory { printf("    分类加的类方法可以正常调用\n"); }

// 这里就是要演示「分类和主类同名方法」，编译器的警告是预期内的
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)whoAmI { printf("    分类的实现\n"); }
#pragma clang diagnostic pop
@end

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    @autoreleasepool {
        printf("== 分类不能加实例变量 ==\n");
        printf("  Person 的 ivar 列表：\n");
        unsigned int n = 0;
        Ivar *ivars = class_copyIvarList([Person class], &n);
        if (n == 0) printf("      （空）—— @property 在分类里没有生成任何 ivar\n");
        for (unsigned int i = 0; i < n; i++) printf("      %s\n", ivar_getName(ivars[i]));
        free(ivars);
        printf("  原因：ivar 布局在编译期写死在 class_ro_t 里，运行时加载分类时已无法改变\n");
        printf("       （改了会让所有已编译的子类 ivar 偏移全部失效）\n");

        printf("\n== 用关联对象补上「成员变量」==\n");
        Person *p = [Person new];
        p.nickname = @"小明";
        printf("  p.nickname = %s  <- 存在全局 AssociationsManager 哈希表里，不在对象内存布局中\n",
               p.nickname.UTF8String);

        printf("\n== 分类方法「覆盖」主类方法的真相 ==\n");
        printf("  调用 [p whoAmI]：");
        printf("\n");
        [p whoAmI];
        printf("  方法列表里两个实现都还在，分类的被插到了前面：\n");
        unsigned int mc = 0;
        Method *ms = class_copyMethodList([Person class], &mc);
        int idx = 0;
        for (unsigned int i = 0; i < mc; i++) {
            if (method_getName(ms[i]) == @selector(whoAmI))
                printf("      第 %u 个方法是 whoAmI，IMP=%p%s\n", i,
                       method_getImplementation(ms[i]), idx++ == 0 ? "  <- 先找到这个" : "");
        }
        free(ms);
        printf("  所以主类实现并没有被「替换」，只是查找时先命中分类的那个\n");

        printf("\n== 分类加的类方法 ==\n");
        [Person classMethodFromCategory];
    }
    return 0;
}
