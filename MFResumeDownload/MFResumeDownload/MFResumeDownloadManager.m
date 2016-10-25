//
//  MFResumeDownloadManager.m
//  yylove
//
//  Created by Vic on 10/10/2016.
//
//

#import "MFResumeDownloadManager.h"

#define kMFRDMaxDownloadCount 2


@interface MFResumeDownloadManager ()

@property (nonatomic, strong) MFResumeDownloadOperation *downloadOperation;

@end

@implementation MFResumeDownloadManager

#pragma mark - 类方法

+ (instancetype)sharedInstance
{
    static MFResumeDownloadManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self inits];
    }
    
    return self;
}

- (void)inits
{
    self.onlyWifiDownload = YES;
    
    self.downloadOperation = [[MFResumeDownloadOperation alloc] init];
    self.maxDownloadCount = kMFRDMaxDownloadCount;

}

- (void)setDelegate:(id<MFResumeDownloadDelegate>)delegate
{
    if (delegate) {
        self.downloadOperation.delegate = delegate;
    }
}

- (void)setMaxDownloadCount:(NSUInteger)maxDownloadCount
{
    self.downloadOperation.maxDownloadCount = maxDownloadCount;
}

- (void)addDownloadTaskWithUrl:(NSString *)url
                        result:(AddDownloadTaskResultBlock)addTaskResultBlock
                      progress:(DownloadProgressBlock)progressBlock
                       success:(DownloadSuccessBlock)successBlock
                       failure:(DownloadFailureBlock)failureBlock
{
    [_downloadOperation addDownloadTaskWithUrl:url result:addTaskResultBlock progress:progressBlock success:successBlock failure:failureBlock];
}

- (void)addDownloadTaskWithUrl:(NSString *)url
                      filename:(NSString *)filename
                        result:(AddDownloadTaskResultBlock)addTaskResultBlock
                      progress:(DownloadProgressBlock)progressBlock
                       success:(DownloadSuccessBlock)successBlock
                       failure:(DownloadFailureBlock)failureBlock
{
    [_downloadOperation addDownloadTaskWithUrl:url filename:filename result:addTaskResultBlock progress:progressBlock success:successBlock failure:failureBlock];
}

- (void)pauseDownloadWithFileUrl:(NSString *)fileUrl
{
    [_downloadOperation pauseDownloadWithFileUrl:fileUrl];
}

- (void)cancelDownloadWithFileUrl:(NSString *)fileUrl
{
    [_downloadOperation cancelDownloadWithFileUrl:fileUrl];
}

- (void)deleteDownloadWithFileUrl:(NSString *)fileUrl
{
    [_downloadOperation deleteDownloadWithFileUrl:fileUrl];
}

- (NSMutableArray<MFResumeDownloadModel *> *)downloadList
{
    return [_downloadOperation downloadList];
}

- (MFResumeDownloadModel *)resumeDownloadModelWithFileUrl:(NSString *)fileUrl
{
    return [_downloadOperation resumeDownloadModelWithFileUrl:fileUrl];
}

- (void)autoDownloadUnFinishedTasks
{
    [_downloadOperation autoDownloadUnFinishedTasks];
}

@end
