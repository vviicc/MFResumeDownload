//
//  MFResumeDownloadModel.h
//  yylove
//
//  Created by Vic on 11/10/2016.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AFHTTPRequestOperation;

typedef NS_ENUM(NSUInteger, MFRDState) {
    MFRDQueue = 0, // 排队等待下载
    MFRDDownloading,
    MFRDPause,
    MFRDFinish,
    MFRDFail,
    MFRDCancel
};

typedef NS_ENUM(NSUInteger,MFRDAddTaskResult) {
    MFRDAddTaskResultSuccessStartDownloading = 0,   // 开始下载
    MFRDAddTaskResultSuccessAddDownloadQueue,       // 进入排队列表等待下载
    MFRDAddTaskResultAlreadyDownloading,            // 之前已经在下载了
    MFRDAddTaskResultAlreadyInDownloadQueue,        // 之前已经在等待下载列表中
    MFRDAddTaskResultAlreadyDownloaded              // 本地已经下载过了
};

typedef void(^AddDownloadTaskResultBlock)(MFRDAddTaskResult result);
typedef void(^DownloadProgressBlock)(CGFloat progress, CGFloat totalMBRead, CGFloat totalMBExpectedToRead);
typedef void(^DownloadSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void(^DownloadFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

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

@property (nonatomic, copy) DownloadProgressBlock progressBlock;

@property (nonatomic, copy) DownloadSuccessBlock successBlock;

@property (nonatomic, copy) DownloadFailureBlock failBlock;

@end
