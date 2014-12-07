//
//  CNWLibraryViewController.m
//  WWDCReader
//
//  Created by Chiharu Nameki on 2014/12/03.
//  Copyright (c) 2014 Chiharu Nameki. All rights reserved.
//

#import "CNWLibraryViewController.h"
#import "CNWAppDelegate.h"
#import "CNWReaderViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>


@interface CNWLibraryViewController ()
@property (nonatomic) NSMutableArray *pathMonitorSources;
@property (nonatomic) NSMutableArray *pdfDocuments;
@end

@implementation CNWLibraryViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.pathMonitorSources = [NSMutableArray array];
    self.pdfDocuments = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
    [self startMonitoringDirectoryChanges];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopMonitoringAllItems];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pdfDocuments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PDFCell" forIndexPath:indexPath];
    CNWPDFDocument *pdf = self.pdfDocuments[indexPath.row];
    cell.textLabel.text = [pdf.URL lastPathComponent];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // delete the file
        CNWPDFDocument *pdf = self.pdfDocuments[indexPath.row];
        [[NSFileManager defaultManager] removeItemAtURL:pdf.URL error:nil];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *controller = [segue destinationViewController];
    if ([controller isKindOfClass:[CNWReaderViewController class]]) {
        CNWReaderViewController *readerController = (CNWReaderViewController *)controller;
        readerController.pdfDocument = self.pdfDocuments[self.tableView.indexPathForSelectedRow.row];
    }
}

#pragma mark - Directory Monitoring

- (void)startMonitoringDirectoryChanges {
    dispatch_queue_t queue = dispatch_queue_create("vnodeMonitoringQueue", 0);
    
    void(^updatePDFDocuments)() = ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // ファイルリスト取得
        NSError *error = nil;
        NSArray *newURLs = [fm contentsOfDirectoryAtURL:CNWDocumentsDirectoryURL()
                             includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLTypeIdentifierKey]
                                                options:NSDirectoryEnumerationSkipsHiddenFiles
                                                  error:&error];
        if (error) return;
        
        // PDFファイルだけに絞り込む
        newURLs = [newURLs filteredArrayUsingPredicate:
                   [NSPredicate predicateWithBlock:^BOOL(id url, NSDictionary *bindings)
                    {
                        // 通常のファイルか？
                        NSNumber *isRegularFile = nil;
                        if (![url getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:nil] ||
                            [isRegularFile boolValue] == NO) {
                            return NO;
                        }
                        
                        // PDFか？
                        NSString *UTI = nil;
                        if (![url getResourceValue:&UTI forKey:NSURLTypeIdentifierKey error:nil] ||
                            ![UTI isEqualToString:(NSString *)kUTTypePDF]) {
                            return NO;
                        }
                        
                        return YES;
                    }]];
        
        NSMutableArray *oldURLs = [@[] mutableCopy];
        for (CNWPDFDocument *document in self.pdfDocuments) {
            [oldURLs addObject:document.URL];
        }
        
        NSSet *oldset = [NSSet setWithArray:oldURLs];
        NSSet *newset = [NSSet setWithArray:newURLs];
        
        NSMutableSet *deletedURLs = [oldset mutableCopy];
        [deletedURLs minusSet:newset];
        NSMutableSet *addedURLs = [newset mutableCopy];
        [addedURLs minusSet:oldset];
        
        // 削除
        if (0 < deletedURLs.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.tableView beginUpdates];
                NSArray *documents = [self.pdfDocuments copy];
                [documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    CNWPDFDocument *document = obj;
                    if ([deletedURLs containsObject:document.URL]) {
                        // 削除されたファイルに相当する行を消す
                        [self.pdfDocuments removeObject:document];
                        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                        [deletedURLs removeObject:document.URL];
                        if (deletedURLs.count == 0) {
                            *stop = YES;
                        }
                    }
                }];
                [self.tableView endUpdates];
                
            });
        }
        
        // 追加
        void(^insert)(NSArray *documents) = ^(NSArray *documents) {
            if (documents.count == 0) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                
                [self.pdfDocuments addObjectsFromArray:documents];
                [self.pdfDocuments sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    CNWPDFDocument *doc1 = obj1;
                    CNWPDFDocument *doc2 = obj2;
                    return [doc1.URL.lastPathComponent compare:doc2.URL.lastPathComponent];
                }];
                
                for (CNWPDFDocument *document in documents) {
                    NSUInteger idx = [self.pdfDocuments indexOfObject:document];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                
                [self.tableView endUpdates];
            });
        };
      
        NSMutableArray *addedDocuments = [@[] mutableCopy];
        for (NSURL *addedURL in addedURLs) {
            CNWPDFDocument *pdfDocument = [[CNWPDFDocument alloc] initWithURL:addedURL];
            if (pdfDocument) {
                if (pdfDocument.isSupported) {
                    [addedDocuments addObject:pdfDocument];
                }
                
            } else {
                // 書き込み中だったら終わるのを待って追加
                [self startMonitoringItemAtPath:addedURL.path
                                          queue:queue
                                 changesHandler:^(dispatch_source_t source,
                                                  dispatch_source_vnode_flags_t flags)
                 {
                     if (flags & DISPATCH_VNODE_ATTRIB) {
                         dispatch_source_cancel(source);
                         CNWPDFDocument *pdfDocument = [[CNWPDFDocument alloc] initWithURL:addedURL];
                         if (pdfDocument.isSupported) {
                             insert(@[pdfDocument]);
                         }
                     }
                 }];
            }
        }
        insert(addedDocuments);
    };

    updatePDFDocuments();
    [self startMonitoringItemAtPath:CNWDocumentsDirectoryURL().path
                              queue:queue
                     changesHandler:^(dispatch_source_t source, dispatch_source_vnode_flags_t flags)
    {
        if (flags & DISPATCH_VNODE_WRITE) {
            updatePDFDocuments();
        }
    }];
}

- (dispatch_source_t)startMonitoringItemAtPath:(NSString *)path
                                         queue:(dispatch_queue_t)queue
                                changesHandler:(void(^)(dispatch_source_t source, dispatch_source_vnode_flags_t flags))block {
    int file = open([path fileSystemRepresentation], O_EVTONLY);
    if (file == -1) return nil;
    
    void (^changesHandler)(dispatch_source_t source, dispatch_source_vnode_flags_t flags);
    changesHandler = [block copy];
    
    dispatch_source_t source;
    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                    file,
                                    DISPATCH_VNODE_DELETE|DISPATCH_VNODE_ATTRIB|DISPATCH_VNODE_WRITE,
                                    queue);
    dispatch_source_set_event_handler(source, ^{
        dispatch_source_vnode_flags_t flags = dispatch_source_get_data(source);
        if (changesHandler) {
            changesHandler(source, flags);
        }
        if (flags & DISPATCH_VNODE_DELETE) {
            dispatch_source_cancel(source);
        }
    });
    dispatch_source_set_cancel_handler(source, ^{
        close(file);
        [self.pathMonitorSources removeObject:source];
    });
    
    [self.pathMonitorSources addObject:source];
    dispatch_resume(source);
    
    return source;
}

- (void)stopMonitoringAllItems {
    NSArray *sources = [self.pathMonitorSources copy];
    for (dispatch_source_t source in sources) {
        dispatch_source_cancel(source);
    }
}
@end
