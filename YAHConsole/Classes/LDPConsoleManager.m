//
//  LDPConsoleManager.m
//  UPWEARTools
//
//  Created by yahua on 2019/9/26.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "LDPConsoleManager.h"
#import "LDPConsoleViewController.h"

#define kLogKey @"kLogKey"

@interface LDPConsoleManager ()

@property (nonatomic, strong) LDPConsoleModel *logModel;

@end

@implementation LDPConsoleManager

+ (void)open {
    
    //#ifdef DEBUG
        [LDPConsoleViewController shareInstance];
    //#endif
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

- (void)addWithLog:(NSString *)log {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!log || log.length==0) {
            return;
        }

        [self.logs addObject:log];
        if (self.newLogBlock) {
            self.newLogBlock(log);
        }
        
        //防止频繁调用
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveLog) object:nil];
        [self performSelector:@selector(saveLog) withObject:nil afterDelay:5];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
    
}

- (void)removeNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willResignActiveNotification:(NSNotification *)notification {
    
    [self saveLog];
}

- (void)willTerminateNotification:(NSNotification *)notification {
    
    [self saveLog];
}

#pragma mark - Private

- (void)saveLogModel {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
