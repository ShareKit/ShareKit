//
//  SHKUploadsViewCell.m
//  ShareKit
//
//  Created by Vilém Kurz on 25/01/14.
//
//

#import "SHKUploadsViewCell.h"

#import "SHK.h"
#import "SHKSharer.h"
#import "SHKUploadInfo.h"
#import "Debug.h"

#define SHOW_CHECKMARK 1 //scrolling is bad on iPhone4. If set to 0. "OK" shows up instead of checkmark for better performance.

#define FILENAME_LABEL_RECT CGRectMake(20, 6, 220, 15)
#define PROGRESS_LABEL_RECT CGRectMake(20, CGRectGetMaxY(self.progressView.frame), 220, 15)
#define FILENAME_LABEL_RECT_FINISHED CGRectMake(20, 8, 220, 15)
#define PROGRESS_LABEL_RECT_FINISHED CGRectMake(20, CGRectGetMaxY(self.progressView.frame)-2, 220, 15)

@interface SHKUploadsViewCell ()

@property (weak, nonatomic) SHKUploadInfo *uploadInfo;
@property (strong, nonatomic) NSByteCountFormatter *byteFormatter;

@end

@implementation SHKUploadsViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _byteFormatter = [[NSByteCountFormatter alloc] init];
        _byteFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
        _byteFormatter.zeroPadsFractionDigits = YES;
    }
    
    return self;
}

- (void)setupLayout {
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //self.filenameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 2, 235, 15)];
    self.filenameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 6, 220, 15)];
    self.filenameLabel.font = [UIFont systemFontOfSize:10];
    self.filenameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.filenameLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:self.filenameLabel];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(20, CGRectGetMaxY(self.filenameLabel.frame)+2, 220, self.progressView.frame.size.height);
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.progressView];
    
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.progressView.frame), 220, 15)];
    self.progressLabel.font = [UIFont systemFontOfSize:8];
    self.progressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.progressLabel];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.actionButton.frame = CGRectMake(250, 0, 60, 40);
    [self.actionButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    self.actionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.contentView addSubview:self.actionButton];
    
    /*
    NSDictionary *views = NSDictionaryOfVariableBindings(_filenameLabel, _progressLabel, _progressView);
    
    self.filenameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *metric = @{@"spacing": @5};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[_filenameLabel]-|" options:nil metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[_progressView]|" options:nil metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7-[_filenameLabel]-3-[_progressView]-3-[_progressLabel]-spacing-|" options:NSLayoutFormatAlignAllLeading metrics:metric views:views]];*/
}

- (void)updateWithUploadInfo:(SHKUploadInfo *)uploadInfo {
    
    self.uploadInfo = uploadInfo;
    
    self.filenameLabel.text = SHKLocalizedString(@"%@ (%@)", uploadInfo.filename, uploadInfo.sharerTitle);
    self.progressView.progress = uploadInfo.uploadProgress;
    
    //SHKLog(@"showProgress:%f sharer:%@", uploadInfo.uploadProgress, uploadInfo.sharerTitle);
    
    NSString *progressBytes = [self.byteFormatter stringFromByteCount:uploadInfo.bytesUploaded];
    NSString *totalBytes = [self.byteFormatter stringFromByteCount:uploadInfo.bytesTotal];
    NSString *bothBytesLabelText = SHKLocalizedString(@"%@ of %@", progressBytes, totalBytes);
    
    if (uploadInfo.uploadFinishedSuccessfully) {
        
        self.actionButton.enabled = NO;
        self.progressView.hidden = YES;
        self.filenameLabel.frame = FILENAME_LABEL_RECT_FINISHED;
        self.progressLabel.frame = PROGRESS_LABEL_RECT_FINISHED;
        self.progressLabel.text = totalBytes;
        
        if (SHOW_CHECKMARK) {
            [self.actionButton setTitle:nil forState:UIControlStateNormal];
            self.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            [self.actionButton setTitle:SHKLocalizedString(@"OK") forState:UIControlStateNormal];
        }

    } else if (uploadInfo.uploadCancelled) {
        
        [self.actionButton setTitle:SHKLocalizedString(@"Cancelled") forState:UIControlStateNormal];
        self.actionButton.enabled = NO;
        self.progressView.hidden = NO;
        self.filenameLabel.frame = FILENAME_LABEL_RECT;
        self.progressLabel.frame = PROGRESS_LABEL_RECT;
        self.progressLabel.text = bothBytesLabelText;
        self.accessoryType = UITableViewCellAccessoryNone;
        
    } else if ([uploadInfo isFailed]) {
        
        [self.actionButton setTitle:SHKLocalizedString(@"Failed") forState:UIControlStateNormal];
        self.actionButton.enabled = NO;
        self.progressView.hidden = NO;
        self.filenameLabel.frame = FILENAME_LABEL_RECT;
        self.progressLabel.frame = PROGRESS_LABEL_RECT;
        self.progressLabel.text = bothBytesLabelText;
        self.accessoryType = UITableViewCellAccessoryNone;
        
    } else {
        
        [self.actionButton setTitle:SHKLocalizedString(@"Cancel") forState:UIControlStateNormal];
        self.actionButton.enabled = YES;
        self.progressView.hidden = NO;
        self.filenameLabel.frame = FILENAME_LABEL_RECT;
        self.progressLabel.frame = PROGRESS_LABEL_RECT;
        self.progressLabel.text = bothBytesLabelText;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)cancel {
    
    SHKSharer *sharer = self.uploadInfo.sharer;
    [sharer cancel];
}

@end
