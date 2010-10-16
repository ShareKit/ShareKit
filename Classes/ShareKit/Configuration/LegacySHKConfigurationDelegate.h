//
//  DefaultSHKConfiguration.h
//  ShareKit
//
//  Created by Edward Dale on 16.10.10.
//  Copyright 2010 RIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKConfiguration.h"

@interface LegacySHKConfigurationDelegate : NSObject <SHKConfigurationDelegate>  {
	NSDictionary *configuration;
}

@end
