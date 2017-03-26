//
//  QSPDownloadTool.m
//  QSPDownload_Demo
//
//  Created by 綦 on 17/3/21.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import "QSPDownloadTool.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AppDelegate+Download.h"

@interface QSPDownloadSource ()
//下载状态
@property (assign, nonatomic) QSPDownloadSourceStyle style;
//复位数据
@property (strong, nonatomic) NSData *resumeData;

@end

@implementation QSPDownloadSource

- (void)setResumeData:(NSData *)resumeData
{
    if ([self.delegate respondsToSelector:@selector(downloadSource:changedResumeData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadSource:self changedResumeData:resumeData];
        });
    }
    
    _resumeData = resumeData;
}
- (void)setStyle:(QSPDownloadSourceStyle)style
{
    if ([self.delegate respondsToSelector:@selector(downloadSource:changedStyle:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadSource:self changedStyle:style];
        });
    }
    
    _style = style;
}
- (void)changeNetPath:(NSString *)netPath
{
    _netPath = netPath;
}
- (void)changeLocation:(NSURL *)location
{
    _location = location;
}
- (void)changeTask:(NSURLSessionDownloadTask *)task
{
    _task = task;
}
- (void)changeFileName:(NSString *)fileName
{
    _fileName = fileName;
}
- (void)changeTotalBytesWritten:(int64_t)totalBytesWritten
{
    _totalBytesWritten = totalBytesWritten;
}
- (void)changeTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    _totalBytesExpectedToWrite = totalBytesExpectedToWrite;
}

@end


@interface QSPDownloadTool ()<NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSMutableArray *downloadSources;
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSMutableArray *delegateArr;

@end

@implementation QSPDownloadTool

static QSPDownloadTool *_shareInstance;

#pragma mark - 属性方法
- (NSMutableArray *)downloadSources
{
    if (_downloadSources == nil) {
        _downloadSources = [NSMutableArray arrayWithCapacity:1];
    }
    
    return _downloadSources;
}
- (NSURLSession *)session
{
    if (_session == nil) {
        //可以上传下载HTTP和HTTPS的后台任务(程序在后台运行)。 在后台时，将网络传输交给系统的单独的一个进程,即使app挂起、推出甚至崩溃照样在后台执行。
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"QSPDownload"];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    
    return _session;
}
- (NSMutableArray *)delegateArr
{
    if (_delegateArr == nil) {
        _delegateArr = [NSMutableArray arrayWithCapacity:1];
    }
    
    return _delegateArr;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [super allocWithZone:zone];
    });
    
    return _shareInstance;
}
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[self alloc] init];
    });
    
    return _shareInstance;
}

/**
 添加下载任务
 
 @param netPath 下载地址
 @return 下载任务数据模型
 */
- (QSPDownloadSource *)addDownloadTast:(NSString *)netPath andDelegate:(id<QSPDownloadToolDelegate>)delegate
{
    QSPDownloadSource *source = [[QSPDownloadSource alloc] init];
    [source changeNetPath:netPath];
    [source changeTask:[self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:netPath]]]];
    [source changeFileName:[[netPath componentsSeparatedByString:@"/"] lastObject]];
    //开始下载任务
    [source.task resume];
    source.style = QSPDownloadSourceStyleDown;
    [self.downloadSources addObject:source];
    if (![self.delegateArr containsObject:delegate]) {
        [self.delegateArr addObject:delegate];
    }
    return source;
}
- (void)removeDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate
{
    [self.delegateArr removeObject:delegate];
}

/**
 暂停下载任务
 
 @param source 下载任务数据模型
 */
- (void)suspendDownload:(QSPDownloadSource *)source
{
    if (source.style == QSPDownloadSourceStyleDown) {
        [source.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            source.resumeData = resumeData;
            source.style = QSPDownloadSourceStyleSuspend;
        }];
    }
    else
    {
        NSLog(@"不能暂停为开始的下载任务！");
    }
}

/**
 继续下载任务
 
 @param source 下载任务数据模型
 */
- (void)continueDownload:(QSPDownloadSource *)source
{
    if (source.style == QSPDownloadSourceStyleSuspend) {
        source.style = QSPDownloadSourceStyleDown;
        if (source.resumeData) {
            [source changeTask:[self.session downloadTaskWithResumeData:source.resumeData]];
        }
        else
        {
            [source changeTask:[self.session downloadTaskWithURL:[NSURL URLWithString:source.netPath]]];
        }
        [source.task resume];
    }
    else
    {
        NSLog(@"不能继续未暂停的下载任务！");
    }
}

/**
 停止下载任务
 
 @param source 下载任务数据模型
 */
- (void)stopDownload:(QSPDownloadSource *)source
{
    if (source.style == QSPDownloadSourceStyleDown) {
        [source.task cancel];
    }
    
    source.style = QSPDownloadSourceStyleStop;
    [self.downloadSources removeObject:source];
}

#pragma mark - NSURLSessionDownloadDelegate代理方法
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    for (QSPDownloadSource *source in self.downloadSources) {
        if (source.task == downloadTask) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([source.delegate respondsToSelector:@selector(downloadSource:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
                    [source changeTotalBytesWritten:totalBytesWritten];
                    [source changeTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
                    [source.delegate downloadSource:source didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
                }
            });
        }
    }
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"%@", location);
    NSLog(@"%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]);
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.completionHandler) {
        appDelegate.completionHandler();
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id delegate in self.delegateArr) {
            if ([delegate respondsToSelector:@selector(downloadTool:downloadTask:didFinishDownloadingToURL:)]) {
                [delegate downloadTool:self downloadTask:downloadTask didFinishDownloadingToURL:location];
            }
        }
    });
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"%s", __FUNCTION__);
}

@end
