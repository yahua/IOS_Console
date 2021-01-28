//
//  LDPConsoleModel.m
//  UPWEARTools
//
//  Created by yahua on 2019/9/29.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "LDPConsoleModel.h"
#import "LDPConsoleManager.h"

@implementation LDPConsoleModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _createDate = [NSDate date];
        _logFileName = [self modelDetailDate];
    }
    return self;
}

- (void)saveLog:(NSString *)log {
    
    dispatch_async([LDPConsoleManager shareInstance].serialQueue, ^{
        
        NSError *error = nil;
        BOOL result = [log writeToFile:self.logFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!result && error) {
            NSLog(@"log保存失败：%@", error);
        }
    });
}

- (void)readLogWithBlock:(void(^)(NSString *log))block {
    
    dispatch_async([LDPConsoleManager shareInstance].serialQueue, ^{
        NSData *data = [[NSData alloc] initWithContentsOfFile:self.logFilePath];
        NSString *readStr =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(readStr);
            }
        });
    });
}

- (BOOL)hasLog {
    
    return [self logSizeByte] > 0;
}

- (unsigned long long)logSizeByte {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:[self logFilePath] traverseLink:YES];
    return [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
}

- (NSString *)logSizeString {
    
    return [NSString stringWithFormat:@"%.2fMB", [self logSizeByte]*1.0/1024/1024];
}

#pragma mark - Private

- (NSString *)logFilePath {
    
    NSString *fileFloder = @"YAH_Logs";
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString * libCachePath = [[paths objectAtIndex:0] stringByAppendingFormat:@"/Caches"];
    NSString *filePath = [libCachePath stringByAppendingPathComponent:fileFloder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        if (result) {
            NSLog(@"log文件夹创建成功");
        }else {
            NSLog(@"log文件夹创建失败");
        }
    }
    filePath = [filePath stringByAppendingPathComponent:self.logFileName];
    return filePath;
}

@end

@implementation LDPConsoleModel (Date)

- (NSString *)modelDate {
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    //    formatter.locale = [NSLocale currentLocale]; // Necessary?
    formatter.dateFormat = @"YYYY-MM-dd";
    return [formatter stringFromDate:_createDate];
}
//精确到秒
- (NSString *)modelDetailDate {
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    //    formatter.locale = [NSLocale currentLocale]; // Necessary?
    formatter.dateFormat = @"YYYY-MM-dd-hh-mm-ss";
    return [formatter stringFromDate:_createDate];
}

@end

