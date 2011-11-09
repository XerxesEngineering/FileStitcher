//
//  AppDelegate.h
//  FileStitcher
//
//  Created by Kevin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileStitcher.h"
#import "File.h"
#import "ProgressStepDelegate.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource, ProgressStepDelegate, NSOpenSavePanelDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSScrollView *scrollView;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

@property (retain) NSMutableArray* files;
@property (retain) FileStitcher* fileStitcher;
@property (retain) NSString* outputFileName;  

- (IBAction)addFiles:(id)sender;
- (IBAction)sortFiles:(id)sender;
- (IBAction)moveUp:(id)sender;
- (IBAction)moveDown:(id)sender;
- (IBAction)clearFiles:(id)sender;
- (IBAction)stitchFilesClick:(id)sender;

- (void) addFilePathsToFiles:(NSArray*)filePaths;
@end
