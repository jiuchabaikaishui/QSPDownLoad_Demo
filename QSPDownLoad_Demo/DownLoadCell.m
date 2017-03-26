//
//  DownLoadCell.m
//  QSPDownLoad_Demo
//
//  Created by 綦 on 17/3/26.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import "DownLoadCell.h"

@interface DownLoadCell ()<QSPDownloadSourceDelegate>

#define DownLoadCell_BigFont            [UIFont systemFontOfSize:14]
#define DownLoadCell_SmollFont          [UIFont systemFontOfSize:10]
#define DownloadCell_Limit              1024.0
#define DownloadCell_Spcing             8.0
@property (weak, nonatomic) UIProgressView *progressView;
@property (weak, nonatomic) UIButton *button;
@property (weak, nonatomic) UILabel *totalLabel;
@property (weak, nonatomic) UILabel *progressLabel;
@property (weak, nonatomic) UILabel *rateLabel;
@property (assign, nonatomic) BOOL isFirstFresh;

@end

@implementation DownLoadCell

#pragma mark - 属性方法
- (void)setSource:(QSPDownloadSource *)source
{
    if (source) {
        if (_source) {
            _source.delegate = nil;
        }
        _source = source;
        source.delegate = self;
        self.isFirstFresh = YES;
        
        self.textLabel.text = source.fileName;
        if (source.totalBytesExpectedToWrite == 0) {
            self.progressView.progress = 0;
        }
        else
        {
            self.progressView.progress = source.totalBytesWritten/(float)source.totalBytesExpectedToWrite;
        }
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textLabel.font = DownLoadCell_BigFont;
        self.textLabel.textColor = [UIColor blackColor];
        
        UILabel *label = [[UILabel alloc] init];
        label.font = DownLoadCell_SmollFont;
        label.textColor = [UIColor grayColor];
        [self.contentView addSubview:label];
        self.totalLabel = label;
        
        label = [[UILabel alloc] init];
        label.font = DownLoadCell_SmollFont;
        label.textColor = self.totalLabel.textColor;
        [self.contentView addSubview:label];
        self.progressLabel = label;
        
        label = [[UILabel alloc] init];
        label.font = DownLoadCell_SmollFont;
        label.textColor = self.totalLabel.textColor;
        [self.contentView addSubview:label];
        self.rateLabel = label;
        
        UIProgressView *progressView = [[UIProgressView alloc] init];
        progressView.progress = 0;
        [self.contentView addSubview:progressView];
        self.progressView = progressView;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont systemFontOfSize:10];
        [button setTitle:@"暂停" forState:UIControlStateNormal];
        UIColor *color = [UIColor colorWithRed:0 green:122/255.0 blue:255/255.0 alpha:1];
        [button setTitleColor:color forState:UIControlStateNormal];
        [button setTitleColor:color forState:UIControlStateSelected];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        button.layer.borderWidth = 0.5;
        button.layer.borderColor = [UIColor grayColor].CGColor;
        button.layer.cornerRadius = 5;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:button];
        self.button = button;
    }
    
    return self;
}

- (void)buttonClicked:(UIButton *)sender
{
    if ([sender.currentTitle isEqualToString:@"下载"]) {
        [[QSPDownloadTool shareInstance] continueDownload:self.source];
    }
    else
    {
        [[QSPDownloadTool shareInstance] suspendDownload:self.source];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //设置位置信息
    CGFloat Y = DownloadCell_Spcing;
    CGFloat H = self.frame.size.height - 2*Y;
    CGFloat W = H;
    CGFloat X = self.frame.size.width - W - DownloadCell_Spcing;
    self.button.frame = CGRectMake(X, Y, W, H);
    
    W = X - 2*DownloadCell_Spcing;
    X = DownloadCell_Spcing;
    Y = DownloadCell_Spcing;
    H = self.frame.size.height - 2*Y - 15;
    self.textLabel.frame = CGRectMake(X, Y, W, H);
    
    Y = Y + H;
    W = [self.totalLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: DownLoadCell_SmollFont} context:nil].size.width;
    H = 15;
    self.totalLabel.frame = CGRectMake(X, Y, W, H);
    
    X = X + W + DownloadCell_Spcing;
    W = [self.progressLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: DownLoadCell_SmollFont} context:nil].size.width;
    self.progressLabel.frame = CGRectMake(X, Y, W, H);
    
    W = [self.rateLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: DownLoadCell_SmollFont} context:nil].size.width;
    X = self.button.frame.origin.x - DownloadCell_Spcing - W;
    self.rateLabel.frame = CGRectMake(X, Y, W, H);
    
    W = self.button.frame.origin.x - 2*DownloadCell_Spcing;
    X = DownloadCell_Spcing;
    Y = self.frame.size.height - DownloadCell_Spcing;
    H = DownloadCell_Spcing;
    self.progressView.frame = CGRectMake(X, Y, W, H);
}

- (NSString *)calculationDataWithBytes:(int64_t)tytes
{
    NSString *result;
    double length;
    if (tytes > DownloadCell_Limit) {
        length = tytes/DownloadCell_Limit;
        if (length > DownloadCell_Limit) {
            length /= DownloadCell_Limit;
            if (length > DownloadCell_Limit) {
                length /= DownloadCell_Limit;
                if (length > DownloadCell_Limit) {
                    length /= DownloadCell_Limit;
                    result = [NSString stringWithFormat:@"%.2fTB", length];
                }
                else
                {
                    result = [NSString stringWithFormat:@"%.2fGB", length];
                }
            }
            else
            {
                result = [NSString stringWithFormat:@"%.2fMB", length];
            }
        }
        else
        {
            result = [NSString stringWithFormat:@"%.2fKB", length];
        }
    }
    else
    {
        result = [NSString stringWithFormat:@"%lliB", tytes];
    }
    
    return result;
}
- (void)freshUiTotalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite bytes:(int64_t)bytes andTimeInterval:(NSTimeInterval)timeInterval
{
    float progress = totalBytesWritten/(float)totalBytesExpectedToWrite;
    self.progressView.progress = progress;
    self.progressLabel.text = [NSString stringWithFormat:@"已下载：%.1f%%", progress*100];
    self.progressLabel.frame = CGRectMake(self.totalLabel.frame.origin.x + self.totalLabel.frame.size.width + DownloadCell_Spcing, self.progressLabel.frame.origin.y, [self.progressLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: DownLoadCell_SmollFont} context:nil].size.width, self.progressLabel.frame.size.height);
    
    self.rateLabel.text = [NSString stringWithFormat:@"%@/s", [self calculationDataWithBytes:(int64_t)(bytes/timeInterval)]];
    CGFloat W = [self.rateLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: DownLoadCell_SmollFont} context:nil].size.width;
    self.rateLabel.frame = CGRectMake(self.button.frame.origin.x - DownloadCell_Spcing - W, self.rateLabel.frame.origin.y, W, self.rateLabel.frame.size.height);
}

#pragma mark - <QSPDownloadSourceDelegate>代理方法
- (void)downloadSource:(QSPDownloadSource *)source didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (!self.totalLabel.text) {
        self.totalLabel.text = [self calculationDataWithBytes:totalBytesExpectedToWrite];
        self.totalLabel.frame = CGRectMake(self.totalLabel.frame.origin.x, self.totalLabel.frame.origin.y, [self.totalLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: DownLoadCell_SmollFont} context:nil].size.width, self.totalLabel.frame.size.height);
    }
    
    static NSDate *lastDate;
    static int64_t bytes;
    NSDate *now = [NSDate date];
    if (lastDate) {
        NSTimeInterval timeInterval = [now timeIntervalSinceDate:lastDate];
        bytes += bytesWritten;
        if (timeInterval > 1) {
            [self freshUiTotalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite bytes:bytes andTimeInterval:timeInterval];
            lastDate = now;
            bytes = 0;
        }
        else
        {
            if (self.isFirstFresh) {
                [self freshUiTotalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite bytes:bytes andTimeInterval:timeInterval];
                lastDate = now;
                bytes = 0;
                self.isFirstFresh = NO;
            }
        }
    }
    else
    {
        lastDate = now;
    }
}
- (void)downloadSource:(QSPDownloadSource *)source changedStyle:(QSPDownloadSourceStyle)style
{
    if (style == QSPDownloadSourceStyleDown) {
        [self.button setTitle:@"暂停" forState:UIControlStateNormal];
    }
    else if (style == QSPDownloadSourceStyleSuspend)
    {
        [self.button setTitle:@"下载" forState:UIControlStateNormal];
    }
}
- (void)downloadSource:(QSPDownloadSource *)source changedResumeData:(NSData *)resumeData
{
    NSLog(@"%s", __FUNCTION__);
}

@end
