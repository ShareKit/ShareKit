#import "SHKConfiguration.h"
#import "LegacySHKConfigurationDelegate.h"

static SHKConfiguration *sharedInstance = nil;

@implementation SHKConfiguration

#pragma mark -
#pragma mark class instance methods

#pragma mark -
#pragma mark Singleton methods

@synthesize delegate;

+ (SHKConfiguration*)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[SHKConfiguration alloc] initWithDelegate:[[LegacySHKConfigurationDelegate alloc] init]];
    }
    return sharedInstance;
}

+ (SHKConfiguration*)sharedInstanceWithDelegate:(id <SHKConfigurationDelegate>)delegate
{
    @synchronized(self)
    {
		if (sharedInstance != nil) {
			[NSException raise:@"IllegalStateException" format:@"SHKConfiguration has already been configured with a delegate."];
		}
		sharedInstance = [[SHKConfiguration alloc] initWithDelegate:delegate];
    }
    return sharedInstance;
}


+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)initWithDelegate:(id <SHKConfigurationDelegate>)delegateIn
{
    if ((self = [super init])) {
		delegate = delegateIn;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

- (id)configurationValue:(NSString*)selector
{
	NSLog(@"Looking for a configuration value for %@.", selector);
	NSString *value;
	SEL sel = NSSelectorFromString(selector);
	if ([delegate respondsToSelector:sel]) {
		value = [delegate performSelector:sel];
		if (value) {
			NSLog(@"Found configuration value for %@: %@", selector, value);
			return value;
		}
	}
	NSLog(@"Didn't find a configuration value for %@.", selector);
	return nil;
}

@end
