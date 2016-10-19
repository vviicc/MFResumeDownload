//
//  MFResumeDownloadStorage.h
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import <Foundation/Foundation.h>
#import "MFResumeDownloadModel.h"

@interface MFResumeDownloadStorage : NSObject

- (BOOL)saveDownloadList:(NSArray<MFResumeDownloadModel *> *)downloadList;

- (NSArray<MFResumeDownloadModel *> *)getDownloadList;

@end
