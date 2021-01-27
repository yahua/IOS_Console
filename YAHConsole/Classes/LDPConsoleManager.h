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

/// 历史log数据
- (NSArray<NSArray<LDPConsoleModel *> *> *)historyLogs;

@end

NS_ASSUME_NONNULL_END
