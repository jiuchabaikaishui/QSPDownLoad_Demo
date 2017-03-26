//
//  QSPDownloadTool.h
//  QSPDownload_Demo
//
//  Created by 綦 on 17/3/21.
//  Copyright © 2017年 PowesunHolding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QSPDownloadSource;

typedef NS_ENUM(NSInteger, QSPDownloadSourceStyle) {
    QSPDownloadSourceStyleDown = 0,//暂停
    QSPDownloadSourceStyleSuspend = 1,//下载
    QSPDownloadSourceStyleStop = 2,//停止
    QSPDownloadSourceStyleFinished = 3//完成
};


@protocol QSPDownloadSourceDelegate <NSObject>

@optional
- (void)downloadSource:(QSPDownloadSource *)source changedStyle:(QSPDownloadSourceStyle)style;
- (void)downloadSource:(QSPDownloadSource *)source changedResumeData:(NSData *)resumeData;
- (void)downloadSource:(QSPDownloadSource *)source didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

@end
@interface QSPDownloadSource : NSObject

//地址路径
@property (copy, nonatomic, readonly) NSString *netPath;
//本地路径
@property (copy, nonatomic) NSURL *location;
//下载任务
@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *task;
//文件名称
@property (strong, nonatomic, readonly) NSString *fileName;
//已下载的字节数
@property (assign, nonatomic, readonly) int64_t totalBytesWritten;
//文件字节数
@property (assign, nonatomic, readonly) int64_t totalBytesExpectedToWrite;
//代理
@property (weak, nonatomic) id<QSPDownloadSourceDelegate> delegate;

@end



@class QSPDownloadTool;
@protocol QSPDownloadToolDelegate <NSObject>

- (void)downloadTool:(QSPDownloadTool *)tool downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;

@end

@interface QSPDownloadTool : NSObject

+ (instancetype)shareInstance;


/**
 添加下载任务

 @param netPath 下载地址
 @param delegate 代理对象
 @return 下载任务数据模型
 */
- (QSPDownloadSource *)addDownloadTast:(NSString *)netPath andDelegate:(id<QSPDownloadToolDelegate>)delegate;

/**
 移除代理

 @param delegate 代理对象
 */
- (void)removeDownloadToolDelegate:(id<QSPDownloadToolDelegate>)delegate;

/**
 暂停下载任务

 @param source 下载任务数据模型
 */
- (void)suspendDownload:(QSPDownloadSource *)source;

/**
 继续下载任务

 @param source 下载任务数据模型
 */
- (void)continueDownload:(QSPDownloadSource *)source;

/**
 停止下载任务

 @param source 下载任务数据模型
 */
- (void)stopDownload:(QSPDownloadSource *)source;

@end
