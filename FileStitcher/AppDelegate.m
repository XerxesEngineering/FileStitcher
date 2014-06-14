//
//  AppDelegate.m
//  FileStitcher
//
//  Created by Kevin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

static NSString* const kFileStitcherPasteboardTableViewType = @"FileStitcherPasteboardTableViewType";

@implementation AppDelegate

- (id)init
{
    self = [super init];
    
    if (self) {
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch; // Finder sort options
    
    NSSortDescriptor* fileSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
         NSRange obj1Range = NSMakeRange(0, [obj1 length]);
         return [obj1 compare:obj2 options:comparisonOptions range:obj1Range locale:[NSLocale currentLocale]];
     }];
    
    NSTableColumn* fileColumn = [self.tableView tableColumnWithIdentifier:@"0"];
    [fileColumn setSortDescriptorPrototype:fileSortDescriptor];
    
    NSSortDescriptor* sizeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bytes" ascending:YES];
    
    NSTableColumn* sizeColumn = [self.tableView tableColumnWithIdentifier:@"1"];
    [sizeColumn setSortDescriptorPrototype:sizeSortDescriptor];
    
    self.sortDescriptors = @[fileSortDescriptor, sizeSortDescriptor];
    
    // smooths out the animation - http://www.cocoabuilder.com/archive/cocoa/242344-determinate-nsprogressindicator-animation.html
    [self.progressIndicator setUsesThreadedAnimation:YES];
    
    [self.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self.tableView registerForDraggedTypes:@[NSFilenamesPboardType, kFileStitcherPasteboardTableViewType]];
}

-(void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{    
    [self addFilePathsToFiles:filenames atIndex:self.files.count withAnimation:NSTableViewAnimationSlideDown];
    [sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

#pragma mark - KVC for files property

- (void)insertFiles:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [self.files insertObjects:array atIndexes:indexes];
    [self invalidateFiles];
}

- (void)removeFilesAtIndexes:(NSIndexSet *)indexes
{
    [self.files removeObjectsAtIndexes:indexes];
    [self invalidateFiles];
}

- (void)invalidateFiles
{
    [self.files setValue:@(NO) forKey:NSStringFromSelector(@selector(processed))];
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.files.count)] columnIndexes:[NSIndexSet indexSetWithIndex:(self.tableView.numberOfColumns-1)]];
}

#pragma mark -
#pragma mark NSDraggingInfo Protocol

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } 
        //        else if (sourceDragMask & NSDragOperationCopy) {
        //            return NSDragOperationCopy;
        //        }
    } else if ([[pboard types] containsObject:kFileStitcherPasteboardTableViewType]) {
        return NSDragOperationEvery;
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
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        // Depending on the dragging source and modifier keys,
        // the file data may be copied or linked
        if (sourceDragMask & NSDragOperationLink) {
            NSArray* filePaths = [pboard propertyListForType:NSFilenamesPboardType];
            [self addFilePathsToFiles:filePaths atIndex:rowIndex withAnimation:NSTableViewAnimationEffectGap];
            return YES;
        } 
        //        else {
        //            [self addDataFromFiles:files];
        //        }
    } else if ([[pboard types] containsObject:kFileStitcherPasteboardTableViewType]) {
        NSData* dragRowData = [pboard dataForType:kFileStitcherPasteboardTableViewType];
        NSIndexSet* dragRowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:dragRowData];
        NSRange dropRowRange = NSMakeRange(rowIndex, dragRowIndexes.count);
        NSIndexSet* dropRowIndexes = [NSIndexSet indexSetWithIndexesInRange:dropRowRange];
        NSInteger dragRow = [dragRowIndexes firstIndex];
        
        // drag down
        if (dragRow < rowIndex) {
            NSArray* dragFiles = [self.files objectsAtIndexes:dragRowIndexes];
            [self.tableView beginUpdates];
            [self insertFiles:dragFiles atIndexes:dropRowIndexes];
//            [self.files insertObjects:dragFiles atIndexes:dropRowIndexes];
//            [self.files removeObjectsAtIndexes:dragRowIndexes];
            [self removeFilesAtIndexes:dragRowIndexes];
            NSIndexSet* reloadIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dragRow, dropRowIndexes.lastIndex - dragRow)];
            [self.tableView reloadDataForRowIndexes:reloadIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns)]];
            [self.tableView endUpdates];
            NSUInteger dragRowIndexesLessThanDropRowIndex = [dragRowIndexes countOfIndexesInRange:NSMakeRange(0, rowIndex)];
            NSIndexSet* selectRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rowIndex - dragRowIndexesLessThanDropRowIndex, dragRowIndexes.count)];
            [self.tableView selectRowIndexes:selectRowIndexes byExtendingSelection:NO];
            return YES;
        // drag up
        } else  if (dragRow > rowIndex) {
            NSArray* dragFiles = [self.files objectsAtIndexes:dragRowIndexes];
            [self.tableView beginUpdates];
            [self removeFilesAtIndexes:dragRowIndexes];
//            [self.files removeObjectsAtIndexes:dragRowIndexes];
//            [self.files insertObjects:dragFiles atIndexes:dropRowIndexes];
            [self insertFiles:dragFiles atIndexes:dropRowIndexes];
            NSIndexSet* reloadIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rowIndex, dragRowIndexes.lastIndex - rowIndex)];
            [self.tableView reloadDataForRowIndexes:reloadIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns)]];
            [self.tableView endUpdates];
            [self.tableView selectRowIndexes:dropRowIndexes byExtendingSelection:NO];
            return YES;
        }
        
//         NSData* rowData = [pboard dataForType:MyPrivateTableViewDataType];
//        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData]; NSInteger dragRow = [rowIndexes firstIndex]; // Move the specified row to its new location... // if we remove a row then everything moves down by one // so do an insert prior to the delete // --- depends which way were moving the data!!! if (dragRow < row) { [nsAryOfDataValues insertObject: [nsAryOfDataValues objectAtIndex:dragRow] atIndex:row]; [nsAryOfDataValues removeObjectAtIndex:dragRow]; [self.nsTableViewObj noteNumberOfRowsChanged]; [self.nsTableViewObj reloadData]; return YES; } // end if MyData * zData = [nsAryOfDataValues objectAtIndex:dragRow]; [nsAryOfDataValues removeObjectAtIndex:dragRow]; [nsAryOfDataValues insertObject:zData atIndex:row]; [self.nsTableViewObj noteNumberOfRowsChanged]; [self.nsTableViewObj reloadData]; return YES;
    }
    
    return NO;
}

- (void)addFilePathsToFiles:(NSArray*)filePaths atIndex:(NSInteger)index withAnimation:(NSTableViewAnimationOptions)animationOptions
{
    NSMutableArray* newFiles = [NSMutableArray arrayWithCapacity:filePaths.count];
    NSIndexSet* newFileIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, filePaths.count)];
    
    for (NSString* filePath in filePaths) {
        File* file = [File fileWithPath:filePath];
        [newFiles addObject:file];
    }
    
    [self.tableView beginUpdates];
//    [self.files insertObjects:newFiles atIndexes:newFileIndexes];
    [self insertFiles:newFiles atIndexes:newFileIndexes];
    [self.tableView insertRowsAtIndexes:newFileIndexes withAnimation:animationOptions];
    [self.tableView endUpdates];
    
    [self enableFileButtons:(self.files.count > 0)];
}

- (void)enableGUI:(BOOL)enable
{
    [self.tableView setEnabled:enable];
    
    for (NSView* view in [[self.window contentView] subviews]) {
        if ([view isKindOfClass:[NSButton class]]) {
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
    [self invalidateFiles];
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
    File* file = (self.files)[rowIndex];
    
    if ([aTableColumn.identifier isEqualToString:@"0"])
        return file.name;
    else if ([aTableColumn.identifier isEqualToString:@"1"])
        return file.displaySize;
    else if ([aTableColumn.identifier isEqualToString:@"2"])
        return file.isProcessed ? [NSImage imageNamed:NSImageNameStatusAvailable /* [NSImage imageNamed:@"check32" */ /*NSImageNameMenuOnStateTemplate*/ /*NSImageNameStatusAvailable*/] : [NSImage imageNamed:NSImageNameStatusNone];

    return nil;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self sortTableView:tableView];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex mouseLocation:(NSPoint)mouseLocation
{
    File* file = (self.files)[rowIndex];
    
    if ([aTableColumn.identifier isEqualToString:@"0"])
        return file.path;
    else if ([aTableColumn.identifier isEqualToString:@"1"])
        return [NSString stringWithFormat:@"%llu bytes", file.bytes];
    else if ([aTableColumn.identifier isEqualToString:@"2"])
        return (file.isProcessed) ? @"Stitched" : @"Not yet stitched";

    return nil;
}

// Table row dragging started
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSData* rowData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:@[kFileStitcherPasteboardTableViewType] owner:self];
    [pboard setData:rowData forType:kFileStitcherPasteboardTableViewType];
    
    return YES;
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
    
    [openPanel setAllowsMultipleSelection:YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* fileURLs = [openPanel URLs];
            NSArray* filePaths = [fileURLs valueForKey:NSStringFromSelector(@selector(path))];
            [self addFilePathsToFiles:filePaths atIndex:self.files.count withAnimation:NSTableViewAnimationEffectFade];
        }
    }];
    
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
    [self invalidateFiles];
    
    if (selectedIndexes.firstIndex > 0) {
        NSMutableIndexSet* newSelectedIndexes = [NSMutableIndexSet indexSet];
        
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.files exchangeObjectAtIndex:idx withObjectAtIndex:idx-1];
            [newSelectedIndexes addIndex:idx-1];
        }];
        
        NSIndexSet* reloadIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newSelectedIndexes.firstIndex, selectedIndexes.lastIndex + 1)];
        NSIndexSet* columnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns)];
        
        [self.tableView reloadDataForRowIndexes:reloadIndexes columnIndexes:columnIndexes];
        [self.tableView selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
    }
}

- (IBAction)moveDown:(id)sender 
{
    NSIndexSet* selectedIndexes = [self.tableView selectedRowIndexes];
    [self invalidateFiles];
    
    if (selectedIndexes.lastIndex < self.files.count - 1) {
        NSMutableIndexSet* newSelectedIndexes = [NSMutableIndexSet indexSet];
        
        [selectedIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
             [self.files exchangeObjectAtIndex:idx withObjectAtIndex:idx+1];
             [newSelectedIndexes addIndex:idx+1];
         }];
        
        NSIndexSet* reloadIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selectedIndexes.firstIndex, newSelectedIndexes.lastIndex + 1)];
        NSIndexSet* columnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns)];
        
        [self.tableView reloadDataForRowIndexes:reloadIndexes columnIndexes:columnIndexes];
        [self.tableView selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
    }
}

- (IBAction)removeFilesFromList:(id)sender
{    
//    [self.files removeObjectsAtIndexes:[self.tableView selectedRowIndexes]];
    [self.tableView beginUpdates];
    [self removeFilesAtIndexes:self.tableView.selectedRowIndexes];
    [self.tableView reloadData];
    [self.tableView endUpdates];
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
    if (self.isStitching) {
        self.fileStitcher.stopRequested = YES;
    } else {
        NSNumber* maxValue = [self.files valueForKeyPath:@"@sum.bytes"];
        self.progressIndicator.doubleValue = 0.0;
        self.progressIndicator.maxValue = maxValue.doubleValue;
        
        [self invalidateFiles];
        
        NSSavePanel* savePanel = [NSSavePanel savePanel];
        [savePanel setDelegate:self];
        [savePanel setExtensionHidden:NO];
        [savePanel setAllowsOtherFileTypes:YES];
        [savePanel setCanSelectHiddenExtension:YES];
        
        [savePanel beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                savePanel.title = savePanel.title;
                File* file = [File fileWithPath:self.outputFileName];
                if ([self.files containsObject:file]) {
                    NSAlert* alert = [NSAlert alertWithMessageText:@"Oh no!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"I can't save to the file (%@) when you have it as one of the input files in the list. Remove the file from the list or save to a different file.", file.name];
                    [alert setAlertStyle:NSCriticalAlertStyle];
                    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
                } else {
                    self.isStitching = YES;
                    [self enableGUI:NO];
                    if (!self.fileStitcher) {
                        self.fileStitcher = [FileStitcher new];
                        self.fileStitcher.bufferSize = 16*1024;
                        self.fileStitcher.delegate = self;
                    }
                    [self.fileStitcher stitchFiles:self.files toOutputFile:file];
                }
            }
        }];
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
    if (okFlag) {
        NSSavePanel* panel = (NSSavePanel*)sender;
        self.outputFileName = panel.URL.path;
        return @"*"; // invalid filename to avoid the "replace" prompt
    } else {
        return filename;
    }
}

#pragma mark -
#pragma mark ProgressStepDelegate Protocol

-(void)updateProgressPercentage:(NSNumber*)percentage
{
    if (![[NSThread currentThread] isEqualTo:[NSThread mainThread]]) {
        [self performSelectorOnMainThread:@selector(updateProgressPercentage:) withObject:percentage waitUntilDone:NO];
        return;
    }
    
    [self.progressIndicator incrementBy:percentage.doubleValue];
}

-(void)performProgressStep:(NSNumber*)step
{
    if (![[NSThread currentThread] isEqualTo:[NSThread mainThread]]) {
        [self performSelectorOnMainThread:@selector(performProgressStep:) withObject:step waitUntilDone:NO];
        return;
    }
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:step.unsignedIntegerValue] columnIndexes:[NSIndexSet indexSetWithIndex:(self.tableView.numberOfColumns-1)]];
}

-(void)progressComplete
{
    if (![[NSThread currentThread] isEqualTo:[NSThread mainThread]]) {
        [self performSelectorOnMainThread:@selector(progressComplete) withObject:nil waitUntilDone:NO];
        return;
    }
    
    self.isStitching = NO;
    [self enableGUI:YES];
    [self tableViewRowSelected:nil];
    if (self.fileStitcher.fileIndex < self.fileStitcher.files.count) {
        File* file = (self.fileStitcher.files)[self.fileStitcher.fileIndex];
        NSAlert* alert = [NSAlert alertWithMessageText:@"Incomplete File" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"The saved file is incomplete. The last partial file copied to the output file was a portion of \"%@\", file %d of %lu in the list.\r\n\r\nTrash the incomplete file, \"%@\"?", file.name, self.fileStitcher.fileIndex + 1, (unsigned long)self.fileStitcher.files.count, [self.outputFileName lastPathComponent]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kFullTrashIcon)]];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
//    else {
//        NSAlert* alert = [NSAlert alertWithMessageText:@"Complete" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Your files have been stitched togther."];
//        [alert setAlertStyle:NSInformationalAlertStyle];
//        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
//    }
}

#pragma mark -
#pragma mark NSAlert Modal Delegate - Informal Protocol

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[self.outputFileName stringByDeletingLastPathComponent] destination:@"" files:@[[self.outputFileName lastPathComponent]] tag:nil];        
    }
}

@end
