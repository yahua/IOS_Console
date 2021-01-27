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

- (void)saveLog:(NSString *)log;

- (void)readLogWithBlock:(void(^)(NSString *log))block;

- (NSString *)logFilePath;

@end

@interface LDPConsoleModel (Date)

//精确到天
- (NSString *)modelDate;
//精确到秒
- (NSString *)modelDetailDate;

@end

NS_ASSUME_NONNULL_END
