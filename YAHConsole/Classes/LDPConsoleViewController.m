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

@interface LDPConsoleViewController ()<
UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSMutableArray *showLogs;

@property (nonatomic, strong) NSMutableArray<NSValue *> *searchRangList;
@property (nonatomic, assign) NSInteger rangeIndex;

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
        instance = [[LDPConsoleViewController alloc] initWithFloatButton];
    });
    return instance;
}

- (instancetype)init
{
    NSBundle *bundle = [NSBundle bundleForClass:LDPConsoleViewController.class];
    NSURL *url = [bundle URLForResource:@"YAHConsole" withExtension:@"bundle"];
    bundle = url?[NSBundle bundleWithURL:url]:[NSBundle mainBundle];
    return [self initWithNibName:NSStringFromClass(LDPConsoleViewController.class) bundle:bundle];
}

- (instancetype)initWithFloatButton {
    
    self = [self init];
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
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    __weak typeof(self) weakSelf  = self;
    [[LDPConsoleManager shareInstance] addLogMonitorCallBack:^(NSString * _Nonnull log) {
        if (!weakSelf.presentingViewController) {
            return;
        }
        [weakSelf.showLogs addObject:[LDPConsoleManager shareInstance].logs.lastObject];
    }];
    
    _showLogs = [NSMutableArray arrayWithCapacity:1];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.textView.text = [[LDPConsoleManager shareInstance].logs componentsJoinedByString:@"\n"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToBottom:nil];
    });
    
    [self performSelector:@selector(showLog) withObject:nil afterDelay:3.0f];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showLog) object:nil];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollToBottom:nil];
        });
    }
    [self.showLogs removeAllObjects];
    [self performSelector:@selector(showLog) withObject:nil afterDelay:3.0f];
}

#pragma mark - Public

+ (void)show {
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[LDPConsoleViewController new] animated:YES completion:nil];
}

#pragma mark - Getter

- (NSMutableArray<NSValue *> *)searchRangList {
    
    if (!_searchRangList) {
        _searchRangList = [NSMutableArray arrayWithCapacity:1];
    }
    return _searchRangList;
}

#pragma mark - Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self search];
}

- (void)search {
    
    [self.searchRangList removeAllObjects];
    self.rangeIndex = 0;
    
    [self.textView.textStorage addAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor],NSBackgroundColorAttributeName:[UIColor clearColor]} range:NSMakeRange(0, self.textView.text.length)];
    NSString *content = self.textView.text;
           NSInteger iLocation = 0;
           while (true) {
               NSRange r = [content rangeOfString:self.searchTextField.text options:NSRegularExpressionSearch range:NSMakeRange(iLocation, content.length-iLocation)];
               if (r.location == NSNotFound) {
                   break;
               }
               [self.textView.textStorage addAttributes:@{NSForegroundColorAttributeName:[UIColor redColor],NSBackgroundColorAttributeName:[UIColor grayColor]} range:r];
               iLocation = r.location+r.length;
               [self.searchRangList addObject:[NSValue valueWithRange:r]];
           }
    [self locationSearchRange];
}

- (void)locationSearchRange {
    
    if (self.rangeIndex < self.searchRangList.count) {
        [self.textView scrollRangeToVisible:[self.searchRangList[self.rangeIndex] rangeValue]];
        [self.textView.textStorage addAttributes:@{NSBackgroundColorAttributeName:[UIColor yellowColor]} range:[self.searchRangList[self.rangeIndex] rangeValue]];
    }
}

#pragma mark - Action

- (IBAction)nextAction:(id)sender {
    
    if (self.searchRangList.count == 0) {
        return;
    }
    
    self.rangeIndex += 1;
    if (self.rangeIndex >= self.searchRangList.count) {
        self.rangeIndex = 0;
    }
    [self locationSearchRange];
}

- (void)enterConsole {
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[LDPConsoleViewController shareInstance] animated:YES completion:nil];
}

- (IBAction)clearAction:(id)sender {
    
    [[LDPConsoleManager shareInstance] cleanCurrentLog];
    
    [self.showLogs removeAllObjects];
    self.textView.text = @"";
}

- (IBAction)closeAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)scrollToTop:(id)sender {
    
    [self.textView setContentOffset:CGPointMake(0, 0) animated:NO];
}
- (IBAction)scrollToBottom:(id)sender {
    
    CGFloat y = self.textView.contentSize.height- self.textView.bounds.size.height;
    if (y<0) {
        y = 0;
        return;
    }
    [self.textView setContentOffset:CGPointMake(0, y) animated:NO];
}

- (IBAction)historyAction:(id)sender {
    
    [[LDPConsoleManager shareInstance] saveLog];
    
    NSBundle *bundle = [NSBundle bundleForClass:LDPConsoleHistoryViewController.class];
    NSURL *url = [bundle URLForResource:@"YAHConsole" withExtension:@"bundle"];
    bundle = url?[NSBundle bundleWithURL:url]:[NSBundle mainBundle];
    LDPConsoleHistoryViewController *vc = [[LDPConsoleHistoryViewController alloc] initWithNibName:NSStringFromClass(LDPConsoleHistoryViewController.class) bundle:bundle];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
