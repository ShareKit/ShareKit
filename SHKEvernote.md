# Using SHKEvernote

SHKEvernote supports sharing links, images, text and files.
In default:

+ Links and text will be sent as rich text format.
+ Images and files will be sent as attachments.

Evernote's consumer and secret key are required.
Request an API Key from [Evernote API Overview](http://www.evernote.com/about/developer/api/) page.

When you received an API Key, define them to `SHKEvernoteConsumerKey` and `SHKEvernoteSecretKey` constants in `SHKConfig.h`.


## Sending custom EDAM content
If you want to send custom EDAM content, use `SHKEvernoteItem` instead of `SHKItem`.

This is a subclass of SHKItem, extended for support `(EDAMNote *)note` property.


	#import SHKEvernote.h
	
	...
	
	NSString *noteTitle = @"My custom evernote.";
	
	EDAMNote *note = [[[EDAMNote alloc] init] autorelease];
	
	// Note content as mutable string
	// kENMLPrefix and kENMLSuffix are defined in SHKEvernote.h
	NSMutableString *content = [NSMutableString stringWithString:kENMLPrefix];
	// Resources to embed
	NSMutableArray *resources = [NSMutableArray array];

	[content appendString:@"<p><a href=\"http://www.apple.com/\">Apple </a></p>"];

	// Image to clip
	NSString *myImageURL = @"http://images.apple.com/iphone/home/images/route-facetime-20100923.png";
	
	EDAMResource *imgResource = [[[EDAMResource alloc] init] autorelease];
	EDAMResourceAttributes *imgAttr = [[[EDAMResourceAttributes alloc] init] autorelease];
	
	// Automatically downloaded from the URL.
	imgAttr.sourceURL = myImageURL;
	imgResource.mime = @"image/jpeg";
	
	imgResource.attributes = imgAttr;
	
	[resources addObject:imgResource];
	// Plural embed images are supported,
	// but this makes slow sharing process
	[content appendFormat:@"<p><img src=\"%@\" /></p>",myImageURL];
	// img element will be replaced with en-media element automatically.
	
	
	[content appendString:kENMLSuffix];

	[note setTitle:noteTitle];
	[note setContent:content];
	[note setResources:resources];

	SHKEvernoteItem *item = [[SHKEvernoteItem alloc] init] autorelease];
	item.title = noteTitle;
	item.shareType = SHKShareTypeURL;
	item.note = note;
	
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	[actionSheet showFromToolbar:self.navigationController.toolbar]; 
	

Learn more about `EDAMNote` at [Evernote official developer overview](http://www.evernote.com/about/developer/api/evernote-api.htm#_Toc272854029).