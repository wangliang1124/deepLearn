// 实例对象 / 类对象 / 元类对象的 isa 与继承关系
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-isa-metaclass.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Animal : NSObject
@end
@implementation Animal
@end

@interface Dog : Animal
@end
@implementation Dog
@end

// 元类和它的类**同名**，只打名字根本分不清，必须带上 isMetaClass 标记
static const char *N(Class c) {
    static char buf[8][128];
    static int i = 0;
    if (!c) return "nil";
    i = (i + 1) % 8;
    snprintf(buf[i], sizeof(buf[i]), "%s%s",
             class_getName(c), class_isMetaClass(c) ? " [元类]" : " [类]");
    return buf[i];
}

int main(void) {
    @autoreleasepool {
        Dog *dog = [Dog new];

        // object_getClass() 读的是 isa 字段；[obj class] 对实例返回类、对类返回自身
        Class cls      = object_getClass(dog);   // 实例的 isa -> 类对象
        Class meta     = object_getClass(cls);   // 类的 isa   -> 元类
        Class metaMeta = object_getClass(meta);  // 元类的 isa -> 根元类

        printf("== isa 链 ==\n");
        printf("dog 实例  .isa = %s\n", N(cls));
        printf("Dog 类    .isa = %s\n", N(meta));
        printf("Dog 元类  .isa = %s   <- 所有元类的 isa 都指向根元类\n", N(metaMeta));
        printf("NSObject元类.isa= %s   <- 根元类的 isa 指向自己\n",
               N(object_getClass(object_getClass([NSObject class]))));

        printf("\n== 继承链（类对象）==\n");
        for (Class c = cls; c; c = class_getSuperclass(c)) printf("  %s\n", N(c));

        printf("\n== 继承链（元类）==\n");
        for (Class c = meta; c; c = class_getSuperclass(c)) printf("  %s\n", N(c));

        printf("\n== 两个关键闭环 ==\n");
        Class rootMeta = object_getClass([NSObject class]);
        printf("根元类的 isa 指向自己吗？        %s\n",
               object_getClass(rootMeta) == rootMeta ? "是" : "否");
        printf("根元类的 superclass 是 NSObject？ %s\n",
               class_getSuperclass(rootMeta) == [NSObject class] ? "是" : "否");

        printf("\n== [obj class] vs object_getClass() ==\n");
        printf("[dog class]                  = %s\n", N([dog class]));
        printf("[Dog class]                  = %s   <- 类对象调 class 返回自己，拿不到元类\n", N([Dog class]));
        printf("object_getClass([Dog class]) = %s   <- 这才是元类\n", N(object_getClass([Dog class])));

        printf("\n== 类对象也是对象 ==\n");
        printf("Dog 是 NSObject 的实例吗？ %s\n",
               [Dog isKindOfClass:[NSObject class]] ? "是" : "否");
    }
    return 0;
}
