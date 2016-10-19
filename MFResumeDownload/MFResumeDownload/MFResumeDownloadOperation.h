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

typedef void(^DownloadProgressBlock)(CGFloat progress, CGFloat totalMBRead, CGFloat totalMBExpectedToRead);
typedef void(^DownloadSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void(^DownloadFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef NS_ENUM(NSUInteger,MFResumeDownloadResult) {
    MFResumeDownloadResultOk = 0,
    MFResumeDownloadResultExistFinishFile   // 本地已经成功下载过
};

@property (nonatomic, weak) id<MFResumeDownloadDelegate> delegate;

#pragma mark - 实例方法

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
