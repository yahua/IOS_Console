//
//  YAHHookObject.m
//  fishhook
//
//  Created by yahua on 2019/9/30.
//

#import "YAHHookObject.h"
#import "LDPConsoleManager.h"
#import <fishhook/fishhook.h>

//申明一个函数指针用于保存原NSLog的真实函数地址
static void (*orig_nslog)(NSString *format, ...);
//NSLog重定向
void redirect_nslog(NSString *format, ...) {
    
    va_list vl;
    va_start(vl, format);
    NSString* str = [[NSString alloc] initWithFormat:format arguments:vl];
    va_end(vl);
    orig_nslog(str);
    
    //可以添加自己的处理，比如输出到自己的持久化存储系统中
    NSDateFormatter *formatter = [NSDateFormatter new];
    //    formatter.locale = [NSLocale currentLocale]; // Necessary?
    formatter.dateFormat = @"YYYY-MM-dd hh:mm:ss:SSS";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    NSString *log = [NSString stringWithFormat:@"%@ %@\n",dateStr, str];
    [[LDPConsoleManager shareInstance] addWithLog:log];
}

//函数指针，用来保存原始的函数地址
static int (* old_printf)(const char *, ...);

//新的printf函数
void new_printf(const char * name, ...) {
    char outbuf[1024*1024];
    va_list vl;
    va_start(vl, name);
    vsprintf(outbuf, name, vl);
    va_end(vl);
    NSString *str = [[NSString alloc] initWithCString:outbuf encoding:NSUTF8StringEncoding];
    old_printf([str UTF8String]);
    
    //可以添加自己的处理，比如输出到自己的持久化存储系统中
    [[LDPConsoleManager shareInstance] addWithLog:str];
}

@implementation YAHHookObject

+ (void)hookPrintMethod {
    
    //nslog
    struct rebinding nslog_rebinding = {"NSLog",redirect_nslog,(void*)&orig_nslog};
    rebind_symbols((struct rebinding[1]){nslog_rebinding}, 1);
    
    //printf
    struct rebinding manager;
     //要交换函数的名称
    manager.name = "printf";
     //新的函数地址
    manager.replacement = new_printf;
     //保存原始函数地址变量的指针（存储下来，在替换后的方法里调用）
    manager.replaced = (void *)&old_printf;
     //定义数组
    struct rebinding rebs[] = {manager};
    /*
     交换方法
     arg1: 存放rebinding结构体的数组
     arg2: 数组的长度
     */
    rebind_symbols(rebs, 1);
}

@end
