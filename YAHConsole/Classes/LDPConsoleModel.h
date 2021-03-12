//
//  LDPConsoleModel.h
//  UPWEARTools
//
//  Created by yahua on 2019/9/29.
//  Copyright © 2019 Landi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LDPConsoleModel : NSObject

@property (nonatomic, strong) NSDate *createDate;
@property (nonatomic, copy) NSString *logFileName;
@property (nonatomic, assign) BOOL force; //是否是强制保存的log

- (void)saveLog:(NSString *)log;

- (void)readLogWithBlock:(void(^)(NSString *log))block;

- (NSString *)logFilePath;

/// 是否有log
- (BOOL)hasLog;
- (unsigned long long)logSizeByte;
- (NSString *)logSizeString;

@end

@interface LDPConsoleModel (Date)

//精确到天
- (NSString *)modelDate;
//精确到秒
- (NSString *)modelDetailDate;

@end

NS_ASSUME_NONNULL_END
