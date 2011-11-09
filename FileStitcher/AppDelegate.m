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

@synthesize files;
@synthesize fileStitcher;
@synthesize outputFileName;

- (void)dealloc
{
    [super dealloc];
}
	
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.files = [NSMutableArray array];
    
    static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;
    
    NSSortDescriptor* fileSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) 
     {
         NSRange obj1Range = NSMakeRange(0, [obj1 length]);
         return [obj1 compare:obj1 options:comparisonOptions range:obj1Range locale:[NSLocale currentLocale]];
     }];
    
    NSTableColumn* fileColumn = [self.tableView tableColumnWithIdentifier:@"0"];
    [fileColumn setSortDescriptorPrototype:fileSortDescriptor];
    
    NSSortDescriptor* sizeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bytes" ascending:YES];
    
    NSTableColumn* sizeColumn = [self.tableView tableColumnWithIdentifier:@"1"];
    [sizeColumn setSortDescriptorPrototype:sizeSortDescriptor];
    
    // smooths out the animation - http://www.cocoabuilder.com/archive/cocoa/242344-determinate-nsprogressindicator-animation.html
    [self.progressIndicator setUsesThreadedAnimation:YES];
    
    [self.window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

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
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) 
    {
        // Depending on the dragging source and modifier keys,
        // the file data may be copied or linked
        if (sourceDragMask & NSDragOperationLink) 
        {
            NSArray* filePaths = [pboard propertyListForType:NSFilenamesPboardType];
            [self addFilePathsToFiles:filePaths];
        } 
        //        else 
        //        {
        //            [self addDataFromFiles:files];
        //        }
    }
    
    return YES;
}

- (void) addFilePathsToFiles:(NSArray*)filePaths
{
    for (NSString* filePath in filePaths)
    {
        File* file = [File fileWithPath:filePath];
        [self.files addObject:file];
    }
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark NSTableViewDataSource Protocol

-(NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
    return [self.files count];
}

-(id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualToString:@"0"])
    {
        File* file = [self.files objectAtIndex:rowIndex];
        return file.name;
    }
    else if ([aTableColumn.identifier isEqualToString:@"1"])
    {
        File* file = [self.files objectAtIndex:rowIndex];
        return file.displaySize;
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self.files sortUsingDescriptors:tableView.sortDescriptors];
    [tableView reloadData];
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
            NSArray* filePaths = [openPanel filenames];
            [self addFilePathsToFiles:filePaths];
        }
    }];
    
    [openPanel release];
}

- (IBAction)sortFiles:(id)sender 
{
    static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;
    
    NSSortDescriptor* fileSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) 
    {
        NSRange obj1Range = NSMakeRange(0, [obj1 length]);
        return [obj1 compare:obj1 options:comparisonOptions range:obj1Range locale:[NSLocale currentLocale]];
    }];
    
    NSSortDescriptor* sizeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bytes" ascending:YES];
    
    NSArray* sortDescriptors = [NSArray arrayWithObjects:fileSortDescriptor, sizeSortDescriptor, nil];
    
    //[self.files sortUsingDescriptors:sortDescriptors];
    [self.tableView setSortDescriptors:sortDescriptors];
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
        
        [self.tableView reloadData];
        [self.tableView selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
    }
}

- (IBAction)moveDown:(id)sender 
{
    NSIndexSet* selectedIndexes = [self.tableView selectedRowIndexes];
    
    if (selectedIndexes.lastIndex < self.files.count - 1)
    {
        NSMutableIndexSet* newSelectedIndexes = [NSMutableIndexSet indexSet];
        
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) 
         {
             [self.files exchangeObjectAtIndex:idx withObjectAtIndex:idx+1];
             [newSelectedIndexes addIndex:idx+1];
         }];
        
        [self.tableView reloadData];
        [self.tableView selectRowIndexes:newSelectedIndexes byExtendingSelection:NO];
    }
}

- (IBAction)clearFiles:(id)sender 
{
    [self.files removeAllObjects];
    [self.tableView reloadData];
}

- (IBAction)stitchFilesClick:(id)sender 
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
                NSLog(@"Output file (%@) is equal to one of the input files.", self.outputFileName);
            }
            else
            {
                int bufferSize = maxValue / [self.files count];
                bufferSize = (bufferSize % 2 == 0) ? bufferSize : bufferSize;
                self.fileStitcher = [[FileStitcher new] autorelease];
                self.fileStitcher.bufferSize = 16*1024;
                self.fileStitcher.delegate = self;
                [self.fileStitcher stitchFiles:self.files toOutputFile:file];
            }
        }
    }];
    
    [savePanel release];
}

#pragma mark -
#pragma mark NSOpenSavePanelDelegate Protocol

- (NSString*)panel:(id)sender userEnteredFilename:(NSString*)filename confirmed:(BOOL)okFlag
{
    if (okFlag)
    {
        NSSavePanel* panel = (NSSavePanel*)sender;
        self.outputFileName = panel.filename;
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
    
}

@end
