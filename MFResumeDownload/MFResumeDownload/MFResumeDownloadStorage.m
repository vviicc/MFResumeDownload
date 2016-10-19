//
//  MFResumeDownloadStorage.m
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import "MFResumeDownloadStorage.h"
#import "MFResumeDownloadCommon.h"

static NSString * const kMFResumeDownloadArchiverName = @"download.archiver";

@implementation MFResumeDownloadStorage

- (BOOL)saveDownloadList:(NSArray<MFResumeDownloadModel *> *)downloadList
{
    if (downloadList.count == 0) {
        return NO;
    }
    
    NSString *archiverFilePath = [self archiverFilePath];
    BOOL success = [NSKeyedArchiver archiveRootObject:downloadList toFile:archiverFilePath];
    return success;
}

- (NSArray<MFResumeDownloadModel *> *)getDownloadList
{
    NSString *archiverFilePath = [self archiverFilePath];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:archiverFilePath];
}

- (NSString *)archiverFilePath
{
    NSString *downloadDir = [self downloadDir];
    NSString *filePath = [downloadDir stringByAppendingPathComponent:kMFResumeDownloadArchiverName];
    
    return filePath;
}

- (NSString *)downloadDir
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downloadDir = [NSString stringWithFormat:@"%@/%@", docPath, kMFResumeDownloadDir];
    
    return downloadDir;
}

@end
