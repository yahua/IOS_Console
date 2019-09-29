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

#define  LDPConsoleLogChangeNotification  @"LDPConsoleLogChangeNotification"

@interface LDPConsoleManager : NSObject

@property (nonatomic, strong) NSMutableArray *logs;

//是否使用控制台功能   仅在DEBUG环境有效
+ (void)open;
+ (instancetype)shareInstance;

- (void)addWithLog:(NSString *)log;

- (NSArray<NSArray<LDPConsoleModel *> *> *)historyLogs;

@end

NS_ASSUME_NONNULL_END
