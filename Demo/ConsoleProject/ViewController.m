//
//  ViewController.m
//  ConsoleProject
//
//  Created by yahua on 2019/9/29.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self log];
}

- (void)log {
    
    NSLog(@"打印log");
    [self performSelector:@selector(log) withObject:nil afterDelay:0.5f];
}

@end
