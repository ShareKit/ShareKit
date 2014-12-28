[![Build Status](https://travis-ci.org/ShareKit/ShareKit.svg?branch=master)](https://travis-ci.org/ShareKit/ShareKit)

ShareKit allows you to share content easily:
```objective-c
- (void)myButtonHandlerAction {

    // Create the item to share (in this example, a url)
    NSURL *url = [NSURL URLWithString:@"http://getsharekit.com"];
    SHKItem *item = [SHKItem URL:url title:@"ShareKit is Awesome!" contentType:SHKURLContentTypeWebpage];
    
    // Get the ShareKit action sheet
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];

    // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
    // but sometimes it may not find one. To be safe, set it explicitly
    [SHK setRootViewController:self];
    
    // Display the action sheet
    if (NSClassFromString(@"UIAlertController")) {
        
        //iOS 8+
        SHKAlertController *alertController = [SHKAlertController actionSheetForItem:item];
        [alertController setModalPresentationStyle:UIModalPresentationPopover];
        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        popPresenter.barButtonItem = self.toolbarItems[1];
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        
        //deprecated
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    }

}
```
Everything else (user authentication, API calls, shareUI etc) is handled by ShareKit. Moreover, you can use and customise [SHKAccountsViewController](https://github.com/ShareKit/ShareKit/blob/master/Classes/ShareKit/UI/SHKAccountsViewController.h) (where users can login/logoff, displays username if someone is logged to a particular service) and [SHKUploadsViewController](https://github.com/ShareKit/ShareKit/blob/master/Classes/ShareKit/UI/SHKUploadsViewController.h) (similar to safari downloads, works with sharers able to report progress). For a brief introduction, check [the demo app](https://github.com/ShareKit/ShareKit-Demo-App). To know more about configuration options see [DefaultSHKConfigurator.m](https://github.com/ShareKit/ShareKit/blob/master/Classes/ShareKit/Configuration/DefaultSHKConfigurator.m). To know more about what type of content can be shared, see [SHKItem.h](https://github.com/ShareKit/ShareKit/blob/master/Classes/ShareKit/Core/SHKItem.h). To find out what sharers exist, and what are they capable of, check [Sharer support matrix](https://github.com/ShareKit/ShareKit/blob/master/Documentation/sharer_itemProperty_support_matrix.xlsx) (does not contain all sharers yet)

Documentation
-------------

The latest documentation and installation instructions can be found on the [ShareKit Wiki](https://github.com/ShareKit/ShareKit/wiki). To get a preview of new features see [What's new](https://github.com/ShareKit/ShareKit/wiki/What's-new) wiki page.

!!! Updated new service creation guidelines for contributors + updated service templates are [here](https://github.com/ShareKit/ShareKit/wiki/New-service-creator's-guidelines) !!!

ShareKit 2
------------

In order to make it easier for new users to choose a canonical fork of ShareKit, the ShareKit community has decided to band together and take responsibility for collecting useful commits into what we're calling "ShareKit 2". It is now ready for you. It is the first officially stable version of ShareKit since February 2010, with more frequent updates expected.

Highlights:

* many new sharers
* new UI (currently used by Facebook, Plurk and LinkedIn, more to follow)
* iOS native social.framework based sharers
* optimised for easy updating (subproject library + 3rd party code as git submodules)
* uses ARC and block callbacks

You can follow the initial planning at https://github.com/ideashower/ShareKit/issues/283.

As ShareKit is now community driven, you are welcome to help, to judge new features, review pull requests etc.. There are many ways you can help, see [FAQ](https://github.com/ShareKit/ShareKit/wiki/FAQ)


Credits
----------
ShareKit was created by [Nate Weiner](www.ideashower.com), is updated by [contributors](https://github.com/ShareKit/ShareKit/contributors) and is maintained by [Vilém Kurz](http://www.cocoaminers.com/?page_id=2).

Personal note by Vilém Kurz
---------------------------------------
ShareKit is a specific project in way that it must communicate with many services. Their API's are ever-changing and it is time consuming to even review all pull requests to allow only the best quality to go in. I love this project, and I devote a lot of my time to it. 

If you feel ShareKit helped you and is on the right way, you can say thank you via [Paypal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=YWPTW5E5ACJ2L), or pick some nice book from my [Amazon wish list](http://www.amazon.co.uk/registry/wishlist/10ILCUM9J9AV7).

If you wish to sponsor any specific ShareKit feature, or do you wish to add your service to ShareKit feel free to [contact me](https://github.com/VilemKurz).

Many thanks! This will help me to give even more time to the project, to bring alive all the the todo's in the list, and more.
