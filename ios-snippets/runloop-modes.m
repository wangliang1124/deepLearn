// RunLoop：线程绑定、Mode、Observer 看到的完整状态流转、Timer 被 Mode 卡住
//
// 编译运行：
//   clang -fobjc-arc -framework Foundation runloop-modes.m -o /tmp/a && /tmp/a

#import <Foundation/Foundation.h>

static const char *ActivityName(CFRunLoopActivity a) {
    switch (a) {
        case kCFRunLoopEntry:         return "Entry          进入 RunLoop";
        case kCFRunLoopBeforeTimers:  return "BeforeTimers   即将处理 Timer";
        case kCFRunLoopBeforeSources: return "BeforeSources  即将处理 Source0";
        case kCFRunLoopBeforeWaiting: return "BeforeWaiting  即将休眠（这里是卡顿检测的关键点）";
        case kCFRunLoopAfterWaiting:  return "AfterWaiting   刚被唤醒";
        case kCFRunLoopExit:          return "Exit           退出 RunLoop";
        default:                      return "unknown";
    }
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    @autoreleasepool {
        printf("== RunLoop 和线程一一对应 ==\n");
        CFRunLoopRef main1 = CFRunLoopGetMain();
        CFRunLoopRef cur   = CFRunLoopGetCurrent();
        printf("  主线程上 CFRunLoopGetMain() == CFRunLoopGetCurrent()? %s\n",
               main1 == cur ? "是" : "否");

        __block CFRunLoopRef childLoop = NULL;
        NSThread *t = [[NSThread alloc] initWithBlock:^{
            childLoop = CFRunLoopGetCurrent();     // 子线程首次调用时才**懒加载创建**
            printf("  子线程里 CFRunLoopGetCurrent() = %p\n", childLoop);
        }];
        [t start];
        while (!childLoop) { usleep(1000); }
        printf("  主线程的 RunLoop              = %p\n", cur);
        printf("  两者不同 -> 每条线程一个，存在全局字典里，key 是线程\n");
        printf("  注意：子线程的 RunLoop 不会自动跑起来，必须自己 CFRunLoopRun()\n");

        printf("\n== 当前 Mode 与已注册的 Mode ==\n");
        CFStringRef mode = CFRunLoopCopyCurrentMode(cur);
        printf("  当前 Mode : %s\n", mode ? [(__bridge NSString *)mode UTF8String] : "(未运行)");
        if (mode) CFRelease(mode);
        CFArrayRef modes = CFRunLoopCopyAllModes(cur);
        printf("  全部 Mode :\n");
        for (CFIndex i = 0; i < CFArrayGetCount(modes); i++)
            printf("      %s\n", [(__bridge NSString *)CFArrayGetValueAtIndex(modes, i) UTF8String]);
        CFRelease(modes);
        printf("\n  常用的几个：\n");
        printf("      kCFRunLoopDefaultMode   平时\n");
        printf("      UITrackingRunLoopMode   iOS 上滚动时（macOS 这里看不到）\n");
        printf("      kCFRunLoopCommonModes   不是真实 Mode，是个「打了 common 标记的 Mode 集合」\n");

        printf("\n== 用 Observer 看一轮完整的状态流转 ==\n");
        CFRunLoopObserverRef ob = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0,
            ^(CFRunLoopObserverRef o, CFRunLoopActivity activity) {
                printf("    %s\n", ActivityName(activity));
            });
        CFRunLoopAddObserver(cur, ob, kCFRunLoopDefaultMode);

        // 加一个 0.05s 后触发的 timer，让 RunLoop 有事可做
        [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:NO block:^(NSTimer *_){
            printf("    >>> Timer 触发\n");
        }];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.15, false);
        CFRunLoopRemoveObserver(cur, ob, kCFRunLoopDefaultMode);
        CFRelease(ob);
        printf("  BeforeWaiting 到 AfterWaiting 之间线程是真的在 mach_msg_trap 里休眠，\n");
        printf("  不占 CPU。卡顿检测就是盯「BeforeSources/AfterWaiting 之后迟迟不到下一个状态」。\n");

        printf("\n== Timer 只在它所属的 Mode 里生效 ==\n");
        __block int firedInDefault = 0;
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.02 repeats:YES block:^(NSTimer *_){
            firedInDefault++;
        }];
        // 只加到 DefaultMode
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];

        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.12, false);
        printf("  在 DefaultMode 跑 0.12s      -> 触发 %d 次\n", firedInDefault);

        firedInDefault = 0;
        CFRunLoopRunInMode(CFSTR("MyCustomMode"), 0.12, false);
        printf("  切到另一个 Mode 跑 0.12s     -> 触发 %d 次  <- 被 Mode 隔离了\n", firedInDefault);
        printf("  这就是 iOS 上「一滚动 Timer 就停」的原因：滚动切到 UITrackingRunLoopMode。\n");
        printf("  解法：加到 NSRunLoopCommonModes。\n");
        [timer invalidate];

        printf("\n== Timer 是否准时？==\n");
        __block int count = 0;
        __block CFAbsoluteTime first = 0, last = 0;
        NSTimer *t2 = [NSTimer timerWithTimeInterval:0.01 repeats:YES block:^(NSTimer *_){
            if (count == 0) first = CFAbsoluteTimeGetCurrent();
            last = CFAbsoluteTimeGetCurrent();
            count++;
            if (count == 3) usleep(80000);     // 模拟一次耗时任务，阻塞 RunLoop 80ms
        }];
        [[NSRunLoop currentRunLoop] addTimer:t2 forMode:NSDefaultRunLoopMode];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.3, false);
        [t2 invalidate];
        printf("  间隔 10ms、跑 300ms，理论应触发约 30 次，实际 %d 次\n", count);
        printf("  中间有一次 80ms 阻塞，错过的回调被直接丢弃而不是补偿 ——\n");
        printf("  NSTimer 依赖 RunLoop 调度，不是实时的，精度受当前任务影响。\n");
    }
    return 0;
}
