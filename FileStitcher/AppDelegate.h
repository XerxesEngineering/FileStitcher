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

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTableView *tableView;
@property (unsafe_unretained) IBOutlet NSScrollView *scrollView;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressIndicator;
@property (unsafe_unretained) IBOutlet NSButton *btnSortFiles;
@property (unsafe_unretained) IBOutlet NSButton *btnMoveUp;
@property (unsafe_unretained) IBOutlet NSButton *btnMoveDown;
@property (unsafe_unretained) IBOutlet NSButton *btnRemoveFiles;
@property (unsafe_unretained) IBOutlet NSButton *btnClearFiles;
@property (unsafe_unretained) IBOutlet NSButton *btnStitchFiles;

@property (strong) NSMutableArray* files;
@property (strong) FileStitcher* fileStitcher;
@property (strong) NSString* outputFileName;  
@property (strong) NSArray* sortDescriptors;
@property (assign) BOOL isStitching;

- (IBAction)addFiles:(id)sender;
- (IBAction)sortFiles:(id)sender;
- (IBAction)moveUp:(id)sender;
- (IBAction)moveDown:(id)sender;
- (IBAction)removeFilesFromList:(id)sender;
- (IBAction)clearFiles:(id)sender;
- (IBAction)stitchFilesClick:(id)sender;
- (IBAction)tableViewRowSelected:(id)sender;

//- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender atTableViewRowIndex:(NSInteger)rowIndex;
//- (void)addFilePathsToFiles:(NSArray*)filePaths atIndex:(NSInteger)index;
//- (void)enableGUI:(BOOL)enable;
//- (void)enableFileButtons:(BOOL)enable;
//- (void)sortTableView:(NSTableView*)tableView;
//- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end
