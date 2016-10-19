//
//  MFResumeDownloadModel.h
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MFRDState) {
    MFRDDownloading = 0,
    MFRDPause,
    MFRDFinish,
    MFRDFail,
    MFRDCancel
};

@class AFHTTPRequestOperation;

@interface MFResumeDownloadSpeed : NSObject

@property (nonatomic, strong) NSDate *lastReadDate;
@property (nonatomic, assign) long long totalBytesRead;
@property (nonatomic, assign) long long speed;

@end

@interface MFResumeDownloadModel : NSObject<NSCoding>

@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) NSString *hashname;

@property (nonatomic, strong) NSString *filename;

@property (nonatomic, assign) CGFloat totalMBRead;

@property (nonatomic, assign) CGFloat totalMBSize;

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, assign) MFRDState state;

@property (nonatomic, assign) NSTimeInterval finishTime;

@property (nonatomic, strong) AFHTTPRequestOperation *operation;

@property (nonatomic, strong) MFResumeDownloadSpeed *downloadSpeed;

@end
