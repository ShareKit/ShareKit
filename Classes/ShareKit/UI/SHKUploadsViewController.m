//
//  SHKUploadsViewController.m
//  ShareKit
//
//  Created by Vilem Kurz on 23/01/2014.
//
//

#import "SHKUploadsViewController.h"

#import "SHK.h"
#import "SHKUploadsViewCell.h"
#import "SHKConfiguration.h"
#import "SHKUploadInfo.h"
#import "Debug.h"

#import "SHKSharer.h" //for mock data only

#define LOAD_MOCK_DATA 0

@interface SHKUploadsViewController ()

@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableOrderedSet *uploadInfoDataSource;
@property (weak, nonatomic) id sendDidFinishObserver;
@property (weak, nonatomic) id sendProgressObserver;
@property (weak, nonatomic) id sendDidFailObserver;
@property (weak, nonatomic) id sendDidCancelObserver;
@property (strong, nonatomic) NSByteCountFormatter *byteFormatter;

//to keep a mock sharer alive
@property (strong, nonatomic) SHKSharer *sharer;

@end

@implementation SHKUploadsViewController

#pragma mark - Initialization

+ (instancetype)openFromViewController:(UIViewController *)rootViewController {
    
    id result = [[SHKCONFIG(SHKUploadsViewControllerSubclass) alloc] initWithUploadInfo:[[SHK currentHelper] uploadProgressUserInfos]];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:result];
    [rootViewController presentViewController:navigationController animated:YES completion:nil];
    return result;
}

- (Class)uploadsViewCellClass {
    
    return [SHKUploadsViewCell class];
}

- (instancetype)initWithUploadInfo:(NSMutableOrderedSet *)uploadInfo {
    
    self = [super init];
    if (self) {
        
        if (LOAD_MOCK_DATA) {
        
            _sharer = [[SHKSharer alloc] init];
            
            SHKUploadInfo *mockUpload = [[SHKUploadInfo alloc] init];
            mockUpload.sharer = _sharer;
            mockUpload.sharerTitle = @"Sharer title";
            mockUpload.filename = @"Long_file_name_____name.test";
            mockUpload.bytesTotal = 3044506;
            mockUpload.bytesUploaded = 789456;
            
            _uploadInfoDataSource = [[NSMutableOrderedSet alloc] initWithCapacity:10];
            [_uploadInfoDataSource addObject:mockUpload];

        } else {
            
            _uploadInfoDataSource = uploadInfo;
        }
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        
        __weak typeof(self) weakSelf = self;
        
        _sendDidFinishObserver = [center addObserverForName:SHKSendDidFinishNotification
                                                     object:nil
                                                      queue:mainQueue
                                                 usingBlock:^(NSNotification *note) {
                                                     [weakSelf.tableView reloadData];
                                                      }];
        
        _sendProgressObserver = [center addObserverForName:SHKUploadProgressNotification
                                                    object:nil
                                                     queue:mainQueue
                                                usingBlock:^(NSNotification *note) {
                                                    
                                                    SHKUploadInfo *uploadInfo = [note.userInfo objectForKey:SHKUploadProgressInfoKeyName];
                                                    NSUInteger index = [weakSelf.uploadInfoDataSource indexOfObject:uploadInfo];
                                                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                                                    SHKUploadsViewCell *cell = (SHKUploadsViewCell *)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
                                                    [cell updateWithUploadInfo:uploadInfo];
                                                }];
        
        _sendDidFailObserver = [center addObserverForName:SHKSendDidFailWithErrorNotification
                                                   object:nil
                                                    queue:mainQueue
                                               usingBlock:^(NSNotification *note) {
                                                   [weakSelf.tableView reloadData];
                                               }];
        _sendDidCancelObserver = [center addObserverForName:SHKSendDidCancelNotification
                                                     object:nil
                                                      queue:mainQueue
                                                 usingBlock:^(NSNotification *note) {
                                                     [weakSelf.tableView reloadData];
                                                 }];
    }
    return self;
}

- (void)dealloc {
    
    SHKLog(@"uploads VC dealloc");
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self.sendDidFinishObserver];
    [center removeObserver:self.sendProgressObserver];
    [center removeObserver:self.sendDidFailObserver];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                           target:self
                                                                                           action:@selector(clear)];
    UITableView *tableView = [[UITableView alloc] initWithFrame:[self.view bounds]];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clear {
    
    NSMutableOrderedSet *uploads = [[SHK currentHelper] uploadProgressUserInfos];
    NSMutableArray *infosToDelete = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (SHKUploadInfo *uploadInfo in uploads) {
        if (![uploadInfo isInProgress]) {
            [infosToDelete addObject:uploadInfo];
        }
    }
    [uploads removeObjectsInArray:infosToDelete];
    [[SHK currentHelper] uploadInfoChanged:nil];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger result = [self.uploadInfoDataSource count];
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    SHKUploadsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[[self uploadsViewCellClass] alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell setupLayout];
    }
    
    SHKUploadInfo *cellUploadData = self.uploadInfoDataSource[indexPath.row];
    [cell updateWithUploadInfo:cellUploadData];
    return cell;
}

@end