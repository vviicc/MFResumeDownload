//
//  MFResumeDownloadCommon.h
//  yylove
//
//  Created by Vic on 12/10/2016.
//
//

#ifndef MFResumeDownloadCommon_h
#define MFResumeDownloadCommon_h

static NSString * const kMFResumeDownloadDir = @"ResumeDownload";

#define MFRDManager [MFResumeDownloadManager sharedInstance]

#define safeBlock(block, ...) if((block)) { block(__VA_ARGS__); }

#define WEAKIFYSELF __weak __typeof(self) _weak_##self = self
#define STRONGIFYSELF __strong __typeof(self) self = _weak_##self

#endif /* MFResumeDownloadCommon_h */
