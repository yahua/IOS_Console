//
//  LDPConsoleManager.m
//  UPWEARTools
//
//  Created by yahua on 2019/9/26.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "LDPConsoleManager.h"
#import "YAHHookObject.h"
#import <UIKit/UIKit.h>

#define kLogKey @"kLogKey"

@interface LDPConsoleManager ()

@property (nonatomic, strong) LDPConsoleModel *logModel;
@property (nonatomic,strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *callbacks;

@end

@implementation LDPConsoleManager

+ (void)open {
    [YAHHookObject hookPrintMethod];
}

+ (instancetype)shareInstance {
    
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[LDPConsoleManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _logs = [NSMutableArray array];
        _logModel = [[LDPConsoleModel alloc] init];
        _callbacks = [NSMutableArray arrayWithCapacity:1];
        self.serialQueue = dispatch_queue_create("yahua.gcd.console.serial_queue",DISPATCH_QUEUE_SERIAL);
        
        [self saveLogModel];
        [self setupNotitication];
    }
    return self;
}

#pragma mark - Public

- (void)cleanCurrentLog {
    
    [self.logs removeAllObjects];
    [self saveLog];
}

- (void)addLogMonitorCallBack:(DPConsoleLogCallBackBlock)callback {
    
    if (!callback) {
        return;
    }
    [_callbacks addObject:callback];
}

- (void)addWithLog:(NSString *)log {
    
    if (!log || log.length==0) {
        return;
    }
    
    if ([NSThread isMainThread]) {
        [self.logs addObject:log];
        for (DPConsoleLogCallBackBlock block in self.callbacks) {
            block(log);
        }
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.logs addObject:log];
            for (DPConsoleLogCallBackBlock block in self.callbacks) {
                block(log);
            }
            
    //        //防止频繁调用
    //        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveLog) object:nil];
    //        [self performSelector:@selector(saveLog) withObject:nil afterDelay:5];
        });
    }
}

- (NSArray<NSArray<LDPConsoleModel *> *> *)historyLogs {
    
    //根据日期区分
    NSMutableDictionary *dicts = [NSMutableDictionary dictionary];
    NSArray<NSDictionary *> *cacheList = [[NSUserDefaults standardUserDefaults] arrayForKey:kLogKey];
    [cacheList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LDPConsoleModel *model = [LDPConsoleModel new];
        model.createDate = [obj objectForKey:@"date"];
        model.logFileName = [obj objectForKey:@"logFileName"];
        NSString *key = [model modelDate];
        NSMutableArray *tmpList = [dicts objectForKey:key];
        if (!tmpList) {
            tmpList = [NSMutableArray arrayWithCapacity:1];
            [dicts setObject:tmpList forKey:key];
        }
        [tmpList insertObject:model atIndex:0];
    }];
    //根据日期拍戏
    NSArray<NSString *> *keys = dicts.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *str1 = (NSString *)obj1;
        NSString *str2 = (NSString *)obj2;
        return [str2 compare:str1];
    }];
    NSMutableArray *sortList = [NSMutableArray arrayWithCapacity:1];
    for (NSString *key in keys) {
        [sortList addObject:[dicts objectForKey:key]];
    }
    
    return [sortList copy];
}

#pragma mark - Notification

- (void)setupNotitication {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
    
}

- (void)removeNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didEnterBackgroundNotification:(NSNotification *)notification {
    
    [self saveLog];
}

- (void)willTerminateNotification:(NSNotification *)notification {
    
    [self saveLog];
}

#pragma mark - Private

- (void)saveLogModel {
    
    dispatch_async(self.serialQueue, ^{
        NSDictionary *dict = @{@"date":self.logModel.createDate,
                               @"logFileName":self.logModel.logFileName};
        NSArray *cacheList = [[NSUserDefaults standardUserDefaults] arrayForKey:kLogKey];
        NSMutableArray *tmpList = [NSMutableArray arrayWithArray:cacheList];
        [tmpList addObject:dict];
        [[NSUserDefaults standardUserDefaults] setObject:[tmpList copy] forKey:kLogKey];
    });
}

- (void)saveLog {
    
    NSString *log = [self.logs componentsJoinedByString:@"\n"];
    [_logModel saveLog:log];
}

@end
