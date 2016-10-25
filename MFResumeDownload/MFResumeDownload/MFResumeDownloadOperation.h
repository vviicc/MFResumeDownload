//
//  MFResumeDownloadOperation.h
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "MFResumeDownloadStorage.h"
#import "MFResumeDownloadDelegate.h"

@interface MFResumeDownloadOperation : NSObject


@property (nonatomic, weak) id<MFResumeDownloadDelegate> delegate;
@property (nonatomic, assign) NSUInteger maxDownloadCount;

#pragma mark - 实例方法

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
