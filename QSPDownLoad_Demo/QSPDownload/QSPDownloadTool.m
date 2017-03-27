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

#define DownloadCell_Limit              1024.0

@interface QSPDownloadSource ()
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
- (void)setNetPath:(NSString *)netPath
{
    _netPath = netPath;
}
- (void)setLocation:(NSURL *)location
{
    _location = location;
}
- (void)setTask:(NSURLSessionDownloadTask *)task
{
    _task = task;
}
- (void)setFileName:(NSString *)fileName
{
    _fileName = fileName;
}
- (void)setTotalBytesWritten:(int64_t)totalBytesWritten
{
    _totalBytesWritten = totalBytesWritten;
}
- (void)setTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    _totalBytesExpectedToWrite = totalBytesExpectedToWrite;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.netPath = [aDecoder decodeObjectForKey:@"netPath"];
        self.location = [aDecoder decodeObjectForKey:@"location"];
        self.style = [aDecoder decodeIntegerForKey:@"style"];
        self.task = nil;
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.totalBytesWritten = [aDecoder decodeInt64ForKey:@"totalBytesWritten"];
        self.totalBytesExpectedToWrite = [aDecoder decodeInt64ForKey:@"totalBytesExpectedToWrite"];
        self.offLine = [aDecoder decodeBoolForKey:@"offLine"];
        
        self.resumeData = [aDecoder decodeObjectForKey:@"resumeData"];
    }
    
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.netPath forKey:@"netPath"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeInteger:self.style forKey:@"style"];
    [aCoder encodeObject:nil forKey:@"task"];
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeInt64:self.totalBytesWritten forKey:@"totalBytesWritten"];
    [aCoder encodeInt64:self.totalBytesExpectedToWrite forKey:@"totalBytesExpectedToWrite"];
    [aCoder encodeBool:self.offLine forKey:@"offLine"];
    
    [aCoder encodeObject:self.resumeData forKey:@"resumeData"];
}

@end


@interface QSPDownloadTool ()<NSURLSessionDownloadDelegate, UIApplicationDelegate>

#define QSPDownloadTool_DownloadSources_Path            [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"QSPDownloadTool_downloadSources.data"]
#define QSPDownloadTool_OffLineStyle_Key                @"QSPDownloadTool_OffLineStyle_Key"
#define QSPDownloadTool_OffLine_Key                     @"QSPDownloadTool_OffLine_Key"

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
        NSArray *arr = [NSArray arrayWithContentsOfFile:QSPDownloadTool_DownloadSources_Path];
        
        for (NSData *data in arr) {
            QSPDownloadSource *source = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if (source.resumeData) {
                [source setTask:[self.session downloadTaskWithResumeData:source.resumeData]];
            }
            else
            {
                [source setTask:[self.session downloadTaskWithURL:[NSURL URLWithString:source.netPath]]];
            }
            [_downloadSources addObject:source];
            
            if (source.isOffLine) {
                if (self.offLineStyle == QSPDownloadToolOffLineStyleDefaut) {
                    if (source.style == QSPDownloadSourceStyleDown || source.style == QSPDownloadSourceStyleSuspend) {
                        source.style = QSPDownloadSourceStyleDown;
                        [self suspendDownload:source];
                    }
                }
                else if (self.offLineStyle == QSPDownloadToolOffLineStyleAuto)
                {
                    if (source.style == QSPDownloadSourceStyleDown || source.style == QSPDownloadSourceStyleSuspend || source.style == QSPDownloadSourceStyleFail) {
                        source.style = QSPDownloadSourceStyleSuspend;
                        [self continueDownload:source];
                    }
                }
                else if (self.offLineStyle == QSPDownloadToolOffLineStyleFromSource)
                {
                    if (source.style == QSPDownloadSourceStyleDown) {
                        source.style = QSPDownloadSourceStyleSuspend;
                        [self continueDownload:source];
                    }
                }
            }
        }
    }
    
    return _downloadSources;
}
- (QSPDownloadToolOffLineStyle)offLineStyle
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:QSPDownloadTool_OffLineStyle_Key];
}
- (void)setOffLineStyle:(QSPDownloadToolOffLineStyle)offLineStyle
{
    [[NSUserDefaults standardUserDefaults] setInteger:self.offLineStyle forKey:QSPDownloadTool_OffLineStyle_Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
        [[NSNotificationCenter defaultCenter] addObserver:_shareInstance selector:@selector(savaDownloadSources:) name:UIApplicationWillTerminateNotification object:nil];
    });
    
    return _shareInstance;
}
- (void)savaDownloadSources:(NSNotification *)sender
{
    NSLog(@"我退出啦！");
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:1];
    for (QSPDownloadSource *souce in self.downloadSources) {
        if (souce.isOffLine) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:souce];
            [mArr addObject:data];
        }
    }
    
    [mArr writeToFile:QSPDownloadTool_DownloadSources_Path atomically:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
 按字节计算文件大小

 @param tytes 字节数
 @return 文件大小字符串
 */
+ (NSString *)calculationDataWithBytes:(int64_t)tytes
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

/**
 添加下载任务
 
 @param netPath 下载地址
 @return 下载任务数据模型
 */
- (QSPDownloadSource *)addDownloadTast:(NSString *)netPath andOffLine:(BOOL)offLine;
{
    QSPDownloadSource *source = [[QSPDownloadSource alloc] init];
    [source setNetPath:netPath];
    [source setTask:[self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:netPath]]]];
    [source setFileName:[[netPath componentsSeparatedByString:@"/"] lastObject]];
    //开始下载任务
    [source.task resume];
    source.style = QSPDownloadSourceStyleDown;
    source.offLine = offLine;
    [(NSMutableArray *)self.downloadSources addObject:source];
    return source;
}
- (void)addDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate
{
    for (QSPDownloadToolDelegateObject *obj in self.delegateArr) {
        if (obj.delegate == delegate) {
            return;
        }
    }
    
    QSPDownloadToolDelegateObject *delegateObj = [[QSPDownloadToolDelegateObject alloc] init];
    delegateObj.delegate = delegate;
    [self.delegateArr addObject:delegateObj];
}
- (void)removeDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate
{
    for (QSPDownloadToolDelegateObject *obj in self.delegateArr) {
        if (obj.delegate == delegate) {
            [self.delegateArr removeObject:delegate];
            return;
        }
    }
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
- (void)suspendAllTask
{
    for (QSPDownloadSource *source in self.downloadSources) {
        [self suspendDownload:source];
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
            [source setTask:[self.session downloadTaskWithResumeData:source.resumeData]];
        }
        else
        {
            [source setTask:[self.session downloadTaskWithURL:[NSURL URLWithString:source.netPath]]];
        }
        [source.task resume];
    }
    else
    {
        NSLog(@"不能继续未暂停的下载任务！");
    }
}
- (void)startAllTask
{
    for (QSPDownloadSource *source in self.downloadSources) {
        [self continueDownload:source];
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
    [(NSMutableArray *)self.downloadSources removeObject:source];
}
- (void)stopAllTask
{
    for (QSPDownloadSource *source in self.downloadSources) {
        [self stopDownload:source];
    }
}
#pragma mark - NSURLSessionDownloadDelegate代理方法
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    for (QSPDownloadSource *source in self.downloadSources) {
        if (source.task == downloadTask) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([source.delegate respondsToSelector:@selector(downloadSource:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
                    [source setTotalBytesWritten:totalBytesWritten];
                    [source setTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (QSPDownloadToolDelegateObject *delegateObj in self.delegateArr) {
            if ([delegateObj.delegate respondsToSelector:@selector(downloadTool:downloadTask:didFinishDownloadingToURL:)]) {
                [delegateObj.delegate downloadTool:self downloadTask:downloadTask didFinishDownloadingToURL:location];
            }
        }
    });
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.completionHandler) {
        appDelegate.completionHandler();
    }
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"%s", __FUNCTION__);
}

@end


@implementation QSPDownloadToolDelegateObject

@end

