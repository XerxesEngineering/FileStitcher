//
//  FileStitcher.m
//  FileStitcher
//
//  Created by Kevin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FileStitcher.h"

@implementation FileStitcher

@synthesize delegate = _delegate;

@synthesize istream = _istream;
@synthesize ostream = _ostream;

@synthesize isReadyToRead = _isReadyToRead;
@synthesize isReadyToWrite = _isReadyToWrite;

@synthesize files = _files;
@synthesize fileIndex = _fileIndex;

@synthesize bufferSize = _bufferSize;

-(id)init
{
    self = [super init];
    if (self)
    {
        _bufferSize = 4096; // disk page size is 4K
    }
    
    return self;
}

-(void)dealloc
{
    [self cleanUpStream:_istream];
    [self cleanUpStream:_ostream];
    [_files release];
    [super dealloc];
}

-(NSString*)description
{
    return [self autoDescription];
}

-(void)stitchFiles:(NSArray*)files toOutputFile:(File*)outFile
{
    self.isReadyToRead = NO;
    self.isReadyToWrite = NO;
    
    self.fileIndex = 0;
    self.files = files;
    
    File* firstFile = [self.files objectAtIndex:0];
    
       
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
    if (stream)
    {
        if (stream.streamStatus != NSStreamStatusNotOpen)
            [stream close];
        [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [stream release];
        stream = nil;
    }
}

-(void)concatFiles
{
    self.isReadyToRead = NO;
    self.isReadyToWrite = NO;
    
    uint8_t buffer[_bufferSize]; 
    NSInteger bytesRead = 0;

    bytesRead = [self.istream read:buffer maxLength:_bufferSize];

    if (bytesRead)
    {
        NSInteger bytesWritten = [self.ostream write:buffer maxLength:bytesRead];
        if (bytesWritten != bytesRead)
            NSLog(@"Read %ld bytes, wrote %ld bytes.", bytesRead, bytesWritten);
        if (self.delegate)
            [self.delegate performProgressStep:bytesRead];
    }
    else
    {
        NSLog(@"Buffer is empty.");
    }

}

-(void)goToNextFile
{    
    if (++self.fileIndex < [self.files count])
    {
        self.isReadyToWrite = YES; // Must do this to keep things moving
        File* file = [self.files objectAtIndex:self.fileIndex];
        self.istream = [[NSInputStream alloc] initWithFileAtPath:file.path];
        [self.istream setDelegate:self];
        [self.istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.istream open];
    }
    else
    {
        [self cleanUpStream:self.istream];
        [self cleanUpStream:self.ostream];
        
        if (self.delegate)
            [self.delegate progressComplete];
    }
}

#pragma mark -
#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if ([stream isKindOfClass:[NSOutputStream class]])
            {
                [self.istream open];
            }
            break;
            
        case NSStreamEventHasBytesAvailable:
            self.isReadyToRead = YES;
            if (self.isReadyToWrite)
                [self concatFiles];
            break;
        
        case NSStreamEventHasSpaceAvailable:
            self.isReadyToWrite = YES;
            if (self.isReadyToRead)
                [self concatFiles];
            break;
            
        case NSStreamEventEndEncountered:
            [self cleanUpStream:stream];
            [self goToNextFile];
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Error");
            [self cleanUpStream:self.istream];
            [self cleanUpStream:self.ostream];
        default:
            break;
    }
}
@end
