//
//  ViewController.m
//  SJRunLoopExample
//
//  Created by SoulJa on 2018/3/30.
//  Copyright © 2018年 SoulJa. All rights reserved.
//

/**
 该示例演示RunLoop的两种常见使用方式
 1.保持一个线程（非主线程）的长久存活
 2.通过监听RunLoop的休眠和即将被唤醒状态执行操作
 */

#import "ViewController.h"

@interface ViewController () {
    CFRunLoopRef _runLoopRef;
    CFRunLoopObserverRef _beforeWaitingObserver;
    CFRunLoopObserverRef _afterWaitingObserver;
}
@property (strong, nonatomic) NSThread *livingThread;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self performSelector:@selector(doSomeThing) onThread:self.livingThread withObject:nil waitUntilDone:NO];
    
    [self observerRunLoopActive];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        [self performSelector:@selector(doSomeThing) onThread:self.livingThread withObject:nil waitUntilDone:NO];
}

- (void)doSomeThing {
    NSLog(@"Thread is living!");
}

#pragma mark - 保持一个线程（非主线程）的长久存活
- (NSThread *)livingThread {
    static NSThread *livingThread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!livingThread) {
            // 创建线程
            livingThread = [[NSThread alloc] initWithTarget:self selector:@selector(doSomeThingKeepThreadAlive) object:nil];
        }
        [livingThread start];
    });
    return livingThread;
}

- (void)doSomeThingKeepThreadAlive {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"LivingThread"];
        // 获取当前线程
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        // 为runLoop添加source
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        // 运行RunLoop
        [runLoop run];
    }
}

#pragma mark - 通过监听RunLoop的休眠和退出状态执行操作
- (void)observerRunLoopActive {
    _runLoopRef = CFRunLoopGetCurrent();
    CFStringRef runLoopMode = kCFRunLoopDefaultMode;
    // 监听进入休眠状态
    _beforeWaitingObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting, true, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        // 可以执行一些计算操作
        NSLog(@"RunLoop处于即将休眠状态");
    });
    // 监听退出状态
    _afterWaitingObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAfterWaiting, true, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        NSLog(@"RunLoop处于即将被唤醒状态");
    });
    
    CFRunLoopAddObserver(_runLoopRef, _beforeWaitingObserver, runLoopMode);
    CFRunLoopAddObserver(_runLoopRef, _afterWaitingObserver, runLoopMode);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    CFRunLoopRemoveObserver(_runLoopRef, _beforeWaitingObserver, kCFRunLoopDefaultMode);
    CFRunLoopRemoveObserver(_runLoopRef, _afterWaitingObserver, kCFRunLoopDefaultMode);
    CFRelease(_runLoopRef);
}

@end
