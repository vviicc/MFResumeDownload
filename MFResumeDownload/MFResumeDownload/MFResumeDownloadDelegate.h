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

- (void)downloadProgressWithDownloadModel:(MFResumeDownloadModel *)model;
- (void)downloadStateChange:(MFRDState)state downloadModel:(MFResumeDownloadModel *)model;
- (void)downloadDeletedWithDownloadModel:(MFResumeDownloadModel *)model;

@end
