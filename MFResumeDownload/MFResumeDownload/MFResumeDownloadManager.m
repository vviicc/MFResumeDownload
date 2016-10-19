//
//  MFResumeDownloadManager.m
//  yylove
//
//  Created by Vic on 10/10/2016.
//
//

#import "MFResumeDownloadManager.h"


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
    _downloadOperation = [[MFResumeDownloadOperation alloc] init];
}

- (void)setDelegate:(id<MFResumeDownloadDelegate>)delegate
{
    if (delegate) {
        self.downloadOperation.delegate = delegate;
    }
}

- (MFResumeDownloadResult)downloadFileWithUrl:(NSString *)urlString
                                     progress:(DownloadProgressBlock)progressBlock
                                      success:(DownloadSuccessBlock)successBlock
                                      failure:(DownloadFailureBlock)failureBlock
{
    return [_downloadOperation downloadFileWithUrl:urlString progress:progressBlock success:successBlock failure:failureBlock];
}

- (MFResumeDownloadResult)downloadFileWithUrl:(NSString *)urlString
                                     fileName:(NSString *)fileName
                                     progress:(DownloadProgressBlock)progressBlock
                                      success:(DownloadSuccessBlock)successBlock
                                      failure:(DownloadFailureBlock)failureBlock
{
    return [_downloadOperation downloadFileWithUrl:urlString fileName:fileName progress:progressBlock success:successBlock failure:failureBlock];
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

@end
