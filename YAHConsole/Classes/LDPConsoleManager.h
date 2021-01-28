//
//  LDPConsoleManager.h
//  UPWEARTools
//
//  Created by yahua on 2019/9/26.
//  Copyright © 2019 Landi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDPConsoleModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^DPConsoleLogCallBackBlock)(NSString *log);

@interface LDPConsoleManager : NSObject

@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *logs;

//是否开启log监听
+ (void)open;
+ (instancetype)shareInstance;

- (void)addLogMonitorCallBack:(DPConsoleLogCallBackBlock)callback;

/// 清除当前所有log
- (void)cleanCurrentLog;

/// 添加新log
/// @param log log
- (void)addWithLog:(NSString *)log;

/// 保存log
- (void)saveLog;

/// 获取历史log
/// @param block 完成回调
- (void)getHistoryLog:(void(^)(NSArray<NSArray<LDPConsoleModel *> *> *historyLogs))block;

@end

NS_ASSUME_NONNULL_END
