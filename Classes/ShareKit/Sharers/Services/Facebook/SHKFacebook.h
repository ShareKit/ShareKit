//
//  SHKFacebook.h
//  ShareKit
//
//  Created by Colin Humber on 1/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKSharer.h"
#import "FBConnect.h"

typedef enum 
{
	SHKFacebookPendingNone,
	SHKFacebookPendingLogin,
	SHKFacebookPendingStatus,
	SHKFacebookPendingImage,
	SHKFacebookPendingLink
} SHKFacebookPendingAction;

@interface SHKFacebook : SHKSharer <FBSessionDelegate, FBRequestDelegate> {
	Facebook *facebook;
	SHKFacebookPendingAction pendingFacebookAction;
	NSArray *permissions;
}

@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic, assign) SHKFacebookPendingAction pendingFacebookAction;

@end
