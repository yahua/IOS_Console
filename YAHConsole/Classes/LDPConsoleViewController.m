//
//  LDPConsoleViewController.m
//  UPWEARTools
//
//  Created by yahua on 2019/9/26.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "LDPConsoleViewController.h"
#import "LDPConsoleHistoryViewController.h"
#import "LDPConsoleManager.h"
#import <fishhook/fishhook.h>

//申明一个函数指针用于保存原NSLog的真实函数地址
static void (*orig_nslog)(NSString *format, ...);
 
//NSLog重定向
void redirect_nslog(NSString *format, ...) {
    
    va_list vl;
    va_start(vl, format);
    NSString* str = [[NSString alloc] initWithFormat:format arguments:vl];
    va_end(vl);
    orig_nslog(str);
    
    //可以添加自己的处理，比如输出到自己的持久化存储系统中
    NSDateFormatter *formatter = [NSDateFormatter new];
    //    formatter.locale = [NSLocale currentLocale]; // Necessary?
    formatter.dateFormat = @"YYYY-MM-dd hh:mm:ss:SSS";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    NSString *log = [NSString stringWithFormat:@"%@ %@\n",dateStr, str];
    [[LDPConsoleManager shareInstance] addWithLog:log];
}


@interface LDPConsoleViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSMutableArray *showLogs;

@end

@implementation LDPConsoleViewController

//+(void)load {
//
//    #ifdef DEBUG
//    [LDPConsoleViewController shareInstance];
//    #endif
//}

+ (instancetype)shareInstance {
    
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:LDPConsoleViewController.class];
        NSURL *url = [bundle URLForResource:@"YAHConsole" withExtension:@"bundle"];
        bundle = url?[NSBundle bundleWithURL:url]:[NSBundle mainBundle];
        instance = [[LDPConsoleViewController alloc] initWithNibName:NSStringFromClass(LDPConsoleViewController.class) bundle:bundle];
    });
    return instance;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
#ifdef DEBUG
        struct rebinding nslog_rebinding = {"NSLog",redirect_nslog,(void*)&orig_nslog};
        rebind_symbols((struct rebinding[1]){nslog_rebinding}, 1);
        
        UIButton *consoleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        consoleBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-44-15, [UIScreen mainScreen].bounds.size.height*0.66, 44, 44);
        consoleBtn.layer.cornerRadius = 22;
        consoleBtn.layer.masksToBounds = YES;
        [consoleBtn setTitle:@"Console" forState:UIControlStateNormal];
        [consoleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        consoleBtn.titleLabel.font = [UIFont systemFontOfSize:10];
        consoleBtn.backgroundColor = [UIColor blueColor];
        [consoleBtn addTarget:self action:@selector(enterConsole) forControlEvents:UIControlEventTouchUpInside];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow addSubview:consoleBtn];
        });
        
#else
#endif
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logChangeNotification) name:LDPConsoleLogChangeNotification object:nil];
    
    _showLogs = [NSMutableArray arrayWithCapacity:1];
    [self performSelector:@selector(showLog) withObject:nil afterDelay:3.0f];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.textView.text = [[LDPConsoleManager shareInstance].logs componentsJoinedByString:@"\n"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToBottom:nil];
    });
}

- (void)logChangeNotification {
    
    //self.textView.text = [[LDPConsoleManager shareInstance].logs componentsJoinedByString:@"\n"];
    if (!self.presentingViewController) {
        return;
    }
    [self.showLogs addObject:[LDPConsoleManager shareInstance].logs.lastObject];
}

- (void)showLog {
    
    if (self.showLogs.count == 0) {
        return;
    }
    
    NSString *log = [self.showLogs componentsJoinedByString:@"\n"];
    BOOL scrollToBottom = NO;
    if (self.textView.contentOffset.y+50 >=
        (self.textView.contentSize.height- self.textView.bounds.size.height)) {
        scrollToBottom = YES;
    }
    [self.textView insertText:log];
    if (scrollToBottom) {
        [self scrollToBottom:nil];
    }
    [self.showLogs removeAllObjects];
    [self performSelector:@selector(showLog) withObject:nil afterDelay:3.0f];
}

#pragma mark - Private

#pragma mark - Action

- (void)enterConsole {
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[LDPConsoleViewController shareInstance] animated:YES completion:nil];
}

- (IBAction)closeAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)scrollToTop:(id)sender {
    
    [self.textView setContentOffset:CGPointMake(0, 0) animated:YES];
}
- (IBAction)scrollToBottom:(id)sender {
    
    CGFloat y = self.textView.contentSize.height- self.textView.bounds.size.height;
    if (y<0) {
        return;
    }
    [self.textView setContentOffset:CGPointMake(0, y) animated:YES];
}

- (IBAction)historyAction:(id)sender {
    
    NSBundle *bundle = [NSBundle bundleForClass:LDPConsoleHistoryViewController.class];
    NSURL *url = [bundle URLForResource:@"YAHConsole" withExtension:@"bundle"];
    bundle = url?[NSBundle bundleWithURL:url]:[NSBundle mainBundle];
    LDPConsoleHistoryViewController *vc = [[LDPConsoleHistoryViewController alloc] initWithNibName:NSStringFromClass(LDPConsoleHistoryViewController.class) bundle:bundle];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
