//
//  SHKConfiguration.m
//  ShareKit
//
//  Created by Edward Dale on 10/16/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKConfiguration.h"
#import "DefaultSHKConfigurator.h"
#import "SuppressPerformSelectorWarning.h"

@interface SHKConfiguration ()

@property (readonly, strong) DefaultSHKConfigurator *configurator;

- (id)initWithConfigurator:(DefaultSHKConfigurator*)config;

@end

static SHKConfiguration *sharedInstance = nil;

@implementation SHKConfiguration

#pragma mark -
#pragma mark Instance methods

- (id)configurationValue:(NSString*)selector withObject:(id)object
{
	//SHKLog(@"Looking for a configuration value for %@.", selector);

	SEL sel = NSSelectorFromString(selector);
	if ([self.configurator respondsToSelector:sel]) {
		id value;        
        if (object) {
            SuppressPerformSelectorLeakWarning(value = [self.configurator performSelector:sel withObject:object]);
        } else {
            SuppressPerformSelectorLeakWarning(value = [self.configurator performSelector:sel]);
        }

		if (value) {
			//SHKLog(@"Found configuration value for %@: %@", selector, [value description]);
			return value;
		}
	}

	//SHKLog(@"Configuration value is nil or not found for %@.", selector);
	return nil;
}

#pragma mark -
#pragma mark Singleton methods

// Singleton template based on http://stackoverflow.com/questions/145154

+ (SHKConfiguration*)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil) {
            [NSException raise:@"IllegalStateException" format:@"ShareKit must be configured before use. Use your subclass of DefaultSHKConfigurator, for more info see https://github.com/ShareKit/ShareKit/wiki/Configuration. Example: ShareKitDemoConfigurator in the demo app"];
        }
    }
    return sharedInstance;
}

+ (SHKConfiguration*)sharedInstanceWithConfigurator:(DefaultSHKConfigurator*)config
{
    if (sharedInstance != nil) {
		[NSException raise:@"IllegalStateException" format:@"SHKConfiguration has already been configured with a delegate."];
    }
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] initWithConfigurator:config];
    });
    
    return sharedInstance;
}

- (id)initWithConfigurator:(DefaultSHKConfigurator*)config
{
    if ((self = [super init])) {
		_configurator = config;
    }
    return self;
}

@end
