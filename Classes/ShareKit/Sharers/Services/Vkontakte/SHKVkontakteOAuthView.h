//
//  SHKVkontakteOAuthView.h
//  forismatic
//
//  Created by MacBook on 05.12.11.
//  Copyright (c) 2011 Alterplay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHKVkontakteOAuthView : UIViewController <UIWebViewDelegate> 
{
	id delegate;
	UIWebView *vkWebView;
	NSString *appID;	
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) UIWebView *vkWebView;
@property (nonatomic, retain) NSString *appID;

- (NSString*)stringBetweenString:(NSString*)start 
                       andString:(NSString*)end 
                     innerString:(NSString*)str;

@end
