#import "SHKConfiguration.h"
#import "SHKPrint.h"

@implementation SHKPrint

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Print");
}

+ (BOOL)canShareText
{
	return NO;
}

+ (BOOL)canShareURL
{
	return NO;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareFile
{
	return NO;
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}

+ (BOOL)canShare
{
	return [UIPrintInteractionController isPrintingAvailable];
}

- (BOOL)shouldAutoShare
{
	return NO;
}

- (BOOL)send
{
	self.quiet = YES;
	
	if (![self validateItem])
		return NO;
	
	return [self print];
}

- (BOOL)print
{
	UIPrintInteractionController *printer = [UIPrintInteractionController sharedPrintController];
	UIPrintInfo *info = [UIPrintInfo printInfo];
	info.outputType = UIPrintInfoOutputPhoto;
	printer.printInfo = info;
	printer.showsPageRange = NO;
	printer.printingItem = item.image;
	[printer presentAnimated:YES completionHandler:^(UIPrintInteractionController *printer, BOOL completed, NSError *error) {
			[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
			if (completed) {
				[self sendDidFinish];
			}
			else {
				[self sendDidFailWithError:error];
			}
		}
	];
	return YES;
}

@end
