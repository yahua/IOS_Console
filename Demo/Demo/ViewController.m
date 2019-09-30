//
//  ViewController.m
//  Demo
//
//  Created by yahua on 2019/9/30.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self log];
}

 NSInteger sindex = 0;
- (void)log {
    
    NSLog(@"nslog  %td", sindex);
    printf("printf %td\n", sindex);
    sindex++;
    [self performSelector:@selector(log) withObject:nil afterDelay:0.1];
}

@end
