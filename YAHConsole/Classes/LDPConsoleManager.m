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

static const NSInteger kDefaultCacheMaxCacheAge = 60*60*24*7; // 1 week

@interface LDPConsoleManager ()

@property (nonatomic, strong) LDPConsoleModel *logModel;
@property (nonatomic,strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *callbacks;

/// 历史log数据
@property (nonatomic, strong) NSArray<NSArray<LDPConsoleModel *> *> *historyLogs;

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
        
        [self setupNotitication];
        
        //清除过期的缓存文件
        [self p_trimRecurrence];
        
        //缓存本次log
        [self saveLogModel];
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

- (void)getHistoryLog:(void(^)(NSArray<NSArray<LDPConsoleModel *> *> *historyLogs))block {
    
    if (!block) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        NSArray *list = self.historyLogs;
        dispatch_async(dispatch_get_main_queue(), ^{
            block(list);
        });
    });
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
    //根据日期排序
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
    //当天排序
    NSMutableArray *tmpList = [NSMutableArray arrayWithCapacity:1];
    for (NSArray<LDPConsoleModel *> *array in sortList) {
        NSArray *tmpArray = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            LDPConsoleModel *model1 = (LDPConsoleModel *)obj1;
            LDPConsoleModel *model2 = (LDPConsoleModel *)obj2;
            return [model2.createDate compare:model1.createDate];
        }];
        [tmpList addObject:tmpArray];
    }
    _historyLogs = [tmpList copy];
    return _historyLogs;
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

- (void)p_trimRecurrence {  //循环调用
    
    [self p_trimInBackGround];
    
//    __weak __typeof(self)weakSelf = self;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60*10 * NSEC_PER_SEC)),
//                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//                       __strong __typeof(weakSelf)self = weakSelf;
//                       if (!self) return;
//                       [self p_trimRecurrence];
//                   });
}

- (void)p_trimInBackGround { //清除过期缓存
    
    [self p_trimWithAge];
//    [self p_trimWithCost];
}

- (void)p_trimWithAge {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async(self.serialQueue, ^{
        
        __strong __typeof(weakSelf)self = weakSelf;

        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-1*kDefaultCacheMaxCacheAge];
        
        for (NSArray<LDPConsoleModel *> *models in self.historyLogs) {
            for (LDPConsoleModel *model in models) {
                NSComparisonResult result = [model.createDate compare:expirationDate];
                if (result == NSOrderedAscending) {
                    [[NSFileManager defaultManager] removeItemAtPath:model.logFilePath error:nil];
                }
            }
        }
        [self checkValidHistoryData];
    });
}

- (void)checkValidHistoryData {
    
    NSMutableArray *tmpList = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray<NSDictionary *> *tmpDictionaryList = [NSMutableArray arrayWithCapacity:1];
    for (NSArray<LDPConsoleModel *> *models in _historyLogs) {
        NSMutableArray *subList = [NSMutableArray arrayWithCapacity:1];
        for (LDPConsoleModel *model in models) {
            if ([model hasLog]) {
                [subList addObject:model];
                [tmpDictionaryList addObject:@{@"date":model.createDate,
                                               @"logFileName":model.logFileName}];
            }
        }
        if (subList.count>0) {
            [tmpList addObject:subList];
        }
    }
    _historyLogs = [tmpList copy];
    //保存缓存
    [[NSUserDefaults standardUserDefaults] setObject:[tmpDictionaryList copy] forKey:kLogKey];
}

@end
