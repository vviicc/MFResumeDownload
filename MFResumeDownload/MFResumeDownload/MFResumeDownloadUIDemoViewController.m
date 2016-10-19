//
//  MFResumeDownloadUIDemoViewController.m
//  yylove
//
//  Created by Vic on 13/10/2016.
//
//

#import "MFResumeDownloadUIDemoViewController.h"
#import "MFResumeDownloadManager.h"
#import "MFResumeDownloadUIAddDownloadViewController.h"

static NSString * const kMFResumeDownloadUIDemoCellIdentifier = @"kMFResumeDownloadUIDemoCellIdentifier";

@interface MFResumeDownloadUIDemoCell : UITableViewCell

- (void)updateModel:(MFResumeDownloadModel *)downloadModel;

@end

@interface MFResumeDownloadUIDemoCell ()

@property (nonatomic, weak) UILabel *filenameLabel;
@property (nonatomic, weak) UILabel *downloadStateLabel;
@property (nonatomic, weak) UILabel *fileUrlLabel;
@property (nonatomic, weak) UILabel *downloadInfoLabel;
@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) UIButton *operationButton;
@property (nonatomic, weak) UIButton *cancelButton;

@property (nonatomic, strong) MFResumeDownloadModel *downloadModel;

@end

@implementation MFResumeDownloadUIDemoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initViews];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat superViewWidth = CGRectGetWidth(self.bounds);
    
    self.filenameLabel.frame = CGRectMake(20, 20, superViewWidth - 100 - 20, 16);
    self.downloadStateLabel.frame = CGRectMake(superViewWidth - 100 - 20, 20, 100, 16);
    self.fileUrlLabel.frame = CGRectMake(20, 40, superViewWidth - 20 - 20, 16);
    self.downloadInfoLabel.frame = CGRectMake(20, 70, superViewWidth - 20 - 20, 16);
    self.progressView.frame = CGRectMake(20, 100, superViewWidth - 20 - 20, 20);
    self.operationButton.frame = CGRectMake(20, 120, 100, 30);
    self.cancelButton.frame = CGRectMake(160, 120, 100, 30);
}

- (void)initViews
{
    UIView *contentView = self.contentView;
    
    UILabel *filenameLabel = [UILabel new];
    [contentView addSubview:filenameLabel];
    self.filenameLabel = filenameLabel;
    filenameLabel.textColor = [UIColor blueColor];
    filenameLabel.font = [UIFont systemFontOfSize:14];
    
    UILabel *downloadStateLabel = [UILabel new];
    [contentView addSubview:downloadStateLabel];
    self.downloadStateLabel = downloadStateLabel;
    downloadStateLabel.textColor = [UIColor blackColor];
    downloadStateLabel.font = [UIFont systemFontOfSize:12];
    downloadStateLabel.textAlignment = NSTextAlignmentRight;
    
    UILabel *fileUrlLabel = [UILabel new];
    [contentView addSubview:fileUrlLabel];
    _fileUrlLabel = fileUrlLabel;
    fileUrlLabel.textColor = [UIColor grayColor];
    fileUrlLabel.font = [UIFont systemFontOfSize:12];
    
    UILabel *downloadInfoLabel = [UILabel new];
    [contentView addSubview:downloadInfoLabel];
    _downloadInfoLabel = downloadInfoLabel;
    downloadInfoLabel.textColor = [UIColor blackColor];
    downloadInfoLabel.font = [UIFont systemFontOfSize:15];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [contentView addSubview:progressView];
    _progressView = progressView;
    progressView.progressTintColor = [UIColor blueColor];
    progressView.trackTintColor = [UIColor grayColor];
    
    UIButton *operationButton = [UIButton new];
    [contentView addSubview:operationButton];
    _operationButton = operationButton;
    [operationButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [operationButton addTarget:self action:@selector(onClickOperation:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cancelButton = [UIButton new];
    [contentView addSubview:cancelButton];
    _cancelButton = cancelButton;
    [cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(onClickCancel:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)onClickOperation:(id)sender
{
    MFRDState state = self.downloadModel.state;
    if (state == MFRDDownloading) {
        [MFRDManager pauseDownloadWithFileUrl:self.downloadModel.url];
        [self.operationButton setTitle:@"继续下载" forState:UIControlStateNormal];
    } else if (state == MFRDFinish) {
        NSString *hashname = self.downloadModel.hashname;
        NSString *localpath = [self filePath:hashname];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"文件地址" message:localpath delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    } else if (state == MFRDPause || state == MFRDFail || state == MFRDCancel) {
        
        [MFRDManager downloadFileWithUrl:self.downloadModel.url fileName:self.downloadModel.filename progress:^(CGFloat progress, CGFloat totalMBRead, CGFloat totalMBExpectedToRead) {
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        }];
    }

}

- (NSString *)filePath:(NSString *)fileName
{
    NSString *downloadDir = [self downloadDir];
    NSString *filePath = [downloadDir stringByAppendingPathComponent:fileName];
    
    return filePath;
}

- (NSString *)downloadDir
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downloadDir = [NSString stringWithFormat:@"%@/%@", docPath, kMFResumeDownloadDir];
    
    return downloadDir;
}

- (void)onClickCancel:(id)sender
{
    MFRDState state = self.downloadModel.state;
    if (state == MFRDDownloading || state == MFRDPause) {
        [MFRDManager cancelDownloadWithFileUrl:self.downloadModel.url];
        [self updateModel:self.downloadModel];
    } else if (state == MFRDFinish || state == MFRDFail || state == MFRDCancel) {
        [MFRDManager deleteDownloadWithFileUrl:self.downloadModel.url];
        
        UIView *superView = self.superview;
        while (![superView isKindOfClass:[UITableView class]] && superView) {
            superView = superView.superview;
        }
        
        if (superView) {
            UITableView *tableView = (UITableView *)superView;
            MFResumeDownloadUIDemoViewController *demoVC = (MFResumeDownloadUIDemoViewController *)tableView.delegate;
            [demoVC performSelector:@selector(reloadAllData)];
        }
    }
}

- (void)updateModel:(MFResumeDownloadModel *)downloadModel
{
    self.downloadModel = downloadModel;
    
    self.filenameLabel.text = downloadModel.filename;
    self.fileUrlLabel.text = downloadModel.url;

    MFRDState state = downloadModel.state;
    if (state == MFRDDownloading) {
        self.downloadStateLabel.text = @"下载中";
        NSString *speed = [NSByteCountFormatter stringFromByteCount:downloadModel.downloadSpeed.speed countStyle:NSByteCountFormatterCountStyleFile];
        self.downloadInfoLabel.text = [NSString stringWithFormat:@"%@/s  %.2f MB / %.2f MB", speed, downloadModel.totalMBRead,downloadModel.totalMBSize];
        self.downloadInfoLabel.hidden = NO;
        [self.progressView setProgress:downloadModel.progress];
        self.progressView.hidden = NO;
        [self.operationButton setTitle:@"暂停" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    } else if (state == MFRDPause) {
        self.downloadStateLabel.text = @"已暂停";
        self.downloadInfoLabel.text = [NSString stringWithFormat:@"%.2f MB / %.2f MB",downloadModel.totalMBRead,downloadModel.totalMBSize];
        self.downloadInfoLabel.hidden = NO;
        [self.progressView setProgress:downloadModel.progress];
        self.progressView.hidden = NO;
        [self.operationButton setTitle:@"继续下载" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    } else if (state == MFRDFinish) {
        self.downloadStateLabel.text = @"下载完成";
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:downloadModel.finishTime];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
        NSString *finishDateString = [formatter stringFromDate:date];
        self.downloadInfoLabel.hidden = NO;
        self.downloadInfoLabel.text = [NSString stringWithFormat:@"下载完成: %@",finishDateString];
        self.progressView.hidden = YES;
        [self.operationButton setTitle:@"查看" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"删除" forState:UIControlStateNormal];
    } else if (state == MFRDFail) {
        self.downloadStateLabel.text = @"下载失败";
        self.downloadInfoLabel.hidden = YES;
        self.progressView.hidden = YES;
        [self.operationButton setTitle:@"重新下载" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"删除" forState:UIControlStateNormal];
    } else if (state == MFRDCancel) {
        self.downloadStateLabel.text = @"已取消";
        self.downloadInfoLabel.hidden = YES;
        self.progressView.hidden = YES;
        [self.operationButton setTitle:@"重新下载" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"删除" forState:UIControlStateNormal];
    }
}

@end

@interface MFResumeDownloadUIDemoViewController ()<UITableViewDelegate,UITableViewDataSource,MFResumeDownloadDelegate>

@property (nonatomic, weak) UITableView *tableview;
@property (nonatomic, weak) UIView *emptyTipView;
@property (nonatomic, weak) UILabel *emptyTipLabel;
@property (nonatomic, weak) UIButton *addDownloadButton;
@property (nonatomic, strong) NSMutableArray<MFResumeDownloadModel *> *downloadList;

@end

@implementation MFResumeDownloadUIDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self inits];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableview.frame = self.view.bounds;
    self.emptyTipView.frame = self.view.bounds;
    self.emptyTipLabel.frame = CGRectMake(0,0,CGRectGetWidth(self.view.bounds), 16);
    self.emptyTipLabel.center = self.view.center;
    self.addDownloadButton.frame = CGRectMake(0, 0, 200, 28);
    self.addDownloadButton.center = CGPointMake(self.emptyTipLabel.center.x, self.emptyTipLabel.center.y + 50);
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadAllData];
}

- (void)inits
{
    [self initViews];
    [self initDatas];
    MFRDManager.delegate = self;
}

- (void)initViews
{
    self.title = @"下载列表";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView *tableview = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:tableview];
    self.tableview = tableview;
    tableview.backgroundColor = [UIColor whiteColor];
    tableview.delegate = self;
    tableview.dataSource = self;
    tableview.rowHeight = 160;
    [tableview registerClass:[MFResumeDownloadUIDemoCell class] forCellReuseIdentifier:kMFResumeDownloadUIDemoCellIdentifier];
    
    UIView *emptyTipView = [UIView new];
    [self.view addSubview:emptyTipView];
    _emptyTipView = emptyTipView;
    
    UILabel *emptyTipLabel = [UILabel new];
    [emptyTipView addSubview:emptyTipLabel];
    _emptyTipLabel = emptyTipLabel;
    emptyTipLabel.text = @"没有历史下载数据";
    emptyTipLabel.textAlignment = NSTextAlignmentCenter;
    emptyTipLabel.textColor = [UIColor lightGrayColor];
    emptyTipLabel.font = [UIFont systemFontOfSize:16];
    
    UIButton *addDownloadButton = [UIButton new];
    [emptyTipView addSubview:addDownloadButton];
    _addDownloadButton = addDownloadButton;
    [addDownloadButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [addDownloadButton setTitle:@"去添加下载数据" forState:UIControlStateNormal];
    addDownloadButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [addDownloadButton addTarget:self action:@selector(addDownloadData:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)addDownloadData:(id)sender
{
    MFResumeDownloadUIAddDownloadViewController *addDownload = [MFResumeDownloadUIAddDownloadViewController new];
    [self.navigationController pushViewController:addDownload animated:YES];
}

- (void)initDatas
{
    NSMutableArray<MFResumeDownloadModel *> *downloadList = [[MFResumeDownloadManager sharedInstance] downloadList];
    self.downloadList = downloadList;
    
    [self reloadAllData];
}

- (void)reloadAllData
{
    if (self.downloadList.count > 0) {
        self.tableview.hidden = NO;
        self.emptyTipView.hidden = YES;
        [self.tableview reloadData];
    } else {
        self.tableview.hidden = YES;
        self.emptyTipView.hidden = NO;
    }
}



#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.downloadList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MFResumeDownloadUIDemoCell *cell = [tableView dequeueReusableCellWithIdentifier:kMFResumeDownloadUIDemoCellIdentifier forIndexPath:indexPath];
    MFResumeDownloadModel *downloadModel = self.downloadList[indexPath.row];
    [cell updateModel:downloadModel];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - MFResumeDownloadDelegate

#define MFResumeDownloadDemoReloadTableView \
[self.tableview reloadData];\
return;

- (void)downloadProgressWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model
{
    MFResumeDownloadDemoReloadTableView
}

- (void)downloadCompletedWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model
{
    MFResumeDownloadDemoReloadTableView
}

- (void)downloadFailedWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model
{
    MFResumeDownloadDemoReloadTableView
}

- (void)downloadPausedWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model
{
    MFResumeDownloadDemoReloadTableView
}

- (void)downloadCanceledWithFileUrl:(NSString *)fileUrl downloadModel:(MFResumeDownloadModel *)model
{
    MFResumeDownloadDemoReloadTableView
}


@end
