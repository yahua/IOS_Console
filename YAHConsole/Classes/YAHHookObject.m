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
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss:SSS";
    }
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    str = [NSString stringWithFormat:@"%@ %@", dateStr, str];
#ifdef DEBUG
    printf("%s\n", [str UTF8String]);
    [[LDPConsoleManager shareInstance] addWithLog:str];
#else
    [[LDPConsoleManager shareInstance] addWithLog:str];
#endif
}

//函数指针，用来保存原始的函数地址
static int (*orig_printf)(const char * __restrict, ...);

//新的printf函数
int new_printf(const char * name, ...) {
    char outbuf[1024*1024];
    va_list vl;
    va_start(vl, name);
    vsprintf(outbuf, name, vl);
    va_end(vl);
    NSString *str = [[NSString alloc] initWithCString:outbuf encoding:NSUTF8StringEncoding];
    
    //可以添加自己的处理，比如输出到自己的持久化存储系统中
    [[LDPConsoleManager shareInstance] addWithLog:str];
    
#ifdef DEBUG
    return orig_printf([str UTF8String]);
#else
    return 1;
#endif
}

//writev
static ssize_t (*orig_writev)(int a, const struct iovec * v, int v_len);
ssize_t new_writev(int a, const struct iovec *v, int v_len) {
    NSMutableString *string = [NSMutableString string];
    for (int i = 0; i < v_len; i++) {
        char *c = (char *)v[i].iov_base;
        [string appendString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
    }
    ssize_t result = orig_writev(a, v, v_len);
    
    //可以添加自己的处理，比如输出到自己的持久化存储系统中
    [[LDPConsoleManager shareInstance] addWithLog:string];
    
    return result;
}

static char *__chineseChar = {0};
static int __buffIdx = 0;
static NSString *__syncToken = @"token";
static size_t (*orig_fwrite)(const void * __restrict __ptr, size_t __size, size_t __nitems, FILE * __restrict __stream);
size_t new_fwrite(const void * __restrict __ptr, size_t __size, size_t __nitems, FILE * __restrict __stream) {
    
    char *str = (char *)__ptr;
    __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (__syncToken) {
            if (str[0] == '\n' && __chineseChar[0] != '\0') {
                s = [[NSString stringWithCString:__chineseChar encoding:NSUTF8StringEncoding] stringByAppendingString:s];
                __buffIdx = 0;
                __chineseChar = calloc(1, sizeof(char));
            }
        }
        [[LDPConsoleManager shareInstance] addWithLog:s];
    });
    return orig_fwrite(__ptr, __size, __nitems, __stream);
}

static int (*orin___swbuf)(int, FILE *);
int new___swbuf(int c, FILE *p) {
    @synchronized (__syncToken) {
        __chineseChar = realloc(__chineseChar, sizeof(char) * (__buffIdx + 2));
        __chineseChar[__buffIdx] = (char)c;
        __chineseChar[__buffIdx + 1] = '\0';
        __buffIdx++;
    }
    return orin___swbuf(c, p);
}

@implementation YAHHookObject

+ (void)hookPrintMethod {
    
    //nslog
    struct rebinding nslog_rebinding = {"NSLog",redirect_nslog,(void*)&orig_nslog};
    rebind_symbols((struct rebinding[1]){nslog_rebinding}, 1);
    
    //nslog、printf
//    rebind_symbols((struct rebinding[1]){{"printf", new_printf, (void *)&orig_printf}}, 1);
//    
//    //nslog内部调用writev
//    //rebind_symbols((struct rebinding[1]){{"writev", new_writev, (void *)&orig_writev}}, 1);
//    
//    rebind_symbols((struct rebinding[1]){{"__swbuf", new___swbuf, (void *)&orin___swbuf}}, 1);
//    rebind_symbols((struct rebinding[1]){{"fwrite", new_fwrite, (void *)&orig_fwrite}}, 1);
}

@end
