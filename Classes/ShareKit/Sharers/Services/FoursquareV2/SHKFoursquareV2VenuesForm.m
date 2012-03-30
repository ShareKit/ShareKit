//
//  SHKFoursquareV2VenuesForm.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/26/11.
//  Sponsored by Twoppy
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

#import "SHKFoursquareV2VenuesForm.h"
#import "SHKFoursquareV2CheckInForm.h"
#import "SHKFoursquareV2Venue.h"

@implementation SHKFoursquareV2VenuesForm

@synthesize delegate = _delegate;
@synthesize request = _request;

@synthesize locationManager = _locationManager;
@synthesize location = _location;

@synthesize query = _query;

@synthesize venues = _venues;
@synthesize filteredVenues = _filteredVenues;

- (void)dealloc
{
    [self stopMonitoringLocation];
    
    self.delegate = nil;
    self.request = nil;
    
    self.query = nil;
    
    self.venues = nil;
    self.filteredVenues = nil;
    
    [super dealloc];
}

- (id)initWithDelegate:(SHKFoursquareV2*)delegate
{
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = SHKLocalizedString(@"Nearby Places");
        
        self.delegate = delegate;
        
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)] autorelease];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    UISearchBar *searchBar = [[[UISearchBar alloc] init] autorelease];
    searchBar.placeholder = SHKLocalizedString(@"Search places");
    [searchBar sizeToFit];
    searchBar.delegate = self;
    
    UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    
    searchController.delegate = self;
    
    searchController.searchResultsDataSource = self;
    
    searchController.searchResultsDelegate = self;
    
    self.tableView.tableHeaderView = searchBar;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   
    [self startMonitoringLocation];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self stopMonitoringLocation];
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.tableView)
    {
        return self.venues != nil ? 1 : 0;
    }
    else
    {
        return self.filteredVenues != nil ? 1 : 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView)
    {
        return self.venues != nil ? [self.venues count] : 0;
    }
    else
    {
        return self.filteredVenues != nil ? [self.filteredVenues count] : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SHKFoureSquareV2VenueCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    SHKFoursquareV2Venue *venue;
    if (tableView == self.tableView)
    {
        venue = [self.venues objectAtIndex:[indexPath row]];
    }
    else
    {
        venue = [self.filteredVenues objectAtIndex:[indexPath row]];
    }
    cell.textLabel.text = venue.name;
    cell.detailTextLabel.text = venue.address;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController popViewControllerAnimated:NO];
    
    if (tableView == self.tableView)
    {
        self.delegate.venue = [self.venues objectAtIndex:[indexPath row]];
    }
    else
    {
        self.delegate.venue = [self.filteredVenues objectAtIndex:[indexPath row]];
    }
    
    self.delegate.location = self.location;
    
    [self.delegate showFoursquareV2CheckInForm];
}

#pragma mark CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    self.location = newLocation;
    
    if (oldLocation == nil)
    {
        [self startloadingVenues];
    }
}

#pragma mark Public
- (void)startMonitoringLocation
{
    // Note: Location access is already tested by sharer
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    
    if ([locationManager respondsToSelector:@selector(startMonitoringSignificantLocationChanges)]) 
    {
        // iOS 4.0 and up
        [locationManager startMonitoringSignificantLocationChanges];
    }
    else
    {
        // Before iOS 4.0
        [locationManager startUpdatingLocation];
    }
    
    self.locationManager = locationManager;
    [locationManager release];
    
    if (self.location == nil) {
        [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Determine your location...")];
    }
}

- (void)stopMonitoringLocation
{
    if (self.locationManager != nil) {
        if ([self.locationManager respondsToSelector:@selector(stopMonitoringSignificantLocationChanges)]) 
        {
            // iOS 4.0 and up
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
        else
        {
            // Before iOS 4.0
            [self.locationManager stopUpdatingLocation];
        }
        self.locationManager.delegate = nil;
        self.locationManager = nil;
    }
    
    self.location = nil;
}

- (void)startloadingVenues
{
    [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Searching places...")];
    
    self.request = [SHKFoursquareV2Request requestVenuesSearchLocation:self.location query:self.query delegate:self isFinishedSelector:@selector(finishLoadingVenues:) accessToken:self.delegate.accessToken autostart:YES];
}

- (void)finishLoadingVenues:(SHKFoursquareV2Request*)sender
{
    [[SHKActivityIndicator currentIndicator] hide];
    
    self.venues = nil;
    
    if (sender.success)
    {
        NSArray *responseVenues = [sender.foursquareResponse objectForKey:@"venues"];
        
        NSMutableArray *venues = [NSMutableArray arrayWithCapacity:[responseVenues count]];
        
        for (NSUInteger i = 0; i < [responseVenues count]; ++i) {
            [venues addObject:[SHKFoursquareV2Venue venueFromDictionary:[responseVenues objectAtIndex:i]]];
        }
        
        if (self.searchDisplayController.active)
        {
            self.filteredVenues = venues;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else
        {
            self.venues = venues;
            [self.tableView reloadData];
        }
    }
    else
    {
        NSError *error = sender.foursquareError;
        
        [self.delegate sendDidFailWithError:error shouldRelogin:error.foursquareRelogin];
    }
    
    self.request = nil;
    
}


#pragma mark -
#pragma mark UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    return NO;
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *query = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.query = (query.length > 0) ? query : nil;
    
    if (self.query) {
        [self startloadingVenues];
    }
}

#pragma mark -
#pragma mark Private

- (void)cancel
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[self.delegate sendDidCancel];
}


@end
