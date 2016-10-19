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
#import <CommonCrypto/CommonCrypto.h>

@interface MFResumeDownloadOperation ()

@property (nonatomic, strong) NSMutableArray<MFResumeDownloadModel *> *downloadList;
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
        if (downloadModel.state == MFRDDownloading) {
            downloadModel.state = MFRDPause;
        }
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

- (MFResumeDownloadResult)downloadFileWithUrl:(NSString *)urlString progress:(DownloadProgressBlock)progressBlock success:(DownloadSuccessBlock)successBlock failure:(DownloadFailureBlock)failureBlock
{
    return  [self downloadFileWithUrl:urlString fileName:nil progress:progressBlock success:successBlock failure:failureBlock];
}

- (MFResumeDownloadResult)downloadFileWithUrl:(NSString *)urlString fileName:(NSString *)fileName progress:(DownloadProgressBlock)progressBlock success:(DownloadSuccessBlock)successBlock failure:(DownloadFailureBlock)failureBlock
{
    MFResumeDownloadResult downloadResult = [self prepareDownload:urlString];
    if (downloadResult == MFResumeDownloadResultExistFinishFile) {
        return downloadResult;
    }
    
    BOOL isFileUrlExist = NO;
    for (MFResumeDownloadModel *downloadModel in self.downloadList) {
        if ([urlString isEqualToString:downloadModel.url]) {
            isFileUrlExist = YES;
            
            if (downloadModel.operation) {
                if ([downloadModel.operation isExecuting]) {
                    return downloadResult;
                } else {
                    [downloadModel.operation cancel];
                }
            }

        }
    }

    NSURL *fileUrl = [NSURL URLWithString:urlString];
    if (!fileName) {
        fileName = [fileUrl lastPathComponent];
    }
    
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
        
        if (progressBlock) {
            progressBlock(progress, totalMBRead, totalMBSize);
        }
    }];
    
    // 成功和失败回调
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [weakSelf updateCompletion:urlString];
        if (successBlock) {
            successBlock(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if([error code] != NSURLErrorCancelled) {
            [weakSelf updateFail:urlString];
            if (failureBlock) {
                failureBlock(operation, error);
            }
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
    }
    
    [self saveDownloadListToLocal];
    
    [operation start];

    
    return downloadResult;
}

- (MFResumeDownloadResult)prepareDownload:(NSString *)fileUrl
{
    MFResumeDownloadModel *downloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    
    if (!downloadModel) {
        return MFResumeDownloadResultOk;
    }
    
    MFRDState state = downloadModel.state;
    
    if (state == MFRDFinish) {
        return MFResumeDownloadResultExistFinishFile;
    } else if (state == MFRDFail) {
        NSString *hashname = downloadModel.hashname;
        NSString *localpath = [self filePath:hashname];
        [self removeDownloadFileIfExist:localpath];
        [self removeDownloadList:downloadModel];
    }
    
    return MFResumeDownloadResultOk;
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadProgressWithFileUrl:downloadModel:)]) {
        [self.delegate downloadProgressWithFileUrl:fileUrl downloadModel:resumeDownloadModel];
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
    
    if ([currentDate timeIntervalSinceDate:downloadSpeed.lastReadDate] >= 1) {
        NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:downloadSpeed.lastReadDate];
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadCompletedWithFileUrl:downloadModel:)]) {
        [self.delegate downloadCompletedWithFileUrl:fileUrl downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
}

- (void)updateFail:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    resumeDownloadModel.state = MFRDFail;
    
    [self resetDownloadSpeed:resumeDownloadModel];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadFailedWithFileUrl:downloadModel:)]) {
        [self.delegate downloadFailedWithFileUrl:fileUrl downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
}

- (void)updatePause:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    if (resumeDownloadModel.operation && [resumeDownloadModel.operation isPaused]) {
        resumeDownloadModel.state = MFRDPause;
    }
    
    [self resetDownloadSpeed:resumeDownloadModel];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadPausedWithFileUrl:downloadModel:)]) {
        [self.delegate downloadPausedWithFileUrl:fileUrl downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
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
    
    [self resetDownloadSpeed:resumeDownloadModel];
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadCanceledWithFileUrl:downloadModel:)]) {
        [self.delegate downloadCanceledWithFileUrl:fileUrl downloadModel:resumeDownloadModel];
    }
    
    [self saveDownloadListToLocal];
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
    
    AFHTTPRequestOperation *operation = resumeDownloadModel.operation;
    [operation pause];
    
    [self updatePause:fileUrl];
}

- (void)cancelDownloadWithFileUrl:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    AFHTTPRequestOperation *operation = resumeDownloadModel.operation;
    [operation cancel];
    
    [self updateCancel:fileUrl];
}

- (void)deleteDownloadWithFileUrl:(NSString *)fileUrl
{
    MFResumeDownloadModel *resumeDownloadModel = [self resumeDownloadModelWithFileUrl:fileUrl];
    if (!resumeDownloadModel) {
        return;
    }
    
    AFHTTPRequestOperation *operation = resumeDownloadModel.operation;
    [operation cancel];
    
    NSString *localpath = [self filePath:resumeDownloadModel.hashname];
    [self removeDownloadFileIfExist:localpath];
    [self removeDownloadList:resumeDownloadModel];
    [self saveDownloadListToLocal];
    
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
    return saveResult;
}


@end
