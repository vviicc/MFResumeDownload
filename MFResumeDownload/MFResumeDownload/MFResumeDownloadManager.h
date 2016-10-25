//
//  MFResumeDownloadManager.h
//  yylove
//
//  Created by Vic on 10/10/2016.
//
//

#import <Foundation/Foundation.h>
#import "MFResumeDownloadOperation.h"
#import "MFResumeDownloadCommon.h"

@interface MFResumeDownloadManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<MFResumeDownloadDelegate> delegate;
@property (nonatomic, assign) NSUInteger maxDownloadCount;
@property (nonatomic, assign) BOOL onlyWifiDownload;

- (void)addDownloadTaskWithUrl:(NSString *)url
                        result:(AddDownloadTaskResultBlock)addTaskResultBlock
                      progress:(DownloadProgressBlock)progressBlock
                       success:(DownloadSuccessBlock)successBlock
                       failure:(DownloadFailureBlock)failureBlock;

- (void)addDownloadTaskWithUrl:(NSString *)url
                      filename:(NSString *)filename
                        result:(AddDownloadTaskResultBlock)addTaskResultBlock
                      progress:(DownloadProgressBlock)progressBlock
                       success:(DownloadSuccessBlock)successBlock
                       failure:(DownloadFailureBlock)failureBlock;

- (void)pauseDownloadWithFileUrl:(NSString *)fileUrl;

- (void)cancelDownloadWithFileUrl:(NSString *)fileUrl;

- (void)deleteDownloadWithFileUrl:(NSString *)fileUrl;

- (NSMutableArray<MFResumeDownloadModel *> *)downloadList;

- (MFResumeDownloadModel *)resumeDownloadModelWithFileUrl:(NSString *)fileUrl;

- (void)autoDownloadUnFinishedTasks;

@end
