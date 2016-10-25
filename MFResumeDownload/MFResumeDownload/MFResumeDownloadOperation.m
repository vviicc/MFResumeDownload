//
//  MFResumeDownloadOperation.m
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import "MFResumeDownloadOperation.h"
#import "MFResumeDownloadModel.h"
#import "MFResumeDownloadCommon.h"
#import "MFResumeDownloadManager.h"
#import <CommonCrypto/CommonCrypto.h>


@interface MFResumeDownloadOperation ()

@property (nonatomic, strong) NSMutableArray<MFResumeDownloadModel *> *downloadList;
@property (nonatomic, strong) NSMutableArray<MFResumeDownloadModel *> *downloadingList;
@property (nonatomic, strong) NSMutableArray<MFResumeDownloadModel *> *preDownloadList;
@property (nonatomic, strong) MFResumeDownloadStorage *downloadStorage;

@end

@implementation MFResumeDownloadOperation

- (instancetype)init
{
    if (self = [super init]) {
        [self inits];
    }
    return self;
}

- (void)inits
{
    [self createDownloadDirIfNeeded];
    
    self.downloadStorage = [[MFResumeDownloadStorage alloc] init];
    self.downloadingList = [NSMutableArray array];
    self.preDownloadList = [NSMutableArray array];
    
    NSArray<MFResumeDownloadModel *> *savedDownloadList = [self.downloadStorage getDownloadList];
    if (savedDownloadList.count > 0) {
        [self updateSavedDownloadList:savedDownloadList];
        self.downloadList = [NSMutableArray arrayWithArray:savedDownloadList];
    } else {
        self.downloadList = [NSMutableArray array];
    }
}

- (void)updateSavedDownloadList:(NSArray<MFResumeDownloadModel *> *)savedDownloadList
{
    for (MFResumeDownloadModel *downloadModel in savedDownloadList) {
        NSString *hashname = downloadModel.hashname;
        NSString *localpath = [self filePath:hashname];
        downloadModel.totalMBRead = [self fileSizeForPath:localpath] / 1024 / 1024.0f;
        downloadModel.progress = downloadModel.totalMBRead / downloadModel.totalMBSize;
//        if (downloadModel.state == MFRDDownloading || downloadModel.state == MFRDQueue) {
//            downloadModel.state = MFRDPause;
//        }
    }
}

#pragma mark - 实例方法

- (unsigned long long)fileSizeForPath:(NSString *)path {
    
    signed long long fileSize = 0;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:path]) {
        
        NSError *error = nil;
        
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        
        if (!error && fileDict) {
            
            fileSize = [fileDict fileSize];
        }
    }
    
    return fileSize;
}

- (void)addDownloadTaskWithUrl:(NSString *)url
                        result:(AddDownloadTaskResultBlock)addTaskResultBlock
                      progress:(DownloadProgressBlock)progressBlock
                       success:(DownloadSuccessBlock)successBlock
                       failure:(DownloadFailureBlock)failureBlock
{
    [self addDownloadTaskWithUrl:url filename:nil result:addTaskResultBlock progress:progressBlock success:successBlock failure:failureBlock];
}

- (void)addDownloadTaskWithUrl:(NSString *)url
                      filename:(NSString *)filename
                        result:(AddDownloadTaskResultBlock)addTaskResultBlock
                      progress:(DownloadProgressBlock)progressBlock
                       success:(DownloadSuccessBlock)successBlock
                       failure:(DownloadFailureBlock)failureBlock
{
    WEAKIFYSELF;
    [self prepareDownloadTaskWithUrl:url filename:filename result:^(MFRDAddTaskResult result) {
        STRONGIFYSELF;
        safeBlock(addTaskResultBlock,result);
        [self handleAddTaskResult:result url:url filename:filename progress:progressBlock success:successBlock failure:failureBlock];
    } progress:progressBlock success:successBlock failure:failureBlock];
}

- (void)handleAddTaskResult:(MFRDAddTaskResult)result
                        url:(NSString *)url
                   filename:(NSString *)filename
                   progress:(DownloadProgressBlock)progressBlock
                    success:(DownloadSuccessBlock)successBlock
                    failure:(DownloadFailureBlock)failureBlock
{
    MFResumeDownloadModel *downloadModel = [self resumeDownloadModelWithFileUrl:url];
    
    if (result == MFRDAddTaskResultSuccessStartDownloading) {
        [self.downloadingList addObject:downloadModel];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadStateChange:downloadModel:)]) {
            [self.delegate downloadStateChange:MFRDDownloading downloadModel:downloadModel];
        }
        [self downloadFileWithUrl:url fileName:filename progress:progressBlock success:successBlock failure:failureBlock];
        
    } else if (result == MFRDAddTaskResultSuccessAddDownloadQueue) {
        [self.preDownloadList addObject:downloadModel];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadStateChange:downloadModel:)]) {
            [self.delegate downloadStateChange:MFRDQueue downloadModel:downloadModel];
        }
    }
}

- (void)prepareDownloadTaskWithUrl:(NSString *)url
                          filename:(NSString *)filename
                            result:(AddDownloadTaskResultBlock)addTaskResultBlock
                          progress:(DownloadProgressBlock)progressBlock
                           success:(DownloadSuccessBlock)successBlock
                           failure:(DownloadFailureBlock)failureBlock
{
    MFResumeDownloadModel *downloadModel = [self resumeDownloadModelWithFileUrl:url];
    
    if (downloadModel && downloadModel.state == MFRDQueue && [self.preDownloadList containsObject:downloadModel]) {
        safeBlock(addTaskResultBlock,MFRDAddTaskResultAlreadyInDownloadQueue);
        return;
    }
    
    if (downloadModel && downloadModel.state == MFRDDownloading && [self.downloadingList containsObject:downloadModel]) {
        safeBlock(addTaskResultBlock,MFRDAddTaskResultAlreadyDownloading);
        return;
    }
    
    if (downloadModel && downloadModel.state == MFRDFinish) {
        safeBlock(addTaskResultBlock,MFRDAddTaskResultAlreadyDownloaded);
        return;
    }
    
    if (downloadModel && downloadModel.state == MFRDFail) {
        NSString *hashname = downloadModel.hashname;
        NSString *localpath = [self filePath:hashname];
        [self removeDownloadFileIfExist:localpath];
        [self removeDownloadList:downloadModel];
    }
    
    BOOL startDownloadNow = [self ableToStartDownloadNow];
    MFRDState state = startDownloadNow ? MFRDDownloading : MFRDQueue;
    [self updateDownloadModelWithUrl:url filename:filename state:state progress:progressBlock success:successBlock failure:failureBlock];
    
    safeBlock(addTaskResultBlock,startDownloadNow ? MFRDAddTaskResultSuccessStartDownloading : MFRDAddTaskResultSuccessAddDownloadQueue);
    
}

- (void)updateDownloadModelWithUrl:(NSString *)url
                          filename:(NSString *)filename
                             state:(MFRDState)state
                          progress:(DownloadProgressBlock)progressBlock
                           success:(DownloadSuccessBlock)successBlock
                           failure:(DownloadFailureBlock)failureBlock
{
    MFResumeDownloadModel *downloadModel = [self resumeDownloadModelWithFileUrl:url];
    
    if (!downloadModel) {
        MFResumeDownloadModel *newDownloadModel = [MFResumeDownloadModel new];
        newDownloadModel.url = url;
        newDownloadModel.filename = filename;
        newDownloadModel.hashname = [self stringToMD5:url];
        newDownloadModel.totalMBRead = 0;
        newDownloadModel.progress = 0;
        newDownloadModel.state = state;
        newDownloadModel.progressBlock = progressBlock;
        newDownloadModel.successBlock = successBlock;
        newDownloadModel.failBlock = failureBlock;
        
        [self.downloadList addObject:newDownloadModel];
    } else {
        downloadModel.state = state;
        downloadModel.progressBlock = progressBlock;
        downloadModel.successBlock = successBlock;
        downloadModel.failBlock = failureBlock;
        
        if (downloadModel.operation && ![downloadModel.operation isCancelled]) {
            [downloadModel.operation cancel];
        }
    }
    
    [self saveDownloadListToLocal];

}

- (BOOL)ableToStartDownloadNow
{
    BOOL startDownload = NO;
    if (self.downloadingList.count < self.maxDownloadCount && self.preDownloadList.count == 0) {
        startDownload = YES;
    }
    return startDownload;
}

- (void)downloadFileWithUrl:(NSString *)urlString fileName:(NSString *)fileName progress:(DownloadProgressBlock)progressBlock success:(DownloadSuccessBlock)successBlock failure:(DownloadFailureBlock)failureBlock
{
    BOOL isFileUrlExist = NO;
    for (MFResumeDownloadModel *downloadModel in self.downloadList) {
        if ([urlString isEqualToString:downloadModel.url]) {
            isFileUrlExist = YES;
            
            if (downloadModel.operation) {
                if ([downloadModel.operation isExecuting]) {
                    return;
                } else {
                    [downloadModel.operation cancel];
                }
            }

        }
    }

    NSURL *fileUrl = [NSURL URLWithString:urlString];
    
    NSString *filePath = [self filePath:[self stringToMD5:urlString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:fileUrl];
    unsigned long long downloadedBytes = 0;
    
    NSLog(@"%s -> Line:%d -> FilePath:\n%@", __func__, __LINE__, filePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        // 获取已下载的文件长度
        downloadedBytes = [self fileSizeForPath:filePath];
        
        // 检查文件是否已经下载了一部分
        if (downloadedBytes > 0) {
            
            NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
            request = mutableURLRequest;
        }
    }
    
    // 不使用缓存，避免断点续传出现问题
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    
    // 下载请求
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // 下载路径
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:YES];
    
    __weak MFResumeDownloadOperation *weakSelf = self;
    
    // 下载进度回调
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        NSLog(@"bytesRead:%lu---totalBytesRead:%lld---totalBytesExpectedToRead:%lld",(unsigned long)bytesRead,totalBytesRead,totalBytesExpectedToRead);
        // 下载进度
        CGFloat progress = ((CGFloat)totalBytesRead + downloadedBytes) / (totalBytesExpectedToRead + downloadedBytes);
        
        CGFloat totalMBRead = (totalBytesRead + downloadedBytes) / 1024 / 1024.0f;
        CGFloat totalMBSize = (totalBytesExpectedToRead + downloadedBytes) / 1024 / 1024.0f;
        
        [weakSelf updateProgress:urlString totalMBRead:totalMBRead totalMBSize:totalMBSize progress:progress bytesRead:bytesRead];
        
        safeBlock(progressBlock,progress,totalMBRead,totalMBSize);
    }];
    
    // 成功和失败回调
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [weakSelf updateCompletion:urlString];
        safeBlock(successBlock ,operation,responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if([error code] != NSURLErrorCancelled) {
            [weakSelf updateFail:urlString];
            safeBlock(failureBlock,operation,error);
        }
    }];
    
    if (isFileUrlExist) {
        MFResumeDownloadModel *downloadModel = [self resumeDownloadModelWithFileUrl:urlString];
        downloadModel.operation = operation;
    } else {
        MFResumeDownloadModel *downloadModel = [MFResumeDownloadModel new];
        downloadModel.url = urlString;
        downloadModel.hashname = [self stringToMD5:urlString];
        downloadModel.filename = fileName;
        downloadModel.totalMBRead = 0;
        downloadModel.progress = 0;
        downloadModel.state = MFRDDownloading;
        downloadModel.operation = operation;
        
        [self.downloadList addObject:downloadModel];
        [self saveDownloadListToLocal];
    }
    
    
    [operation start];
    
}

- (BOOL)removeDownloadFileIfExist:(NSString *)filepath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filepath error:&error];
        return success;
    }
    return YES;
}

- (void)removeDownloadList:(MFResumeDownloadModel *)downloadModel
{
    [self.downloadList removeObject:downloadModel];
}

- (void)updateProgress:(NSString *)fileUrl totalMBRead:(CGFloat)totalMBRead totalMBSize:(CGFloat)totalMBSize progress:(CGFloat)progress bytesRead:(long long)bytesRead
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    resumeDownloadModel.totalMBRead = totalMBRead;
    resumeDownloadModel.totalMBSize = totalMBSize;
    resumeDownloadModel.progress = progress;
    
    if (resumeDownloadModel.operation && [resumeDownloadModel.operation isExecuting]) {
        resumeDownloadModel.state = MFRDDownloading;
    }
    
    [self updateDownloadSpeed:resumeDownloadModel bytesRead:bytesRead];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadProgressWithDownloadModel:)]) {
        [self.delegate downloadProgressWithDownloadModel:resumeDownloadModel];
    }
}

- (void)updateDownloadSpeed:(MFResumeDownloadModel *)resumeDownloadModel bytesRead:(long long)bytesRead
{
    if (resumeDownloadModel.downloadSpeed == nil) {
        resumeDownloadModel.downloadSpeed = [MFResumeDownloadSpeed new];
    }
    
    MFResumeDownloadSpeed *downloadSpeed = resumeDownloadModel.downloadSpeed;
    NSDate *currentDate = [NSDate date];
    downloadSpeed.totalBytesRead += bytesRead;
    
    if (!downloadSpeed.lastReadDate) {
        downloadSpeed.lastReadDate = currentDate;
    }
    
    
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:downloadSpeed.lastReadDate];
    if (timeInterval >= 1 || (downloadSpeed.speed == 0 && timeInterval != 0)) {
        long long speed = downloadSpeed.totalBytesRead / timeInterval;
        downloadSpeed.speed = speed;
        downloadSpeed.totalBytesRead = 0;
        downloadSpeed.lastReadDate = currentDate;
    }
}

- (void)resetDownloadSpeed:(MFResumeDownloadModel *)resumeDownloadModel
{
    MFResumeDownloadSpeed *downloadSpeed = resumeDownloadModel.downloadSpeed;
    downloadSpeed.totalBytesRead = 0;
    downloadSpeed.lastReadDate = nil;
    downloadSpeed.speed = 0;
}

- (void)updateCompletion:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    resumeDownloadModel.progress = 1;
    resumeDownloadModel.state = MFRDFinish;
    resumeDownloadModel.finishTime = [[NSDate date] timeIntervalSince1970];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadStateChange:downloadModel:)]) {
        [self.delegate downloadStateChange:MFRDFinish downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
    [self downloadFromQueueListWhenDownloadStateChanged:fileUrl];
}

- (void)updateFail:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    resumeDownloadModel.state = MFRDFail;
    
    [self resetDownloadSpeed:resumeDownloadModel];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadStateChange:downloadModel:)]) {
        [self.delegate downloadStateChange:MFRDFail downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
    [self downloadFromQueueListWhenDownloadStateChanged:fileUrl];

}

- (void)updatePause:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    if (resumeDownloadModel.state == MFRDDownloading && resumeDownloadModel.operation && [resumeDownloadModel.operation isPaused]) {
        resumeDownloadModel.state = MFRDPause;
    }
    
    if (resumeDownloadModel.state == MFRDQueue) {
        resumeDownloadModel.state = MFRDPause;
    }
    
    [self resetDownloadSpeed:resumeDownloadModel];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadStateChange:downloadModel:)]) {
        [self.delegate downloadStateChange:MFRDPause downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
    [self downloadFromQueueListWhenDownloadStateChanged:fileUrl];

}

- (void)updateCancel:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    if (resumeDownloadModel.operation && [resumeDownloadModel.operation isCancelled]) {
        resumeDownloadModel.state = MFRDCancel;
    }
    
    if (resumeDownloadModel.state == MFRDQueue) {
        resumeDownloadModel.state = MFRDCancel;
    }
    
    [self resetDownloadSpeed:resumeDownloadModel];
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadStateChange:downloadModel:)]) {
        [self.delegate downloadStateChange:MFRDCancel downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
    [self downloadFromQueueListWhenDownloadStateChanged:fileUrl];

}

- (void)updateDelete:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    [self downloadFromQueueListWhenDownloadStateChanged:fileUrl];
    
    NSString *localpath = [self filePath:resumeDownloadModel.hashname];
    [self removeDownloadFileIfExist:localpath];
    [self removeDownloadList:resumeDownloadModel];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadDeletedWithDownloadModel:)]) {
        [self.delegate downloadDeletedWithDownloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];

}

- (void)downloadFromQueueListWhenDownloadStateChanged:(NSString *)url
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:url];
    if (!resumeDownloadModel) {
        return;
    }
    
    [self.downloadingList removeObject:resumeDownloadModel];
    [self.preDownloadList removeObject:resumeDownloadModel];
    
    if (self.downloadingList.count < self.maxDownloadCount && self.preDownloadList.count > 0) {
        MFResumeDownloadModel *downloadModel = self.preDownloadList.firstObject;
        [self.preDownloadList removeObject:downloadModel];
        [self.downloadingList addObject:downloadModel];
        [self downloadFileWithUrl:downloadModel.url fileName:downloadModel.filename progress:downloadModel.progressBlock success:downloadModel.successBlock failure:downloadModel.failBlock];
    }
}

- (void)saveDownloadListToLocal
{
    [self.downloadStorage saveDownloadList:self.downloadList];
}

- (MFResumeDownloadModel *)resumeDownloadModelWithFileUrl:(NSString *)fileUrl
{
    for (MFResumeDownloadModel *resumeDownloadModel in self.downloadList) {
        if ([resumeDownloadModel.url isEqualToString:fileUrl]) {
            return resumeDownloadModel;
        }
    }
    
    return nil;
}

- (void)autoDownloadUnFinishedTasks
{
    NSMutableArray<MFResumeDownloadModel *> *preDownloadList = [NSMutableArray array];
    
    for (MFResumeDownloadModel *downloadModel in self.downloadList) {
        if (downloadModel.state == MFRDDownloading) {
            [self addDownloadTaskWithUrl:downloadModel.url filename:downloadModel.filename result:nil progress:nil success:nil failure:nil];
        } else if (downloadModel.state == MFRDQueue) {
            [preDownloadList addObject:downloadModel];
        }
    }
    
    for (MFResumeDownloadModel *downloadModel in preDownloadList) {
        [self addDownloadTaskWithUrl:downloadModel.url filename:downloadModel.filename result:nil progress:nil success:nil failure:nil];
    }
}

- (NSString *)filePath:(NSString *)fileName
{
    NSString *downloadDir = [self downloadDir];
    NSString *filePath = [downloadDir stringByAppendingPathComponent:fileName];
    
    return filePath;
}

- (NSString *)downloadDir
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downloadDir = [NSString stringWithFormat:@"%@/%@", docPath, kMFResumeDownloadDir];
    
    return downloadDir;
}

- (void)createDownloadDirIfNeeded
{
    NSString *downloadDir = [self downloadDir];
    
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:downloadDir isDirectory:&isDir];
    
    if (!(isDir == YES && existed == YES)) {
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)pauseDownloadWithFileUrl:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    if (resumeDownloadModel.state == MFRDDownloading) {
        AFHTTPRequestOperation *operation = resumeDownloadModel.operation;
        if (operation && ![operation isPaused]) {
            [operation pause];
        }
    }
    
    [self updatePause:fileUrl];
}

- (void)cancelDownloadWithFileUrl:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    if (resumeDownloadModel.state == MFRDDownloading || resumeDownloadModel.state == MFRDPause || resumeDownloadModel.state == MFRDFail) {
        AFHTTPRequestOperation *operation = resumeDownloadModel.operation;
        if (operation && ![operation isCancelled]) {
            [operation cancel];
        }
    }
    
    [self updateCancel:fileUrl];
}

- (void)deleteDownloadWithFileUrl:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    if (resumeDownloadModel.state == MFRDDownloading || resumeDownloadModel.state == MFRDPause || resumeDownloadModel.state == MFRDFail) {
        AFHTTPRequestOperation *operation = resumeDownloadModel.operation;
        if (operation && ![operation isCancelled]) {
            [operation cancel];
        }
    }
    
    [self updateDelete:fileUrl];
    
}

- (NSMutableArray<MFResumeDownloadModel *> *)downloadList
{
    return _downloadList;
}

- (NSString *)stringToMD5:(NSString *)str
{
    const char *fooData = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(fooData, (CC_LONG)strlen(fooData), result);
    NSMutableString *saveResult = [NSMutableString string];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [saveResult appendFormat:@"%02x", result[i]];
    }
    
    NSString *ext = str.pathExtension;
    if (ext.length > 0) {
        [saveResult appendFormat:@".%@",ext];
    }
    return saveResult;
}


@end
