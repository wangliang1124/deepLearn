// 一组高频「辨析题」的实测：
//   nil / Nil / NULL / NSNull、[self class] vs [super class]、
//   NSString == vs isEqualToString:、copy vs mutableCopy、static 局部变量
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation objc-value-semantics.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Super : NSObject @end
@implementation Super @end

@interface Sub : Super @end
@implementation Sub
- (void)compare {
    printf("  [self class]      = %s\n", class_getName([self class]));
    printf("  [self superclass] = %s\n", class_getName([self superclass]));
    printf("  [super class]     = %s   <- 仍是 Sub！\n", class_getName([super class]));
    printf("  [super superclass]= %s\n", class_getName([super superclass]));
    printf("  原因：super 只改变「从哪开始找方法」（从 Super 开始），\n");
    printf("       接收者 self 始终没变，-class 返回的是接收者的类。\n");
}
@end

static void counter(const char *label) {
    static int s = 0;   // 静态局部变量：只初始化一次，跨调用保留
    int normal = 0;     // 普通局部变量：每次进来都重新初始化
    s++; normal++;
    printf("  %s  static=%d  普通=%d\n", label, s, normal);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    @autoreleasepool {
        printf("== nil / Nil / NULL / NSNull ==\n");
        printf("  nil    = %p  用于对象指针 (id)\n", (void *)nil);
        printf("  Nil    = %p  用于类对象 (Class)\n", (void *)Nil);
        printf("  NULL   = %p  用于 C 指针\n", (void *)NULL);
        printf("  三者值都是 0，区别只在语义/类型\n");
        printf("  NSNull = %s，是个真实对象，指针 = %p\n",
               class_getName([[NSNull null] class]), (__bridge void *)[NSNull null]);
        NSArray *arr = @[@1, [NSNull null], @3];
        printf("  容器不能装 nil，只能用 NSNull 占位：%s\n", arr.description.UTF8String);
        printf("  [NSNull null] 自身非空：%s\n", [NSNull null] ? "真" : "假");

        printf("\n== 给 nil 发消息不崩溃 ==\n");
        NSString *nilStr = nil;
        printf("  [nil length]        = %lu（返回 0）\n", (unsigned long)[nilStr length]);
        printf("  [nil description]   = %s\n", [nilStr description] ? "非 nil" : "nil");

        printf("\n== [self class] vs [super class] ==\n");
        [[Sub new] compare];

        printf("\n== NSString: == 比指针，isEqualToString: 比内容 ==\n");
        NSString *a = @"hello";
        NSString *b = @"hello";
        NSString *c = [NSString stringWithFormat:@"hel%s", "lo"];
        printf("  a == b                    -> %s  (同一份编译期常量，指针相同)\n", a == b ? "YES" : "NO");
        printf("  a == c                    -> %s  (运行时构造，另一块内存)\n", a == c ? "YES" : "NO");
        printf("  [a isEqualToString:c]     -> %s  (内容相同)\n", [a isEqualToString:c] ? "YES" : "NO");
        printf("  a=%s  c=%s\n", class_getName(object_getClass(a)), class_getName(object_getClass(c)));

        printf("\n== copy / mutableCopy ==\n");
        NSArray        *imm = @[@1, @2];
        NSMutableArray *mut = [@[@1, @2] mutableCopy];

        id r1 = [imm copy];         // 不可变 copy -> 浅拷贝，返回自身
        id r2 = [imm mutableCopy];  // 不可变 mutableCopy -> 新的可变对象
        id r3 = [mut copy];         // 可变 copy -> 新的不可变对象
        id r4 = [mut mutableCopy];  // 可变 mutableCopy -> 新的可变对象

        printf("  [不可变 copy]        新对象? %-3s  类型=%s\n",
               r1 == imm ? "否" : "是", class_getName(object_getClass(r1)));
        printf("  [不可变 mutableCopy] 新对象? %-3s  类型=%s\n",
               r2 == imm ? "否" : "是", class_getName(object_getClass(r2)));
        printf("  [可变   copy]        新对象? %-3s  类型=%s\n",
               r3 == mut ? "否" : "是", class_getName(object_getClass(r3)));
        printf("  [可变   mutableCopy] 新对象? %-3s  类型=%s\n",
               r4 == mut ? "否" : "是", class_getName(object_getClass(r4)));
        printf("  规律：只有「不可变对象 copy」会直接返回自身，其余都产生新对象\n");

        printf("\n  都是浅拷贝——元素本身不复制：\n");
        NSMutableArray *inner = [@[@"x"] mutableCopy];
        NSArray *outer = @[inner];
        NSArray *shallow = [outer copy];
        [inner addObject:@"y"];
        printf("  改了原始元素后，拷贝里也变了：%s\n", [shallow[0] description].UTF8String);

        printf("\n== static 局部变量 vs 普通局部变量 ==\n");
        counter("第 1 次调用");
        counter("第 2 次调用");
        counter("第 3 次调用");
    }
    return 0;
}
