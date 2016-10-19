//
//  MFResumeDownloadDelegate.h
//  yylove
//
//  Created by Vic on 18/10/2016.
//
//

#import <Foundation/Foundation.h>

@protocol MFResumeDownloadDelegate <NSObject>

@optional

- (void)downloadProgressWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model;
- (void)downloadCompletedWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model;
- (void)downloadFailedWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model;
- (void)downloadPausedWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model;
- (void)downloadCanceledWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model;

@end
