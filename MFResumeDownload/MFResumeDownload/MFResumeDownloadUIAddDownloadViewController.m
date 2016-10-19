//
//  MFResumeDownloadUIAddDownloadViewController.m
//  yylove
//
//  Created by Vic on 13/10/2016.
//
//

#import "MFResumeDownloadUIAddDownloadViewController.h"
#import "MFResumeDownloadManager.h"

static NSString * const kMFResumeDownloadUIAddDownloadCellIdentifier = @"kMFResumeDownloadUIAddDownloadCellIdentifier";

@interface MFResumeDownloadUIAddDownloadCell : UITableViewCell

- (void)updateCellWithName:(NSString *)filename url:(NSString *)fileUrl;

@end

@interface MFResumeDownloadUIAddDownloadCell ()

@property (nonatomic, weak) UILabel *filenameLabel;
@property (nonatomic, weak) UILabel *fileUrlLabel;
@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) UIButton *operationButton;

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *fileUrl;

@end

@implementation MFResumeDownloadUIAddDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self inits];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat superViewWidth = CGRectGetWidth(self.bounds);
    self.filenameLabel.frame = CGRectMake(20, 20, superViewWidth - 20 - 20, 16);
    self.fileUrlLabel.frame = CGRectMake(20, 40, superViewWidth - 20 - 20, 14);
    self.progressView.frame = CGRectMake(20, 60, superViewWidth - 20 - 20, 20);
    self.operationButton.frame = CGRectMake(20, 80, 120, 28);
}

- (void)inits
{
    [self initViews];
}

- (void)initViews
{
    UIView *contentView = self.contentView;
    
    UILabel *filenameLabel = [UILabel new];
    [contentView addSubview:filenameLabel];
    self.filenameLabel = filenameLabel;
    filenameLabel.textColor = [UIColor blackColor];
    filenameLabel.font = [UIFont systemFontOfSize:14];
    
    UILabel *fileUrlLabel = [UILabel new];
    [contentView addSubview:fileUrlLabel];
    _fileUrlLabel = fileUrlLabel;
    fileUrlLabel.textColor = [UIColor grayColor];
    fileUrlLabel.font = [UIFont systemFontOfSize:12];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [contentView addSubview:progressView];
    _progressView = progressView;
    progressView.progressTintColor = [UIColor blueColor];
    progressView.trackTintColor = [UIColor grayColor];
    
    UIButton *operationButton = [UIButton new];
    operationButton.backgroundColor = [UIColor whiteColor];
    [contentView addSubview:operationButton];
    _operationButton = operationButton;
    [operationButton setTitle:@"下载" forState:UIControlStateNormal];
    [operationButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [operationButton addTarget:self action:@selector(onClickOperation:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)onClickOperation:(id)sender
{
    MFResumeDownloadModel *downloadModel = [MFRDManager resumeDownloadModelWithFileUrl:self.fileUrl];
    
    __weak __typeof(self) weakSelf = self;
    
    if (!downloadModel || downloadModel.state == MFRDPause || downloadModel.state == MFRDFail || downloadModel.state == MFRDCancel) {
        [MFRDManager downloadFileWithUrl:self.fileUrl fileName:self.filename progress:^(CGFloat progress, CGFloat totalMBRead, CGFloat totalMBExpectedToRead) {
            [weakSelf updateDownloadProgress:progress];
        } success:nil failure:nil];
    } else if (downloadModel.state == MFRDDownloading) {
        [MFRDManager pauseDownloadWithFileUrl:self.fileUrl];
        [self updateDownloadPause];
    }
}

- (void)updateDownloadProgress:(CGFloat)progress
{
    [self.progressView setProgress:progress];
    
    if ([[self.operationButton titleForState:UIControlStateNormal] isEqualToString:@"下载"]) {
        [self.operationButton setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (void)updateDownloadPause
{
    if ([[self.operationButton titleForState:UIControlStateNormal] isEqualToString:@"暂停"]) {
        [self.operationButton setTitle:@"下载" forState:UIControlStateNormal];
    }
}

- (void)updateCellWithName:(NSString *)filename url:(NSString *)fileUrl
{
    _filename = filename;
    _fileUrl = fileUrl;
    
    self.filenameLabel.text = filename;
    self.fileUrlLabel.text = fileUrl;
}

@end

@interface MFResumeDownloadUIAddDownloadViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) UITableView *tableview;
@property (nonatomic, strong) NSArray *addDownloadData;

@end

@implementation MFResumeDownloadUIAddDownloadViewController

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
    
}

- (void)inits
{
    [self initViews];
    [self initData];
}

- (void)initViews
{
    UITableView *tableview = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:tableview];
    self.tableview = tableview;
    tableview.backgroundColor = [UIColor whiteColor];
    tableview.delegate = self;
    tableview.dataSource = self;
    tableview.rowHeight = 110;
    [tableview registerClass:[MFResumeDownloadUIAddDownloadCell class] forCellReuseIdentifier:kMFResumeDownloadUIAddDownloadCellIdentifier];
}

- (void)initData
{
    NSString *filename = @"filename";
    NSString *fileurl = @"fileurl";
    self.addDownloadData = @[@{filename:@"QQ_V5.1.2.dmg",fileurl:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.1.2.dmg"},
                         @{filename:@"SDWebImage.zip",fileurl:@"https://codeload.github.com/rs/SDWebImage/zip/master"},
                         @{filename:@"YYKit.zip",fileurl:@"https://codeload.github.com/ibireme/YYKit/zip/master"}
                         ];
}

#pragma mark - delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _addDownloadData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MFResumeDownloadUIAddDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:kMFResumeDownloadUIAddDownloadCellIdentifier forIndexPath:indexPath];
    
    NSDictionary *dict = self.addDownloadData[indexPath.row];
    NSString *filename = dict[@"filename"];
    NSString *fileurl = dict[@"fileurl"];
    
    [cell updateCellWithName:filename url:fileurl];
    
    return cell;
}

@end
