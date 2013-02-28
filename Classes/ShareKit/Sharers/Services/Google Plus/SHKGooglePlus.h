//
//  SHKGooglePlus.h
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

#import "SHKSharer.h"
#import "GPPShare.h"

@interface SHKGooglePlus : SHKSharer <GPPShareDelegate> {
    GPPShare *mGooglePlusShare;
    id<GPPShareBuilder> mShareBuilder;
}

@property (nonatomic, retain) GPPShare *mGooglePlusShare;
@property (nonatomic, retain) id<GPPShareBuilder> mShareBuilder;

@end