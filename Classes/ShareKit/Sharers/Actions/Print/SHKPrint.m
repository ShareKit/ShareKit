
#import "SHKPrint.h"
#import "SharersCommonHeaders.h"

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
    info.outputType = self.item.printOutputType;
    printer.printInfo = info;
	printer.showsPageRange = NO;
	printer.printingItem = self.item.image;
	UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printer,
															  BOOL completed, NSError *error) {
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		if (completed) {
			[self sendDidFinish];
		} else if (!error) {
            [self sendDidCancel];
        } else {
            [self sendDidFailWithError:error];
        }
	};

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIView *view = [SHK currentHelper].rootViewForUIDisplay.view;
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
