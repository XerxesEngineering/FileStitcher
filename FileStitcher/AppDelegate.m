//
//  AppDelegate.m
//  FileStitcher
//
//  Created by Kevin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tableView = _tableView;
@synthesize scrollView = _scrollView;
@synthesize progressIndicator = _progressIndicator;
@synthesize btnSortFiles = _btnSortFiles;
@synthesize btnMoveUp = _btnMoveUp;
@synthesize btnMoveDown = _btnMoveDown;
@synthesize btnRemoveFiles = _btnRemoveFiles;
@synthesize btnClearFiles = _btnClearFiles;
@synthesize btnStitchFiles = _btnStitchFiles;


@synthesize files;
@synthesize fileStitcher;
@synthesize outputFileName;
@synthesize sortDescriptors;
@synthesize isStitching;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        /* init files array before the app delegate methods to cover both scenarios:
         1. When files are dropped on the app icon before launch.
            application:openFiles:
            applicationDidFinishLaunching:
         2. When files are dropped on the app icon after launch.
            applicationDidFinishLaunching:
            application:openFiles:
         */
        self.files = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}
	
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch; // Finder sort options
    
    NSSortDescriptor* fileSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) 
     {
         NSRange obj1Range = NSMakeRange(0, [obj1 length]);
         return [obj1 compare:obj2 options:comparisonOptions range:obj1Range locale:[NSLocale currentLocale]];
     }];
    
    NSTableColumn* fileColumn = [self.tableView tableColumnWithIdentifier:@"0"];
    [fileColumn setSortDescriptorPrototype:fileSortDescriptor];
    
    NSSortDescriptor* sizeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bytes" ascending:YES];
    
    NSTableColumn* sizeColumn = [self.tableView tableColumnWithIdentifier:@"1"];
    [sizeColumn setSortDescriptorPrototype:sizeSortDescriptor];
    
    self.sortDescriptors = [NSArray arrayWithObjects:fileSortDescriptor, sizeSortDescriptor, nil];
    
    // smooths out the animation - http://www.cocoabuilder.com/archive/cocoa/242344-determinate-nsprogressindicator-animation.html
    [self.progressIndicator setUsesThreadedAnimation:YES];
    
    NSArray* draggedTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
    [self.window registerForDraggedTypes:draggedTypes];
    [self.tableView registerForDraggedTypes:draggedTypes];
}

-(void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{    
    [self addFilePathsToFiles:filenames atIndex:self.files.count];
    [sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

#pragma mark - 
#pragma mark NSDraggingInfo Protocol

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) 
    {
        if (sourceDragMask & NSDragOperationLink) 
        {
            return NSDragOperationLink;
        } 
        //        else if (sourceDragMask & NSDragOperationCopy) 
        //        {
        //            return NSDragOperationCopy;
        //        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
    return [self performDragOperation:sender atTableViewRowIndex:self.files.count];
}

#pragma mark -
#pragma Custom Methods

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender atTableViewRowIndex:(NSInteger)rowIndex
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) 
    {
        // Depending on the dragging source and modifier keys,
        // the file data may be copied or linked
        if (sourceDragMask & NSDragOperationLink) 
        {
            NSArray* filePaths = [pboard propertyListForType:NSFilenamesPboardType];
            [self addFilePathsToFiles:filePaths atIndex:rowIndex];
        } 
        //        else 
        //        {
        //            [self addDataFromFiles:files];
        //        }
    }
    
    return YES;
}

- (void)addFilePathsToFiles:(NSArray*)filePaths atIndex:(NSInteger)index
{
    NSMutableArray* newFiles = [NSMutableArray arrayWithCapacity:filePaths.count];
    NSIndexSet* newFileIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, filePaths.count)];
    
    for (NSString* filePath in filePaths)
    {
        File* file= [File fileWithPath:filePath];
        [newFiles addObject:file];
    }
    
    [self.files insertObjects:newFiles atIndexes:newFileIndexes];    
    [self.tableView reloadData];
    
    [self enableFileButtons:(self.files.count > 0)];
}

- (void)enableGUI:(BOOL)enable
{
    [self.tableView setEnabled:enable];
    
    for (NSView* view in [[self.window contentView] subviews])
    {
        if ([view isKindOfClass:[NSButton class]])
        {
            NSButton* button = (NSButton*)view;
            if (![button isEqualTo:self.btnStitchFiles])
                [button setEnabled:enable];
        }
    }
    
    self.btnStitchFiles.title = (enable) ? @"Stitch Files" : @"Stop";
}

- (void)enableFileButtons:(BOOL)enable
{
    [self.btnSortFiles setEnabled:enable];
    [self.btnClearFiles setEnabled:enable];
    [self.btnStitchFiles setEnabled:enable];
}

- (void)sortTableView:(NSTableView*)tableView
{
    [self.files sortUsingDescriptors:tableView.sortDescriptors];
    [tableView reloadData];
}

#pragma mark -
#pragma mark NSTableViewDataSource Protocol

-(NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
    return [self.files count];
}

-(id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
    File* file = [self.files objectAtIndex:rowIndex];
    
    if ([aTableColumn.identifier isEqualToString:@"0"])
        return file.name;
    else if ([aTableColumn.identifier isEqualToString:@"1"])
        return file.displaySize;

    return nil;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self sortTableView:tableView];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex mouseLocation:(NSPoint)mouseLocation
{
    File* file = [self.files objectAtIndex:rowIndex];
    
    if ([aTableColumn.identifier isEqualToString:@"0"])
        return file.path;
    else if ([aTableColumn.identifier isEqualToString:@"1"])
        return [NSString stringWithFormat:@"%ld bytes", file.bytes];

    return nil;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropOn)
        return NSDragOperationNone;
    else
        return [self draggingEntered:info];
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    return [self performDragOperation:info atTableViewRowIndex:row];
}

#pragma mark -
#pragma mark Action event handlers

- (IBAction)addFiles:(id)sender 
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel retain];
    
    [openPanel setAllowsMultipleSelection:YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) 
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSArray* fileURLs = [openPanel URLs];
            NSMutableArray* filePaths = [NSMutableArray arrayWithCapacity:fileURLs.count];
            [fileURLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSURL* fileURL = (NSURL*)obj;
                [filePaths addObject:fileURL.path];
            }];
            [self addFilePathsToFiles:filePaths atIndex:self.files.count];
        }
    }];
    
    [openPanel release];
}

- (IBAction)sortFiles:(id)sender 
{
    if ([self.tableView.sortDescriptors isEqualToArray:self.sortDescriptors])
        [self sortTableView:self.tableView]; // sort descriptors aren't changing; sort manually
    else
        [self.tableView setSortDescriptors:self.sortDescriptors]; // calls tableView:sortDescriptorsDidChange:
}

- (IBAction)moveUp:(id)sender 
{
    NSIndexSet* selectedIndexes = [self.tableView selectedRowIndexes];
    
    if (selectedIndexes.firstIndex > 0)
    {
        NSMutableIndexSet* newSelectedIndexes = [NSMutableIndexSet indexSet];
        
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) 
        {
            [self.files exchangeObjectAtIndex:idx withObjectAtIndex:idx-1];
            [newSelectedIndexes addIndex:idx-1];
        }];
        
        NSIndexSet* reloadIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newSelectedIndexes.firstIndex, selectedIndexes.lastIndex + 1)];
        NSIndexSet* columnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.tableView numberOfColumns])];
        
        [self.tableView reloadDataForRowIndexes:reloadIndexes columnIndexes:columnIndexes];
        [self.tableView selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
    }
}

- (IBAction)moveDown:(id)sender 
{
    NSIndexSet* selectedIndexes = [self.tableView selectedRowIndexes];
    
    if (selectedIndexes.lastIndex < self.files.count - 1)
    {
        NSMutableIndexSet* newSelectedIndexes = [NSMutableIndexSet indexSet];
        
        [selectedIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) 
         {
             [self.files exchangeObjectAtIndex:idx withObjectAtIndex:idx+1];
             [newSelectedIndexes addIndex:idx+1];
         }];
        
        NSIndexSet* reloadIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selectedIndexes.firstIndex, newSelectedIndexes.lastIndex + 1)];
        NSIndexSet* columnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.tableView numberOfColumns])];
        
        [self.tableView reloadDataForRowIndexes:reloadIndexes columnIndexes:columnIndexes];
        [self.tableView selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
    }
}

- (IBAction)removeFilesFromList:(id)sender
{    
    [self.files removeObjectsAtIndexes:[self.tableView selectedRowIndexes]];
    [self.tableView reloadData];
    [self tableViewRowSelected:sender]; // handle last file removed
    [self enableFileButtons:(self.files.count > 0)];
}

- (IBAction)clearFiles:(id)sender 
{
    [self.files removeAllObjects];
    [self.tableView reloadData];
    [self tableViewRowSelected:sender]; 
    [self enableFileButtons:NO];
}

- (IBAction)stitchFilesClick:(id)sender 
{
    if (self.isStitching)
    {
        self.fileStitcher.isStopRequested = YES;
    }
    else
    {
        __block double maxValue = 0.0;
        
        [self.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
        {
            File* file = (File*)obj;
            maxValue += file.bytes;
        }];
        
        self.progressIndicator.doubleValue = 0.0;
        self.progressIndicator.maxValue = maxValue;
        
        NSSavePanel* savePanel = [NSSavePanel savePanel];
        [savePanel retain];
        [savePanel setDelegate:self];
        [savePanel setExtensionHidden:NO];
        [savePanel setAllowsOtherFileTypes:YES];
        [savePanel setCanSelectHiddenExtension:YES];
        
        
        [savePanel beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton)
            {
                savePanel.title = savePanel.title;
                File* file = [File fileWithPath:self.outputFileName];
                if ([self.files containsObject:file])
                {
                    NSAlert* alert = [NSAlert alertWithMessageText:@"Oh no!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"I can't save to the file (%@) when you have it as one of the input files in the list. Remove the file from the list or save to a different file.", file.name];
                    [alert setAlertStyle:NSCriticalAlertStyle];
                    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
                }
                else
                {
                    self.isStitching = YES;
                    [self enableGUI:NO];
                    int bufferSize = maxValue / [self.files count];
                    bufferSize = (bufferSize % 2 == 0) ? bufferSize : bufferSize;
                    if (!self.fileStitcher)
                    {
                        self.fileStitcher = [FileStitcher new];
                        self.fileStitcher.bufferSize = 16*1024;
                        self.fileStitcher.delegate = self;
                    }
                    [self.fileStitcher stitchFiles:self.files toOutputFile:file];
                }
            }
        }];
        
        [savePanel release];
    }
}

- (IBAction)tableViewRowSelected:(id)sender
{
    BOOL rowsSelected = (self.tableView.numberOfSelectedRows > 0);
    [self.btnMoveUp setEnabled:rowsSelected];
    [self.btnMoveDown setEnabled:rowsSelected];
    [self.btnRemoveFiles setEnabled:rowsSelected];
}

#pragma mark -
#pragma mark NSOpenSavePanelDelegate Protocol

- (NSString*)panel:(id)sender userEnteredFilename:(NSString*)filename confirmed:(BOOL)okFlag
{
    if (okFlag)
    {
        NSSavePanel* panel = (NSSavePanel*)sender;
        self.outputFileName = panel.URL.path;
        return @"*"; // invalid filename to avoid the "replace" prompt
    }
    else
    {
        return filename;
    }
}

#pragma mark -
#pragma mark ProgressStepDelegate Protocol

-(void)performProgressStep:(double)progressStep
{
    [self.progressIndicator incrementBy:progressStep];
}

-(void)progressComplete
{
    self.isStitching = NO;
    [self enableGUI:YES];
    if (self.fileStitcher.fileIndex < self.fileStitcher.files.count)
    {
        File* file = [self.fileStitcher.files objectAtIndex:self.fileStitcher.fileIndex];
        NSAlert* alert = [NSAlert alertWithMessageText:@"Incomplete File" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"The saved file is incomplete. The last partial file copied to the output file was a portion of \"%@\", file %d of %d in the list.\r\n\r\nTrash the incomplete file, \"%@\"?", file.name, self.fileStitcher.fileIndex + 1, self.fileStitcher.files.count, [self.outputFileName lastPathComponent]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kFullTrashIcon)]];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
}

#pragma mark -
#pragma mark NSAlert Modal Delegate - Informal Protocol

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn)
    {
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[self.outputFileName stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[self.outputFileName lastPathComponent]] tag:nil];        
    }
}

@end
