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

- (MFResumeDownloadResult)downloadFileWithUrl:(NSString *)urlString
                                     progress:(DownloadProgressBlock)progressBlock
                                      success:(DownloadSuccessBlock)successBlock
                                      failure:(DownloadFailureBlock)failureBlock;

- (MFResumeDownloadResult)downloadFileWithUrl:(NSString *)urlString
                                     fileName:(NSString *)fileName
                                     progress:(DownloadProgressBlock)progressBlock
                                      success:(DownloadSuccessBlock)successBlock
                                      failure:(DownloadFailureBlock)failureBlock;

- (void)pauseDownloadWithFileUrl:(NSString *)fileUrl;

- (void)cancelDownloadWithFileUrl:(NSString *)fileUrl;

- (void)deleteDownloadWithFileUrl:(NSString *)fileUrl;

- (NSMutableArray<MFResumeDownloadModel *> *)downloadList;

- (MFResumeDownloadModel *)resumeDownloadModelWithFileUrl:(NSString *)fileUrl;

@end
