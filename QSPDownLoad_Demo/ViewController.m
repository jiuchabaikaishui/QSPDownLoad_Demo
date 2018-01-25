//
//  ViewController.m
//  QSPDownLoad_Demo
//
//  Created by 綦 on 17/3/21.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import "ViewController.h"
#import "DownLoadCell.h"
#import "FinishedViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, QSPDownloadToolDelegate>

@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataArr;

@end

@implementation ViewController

- (NSMutableArray *)dataArr
{
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray arrayWithArray:[QSPDownloadTool shareInstance].downloadSources];
    }
    
    return _dataArr;
}

- (void)dealloc
{
    NSLog(@"%@ 销毁啦！", NSStringFromClass([self class]));
    [[QSPDownloadTool shareInstance] removeDownloadToolDelegate:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [button addTarget:self action:@selector(addDownLoadData:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setRightBarButtonItem:item];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    [self.view addSubview:tableView];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView = tableView;
    
    [[QSPDownloadTool shareInstance] addDownloadToolDelegate:self];
}

- (void)addDownLoadData:(UIButton *)sender
{
    [self.dataArr addObject:[[QSPDownloadTool shareInstance] addDownloadTast:@"http://120.25.226.186:32812/resources/videos/minion_08.mp4" andOffLine:YES]];//http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0   //http://dl102.80s.im:920/1703/[射雕YX传2017版]第38集/[射雕YX传2017版]第38集_bd.mp4
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.dataArr.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>代理方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"DownLoadCell";
    DownLoadCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[DownLoadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.source = self.dataArr[indexPath.row];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DownLoadCell_Height;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[QSPDownloadTool shareInstance] stopDownload:self.dataArr[indexPath.row]];
        [self.dataArr removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    }
}

#pragma mark - <QSPDownloadToolDelegate>代理方法
- (void)downloadToolDidFinish:(QSPDownloadTool *)tool downloadSource:(QSPDownloadSource *)source
{
    for (int index = 0; index < self.dataArr.count; index++) {
        QSPDownloadSource *currentSource = self.dataArr[index];
        if (currentSource.task == source.task) {
            [self.dataArr removeObject:currentSource];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
        }
    }
    
    NSArray *arr = [NSArray arrayWithContentsOfFile:QSPDownloadTool_DownloadFinishedSources_Path];
    NSMutableArray *mArr = [NSMutableArray arrayWithArray:arr];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:source];
    [mArr addObject:data];
    
    [mArr writeToFile:QSPDownloadTool_DownloadFinishedSources_Path atomically:YES];
}

@end
