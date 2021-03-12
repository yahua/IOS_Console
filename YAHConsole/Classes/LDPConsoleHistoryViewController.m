//
//  LDPConsoleHistoryViewController.m
//  UPWEARTools
//
//  Created by yahua on 2019/9/29.
//  Copyright © 2019 Landi. All rights reserved.
//

#import "LDPConsoleHistoryViewController.h"
#import "LDPConsleDetailViewController.h"
#import "LDPConsoleManager.h"

@interface LDPConsoleHistoryViewController () <
UITableViewDelegate,
UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel;

@property (nonatomic, strong) NSArray<NSArray<LDPConsoleModel *> *> *datas;

@end

@implementation LDPConsoleHistoryViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    __weak __typeof(self)weakSelf = self;
    [[LDPConsoleManager shareInstance] getHistoryLog:^(NSArray<NSArray<LDPConsoleModel *> *> * _Nonnull historyLogs) {
        weakSelf.datas = historyLogs;
        [self.tableView reloadData];
        
        unsigned long long total = 0;
        for (NSArray<LDPConsoleModel *> *array in historyLogs) {
            for (LDPConsoleModel *model in array) {
                total += model.logSizeByte;
            }
        }
        self.totalSizeLabel.text = [NSString stringWithFormat:@"总缓存:%.2fMB", total*1.0/1024/1024];
    }];
}

- (IBAction)closeButton:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.datas.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.datas[section].count;
}

//- (CGFloat)tab

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return [self.datas[section].firstObject modelDate];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    LDPConsoleModel *model = [self.datas[indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.textColor = model.force?[UIColor redColor]:[UIColor blackColor];
    cell.textLabel.text = [model modelDetailDate];
    cell.detailTextLabel.text = [model logSizeString];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    LDPConsoleModel *model = self.datas[indexPath.section][indexPath.row];
    [self presentViewController:[[LDPConsleDetailViewController alloc] initWithModel:model] animated:YES completion:nil];
}

@end
