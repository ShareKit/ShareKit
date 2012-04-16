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
	if (![UIPrintInteractionController class])
		return NO;

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
	if (![UIPrintInteractionController class])
		return NO;

	UIPrintInteractionController *printer = [UIPrintInteractionController sharedPrintController];
	UIPrintInfo *info = [UIPrintInfo printInfo];
	info.outputType = [[self.item customValueForKey:PRINT_INFO_OUTPUT_TYPE_KEY] isEqualToString:PRINT_INFO_OUTPUT_TYPE_VALUE_PHOTO] ? UIPrintInfoOutputPhoto: UIPrintInfoOutputGeneral;
    printer.printInfo = info;
	printer.showsPageRange = NO;
	printer.printingItem = item.image;
	UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printer,
															  BOOL completed, NSError *error) {
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		if (completed) {
			[self sendDidFinish];
		}
		else {
			[self sendDidFailWithError:error];
		}
	};

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIView *view = [SHK currentHelper].rootViewForCustomUIDisplay.view;
		CGSize viewSize = view.bounds.size;
		CGRect fromRect = CGRectMake(viewSize.width/2, viewSize.height/2,
									 viewSize.width, viewSize.height);
        [printer presentFromRect:fromRect inView:view animated:YES completionHandler:completionHandler];
	} else {
		[printer presentAnimated:YES completionHandler:completionHandler];
	}
	return YES;
}

@end
