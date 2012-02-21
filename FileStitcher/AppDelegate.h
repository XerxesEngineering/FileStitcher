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
@property (assign) IBOutlet NSButton *btnMoveUp;
@property (assign) IBOutlet NSButton *btnMoveDown;
@property (assign) IBOutlet NSButton *btnRemoveFiles;
@property (assign) IBOutlet NSButton *btnStitchFiles;

@property (retain) NSMutableArray* files;
@property (retain) FileStitcher* fileStitcher;
@property (retain) NSString* outputFileName;  
@property (retain) NSArray* sortDescriptors;
@property (assign) BOOL isStitching;

- (IBAction)addFiles:(id)sender;
- (IBAction)sortFiles:(id)sender;
- (IBAction)moveUp:(id)sender;
- (IBAction)moveDown:(id)sender;
- (IBAction)removeFilesFromList:(id)sender;
- (IBAction)clearFiles:(id)sender;
- (IBAction)stitchFilesClick:(id)sender;
- (IBAction)tableViewRowSelected:(id)sender;

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender atTableViewRowIndex:(NSInteger)rowIndex;
- (void)addFilePathsToFiles:(NSArray*)filePaths atIndex:(NSInteger)index;
- (void)enableGUI:(BOOL)enable;
- (void)sortTableView:(NSTableView*)tableView;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end
