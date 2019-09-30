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

@interface LDPConsoleManager : NSObject

@property (nonatomic, strong) NSMutableArray *logs;
@property (nonatomic, copy) void(^newLogBlock)(NSString *log);

//是否使用控制台功能   仅在DEBUG环境有效
+ (void)open;
+ (instancetype)shareInstance;
- (void)cleanCurrentLog;

- (void)addWithLog:(NSString *)log;

- (NSArray<NSArray<LDPConsoleModel *> *> *)historyLogs;

@end

NS_ASSUME_NONNULL_END
