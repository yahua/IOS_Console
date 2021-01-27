//
//  LDPConsoleViewController.h
//  UPWEARTools
//
//  Created by yahua on 2019/9/26.
//  Copyright © 2019 Landi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LDPConsoleViewController : UIViewController

//提供一个悬浮按钮，进入日志查询页面
+ (instancetype)shareInstance;

+ (void)show;

@end

NS_ASSUME_NONNULL_END
