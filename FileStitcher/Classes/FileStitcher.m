//
//  FileStitcher.m
//  FileStitcher
//
//  Created by Kevin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FileStitcher.h"

@implementation FileStitcher

-(id)init
{
    self = [super init];
    if (self) {
        _bufferSize = 4096; // disk page size is 4K
    }
    
    return self;
}

-(void)dealloc
{
    [self cleanUpStream:_istream];
    [self cleanUpStream:_ostream];
}

-(NSString*)description
{
    return [self autoDescription];
}

-(void)stitchFiles:(NSArray*)files toOutputFile:(File*)outFile
{
    self.readyToRead = NO;
    self.readyToWrite = NO;
    self.stopRequested = NO;
    
    self.fileIndex = 0;
    self.files = files;
    
    File* firstFile = (self.files)[0];    
       
    self.istream = [[NSInputStream alloc] initWithFileAtPath:firstFile.path];
    [self.istream setDelegate:self];
    [self.istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.ostream = [[NSOutputStream alloc] initToFileAtPath:outFile.path append:YES];
    [self.ostream setDelegate:self];
    [self.ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.ostream open];
}

-(void)cleanUpStream:(NSStream*)stream
{
    if (stream) {
        if (stream.streamStatus != NSStreamStatusNotOpen)
            [stream close];
        [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

-(void)cleanUpAndComplete
{
    [self cleanUpStream:_istream];
    [self cleanUpStream:_ostream];
    
    if (self.delegate)
        [self.delegate progressComplete];
}

-(void)concatFiles
{
    self.readyToRead = NO;
    self.readyToWrite = NO;
    
    uint8_t buffer[_bufferSize]; 
    NSInteger bytesRead = 0;

    bytesRead = [self.istream read:buffer maxLength:_bufferSize];

    if (bytesRead) {
        NSInteger bytesWritten = [self.ostream write:buffer maxLength:bytesRead];
        if (bytesWritten != bytesRead)
            NSLog(@"Read %ld bytes, wrote %ld bytes.", bytesRead, bytesWritten);
        if (self.delegate)
            [self.delegate updateProgressPercentage:bytesRead];
    } else {
        NSLog(@"Buffer is empty.");
    }
}

-(void)goToNextFile
{    
    if (self.delegate)
        [self.delegate performProgressStep:self.fileIndex];
    
    File* oldFile = self.files[self.fileIndex];
    oldFile.processed = YES;
    
    if (++self.fileIndex < [self.files count]) {
        self.readyToWrite = YES; // Must do this to keep things moving
        File* file = (self.files)[self.fileIndex];
        self.istream = [[NSInputStream alloc] initWithFileAtPath:file.path];
        [self.istream setDelegate:self];
        [self.istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.istream open];
    } else {
        [self cleanUpAndComplete];
    }
}

#pragma mark -
#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    if (self.isStopRequested) {
        [self cleanUpAndComplete];
        return;
    }
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if ([stream isKindOfClass:[NSOutputStream class]]) {
                [self.istream open];
            }
            break;
            
        case NSStreamEventHasBytesAvailable:
            self.readyToRead = YES;
            if (self.isReadyToWrite)
                [self concatFiles];
            break;
        
        case NSStreamEventHasSpaceAvailable:
            self.readyToWrite = YES;
            if (self.isReadyToRead)
                [self concatFiles];
            break;
            
        case NSStreamEventEndEncountered:
            [self cleanUpStream:stream];
            [self goToNextFile];
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Error");
            [self cleanUpStream:_istream];
            [self cleanUpStream:_ostream];
        default:
            break;
    }
}
@end
