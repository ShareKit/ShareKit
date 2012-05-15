//
//  UploadViewController.h
//  ShareKit
//
//  Created by George Termentzoglou on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "SHKSharer.h"

@interface UploadViewController : UIViewController <DBRestClientDelegate>
{
    DBRestClient *restClient;
    
    NSString *filePath;
    
    NSString *fileName;
}
@property (retain, nonatomic) IBOutlet UILabel *statusLabel;

@property (retain, nonatomic) IBOutlet UILabel *fileNameLabel;
- (IBAction)upload:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)logout:(id)sender;

@end
