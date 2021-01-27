//
//  LDPConsleDetailViewController.m
//  UPWEARTools
//
//  Created by yahua on 2019/9/29.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "LDPConsleDetailViewController.h"

@interface LDPConsleDetailViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) LDPConsoleModel *model;

@property (nonatomic,strong) UIDocumentInteractionController *document;

@end

@implementation LDPConsleDetailViewController

- (instancetype)initWithModel:(LDPConsoleModel *)model {
    
    NSBundle *bundle = [NSBundle bundleForClass:LDPConsleDetailViewController.class];
    NSURL *url = [bundle URLForResource:@"YAHConsole" withExtension:@"bundle"];
    bundle = url?[NSBundle bundleWithURL:url]:[NSBundle mainBundle];
    self = [super initWithNibName:NSStringFromClass(LDPConsleDetailViewController.class) bundle:bundle];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        _model = model;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    __weak typeof(self) weakSelf  = self;
    [_model readLogWithBlock:^(NSString * _Nonnull log) {
        weakSelf.textView.text = log;
    }];
}

#pragma mark - Action

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

- (IBAction)exportAction:(id)sender {
    
    _document = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:[self.model logFilePath]]];
    BOOL canOpen =  [self.document presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    if(!canOpen) {
        NSLog(@"沒有程序可以打开选中的文件");
     }
}

@end
