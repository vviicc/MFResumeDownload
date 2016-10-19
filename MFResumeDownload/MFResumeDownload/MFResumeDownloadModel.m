//
//  MFResumeDownloadModel.m
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import "MFResumeDownloadModel.h"

@implementation MFResumeDownloadSpeed

@end

@implementation MFResumeDownloadModel

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeObject:self.hashname forKey:@"hashname"];
    [aCoder encodeObject:self.filename forKey:@"filename"];
    [aCoder encodeFloat:self.totalMBRead forKey:@"totalMBRead"];
    [aCoder encodeFloat:self.totalMBSize forKey:@"totalMBSize"];
    [aCoder encodeFloat:self.progress forKey:@"progress"];
    [aCoder encodeInteger:self.state forKey:@"state"];
    [aCoder encodeDouble:self.finishTime forKey:@"finishTime"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.hashname = [aDecoder decodeObjectForKey:@"hashname"];
        self.filename = [aDecoder decodeObjectForKey:@"filename"];
        self.totalMBRead = [aDecoder decodeFloatForKey:@"totalMBRead"];
        self.totalMBSize = [aDecoder decodeFloatForKey:@"totalMBSize"];
        self.progress = [aDecoder decodeFloatForKey:@"progress"];
        self.state = [aDecoder decodeIntForKey:@"state"];
        self.finishTime = [aDecoder decodeDoubleForKey:@"finishTime"];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        MFResumeDownloadSpeed *downloadSpeed = [MFResumeDownloadSpeed new];
        downloadSpeed.totalBytesRead = 0;
        downloadSpeed.lastReadDate = nil;
        downloadSpeed.speed = 0;
        self.downloadSpeed = downloadSpeed;
    }
    
    return self;
}

@end
