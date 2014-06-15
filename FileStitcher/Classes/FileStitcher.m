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
        _bufferSize = 4096;
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
    
//    NSDictionary* systemVersionInfo = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
//    NSString* systemVersion = systemVersionInfo[@"ProductVersion"];
    
    SInt32 systemMajorVersion, systemMinorVersion;
    Gestalt(gestaltSystemVersionMajor, &systemMajorVersion);
    Gestalt(gestaltSystemVersionMinor, &systemMinorVersion);
    
    if (systemMajorVersion == 10 && systemMinorVersion < 7) {
        File* firstFile = (self.files)[0];
        
        self.istream = [NSInputStream inputStreamWithFileAtPath:firstFile.path];
        [self.istream setDelegate:self];
        [self.istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        self.ostream = [NSOutputStream outputStreamToFileAtPath:outFile.path append:YES];
        [self.ostream setDelegate:self];
        [self.ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self.ostream open];
    } else {
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    #if __MAC_OS_X_VERSION_MIN_REQUIRED > 1060
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString* queueName = [NSString stringWithFormat:@"%@.IO", [[NSBundle mainBundle].infoDictionary objectForKey:(id)kCFBundleIdentifierKey]];
            
            dispatch_queue_t queue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
            dispatch_group_t group = dispatch_group_create();
            
            size_t blockSizeWrite = (outFile.blockSize != nil && outFile.blockSize > 0) ? outFile.blockSize.unsignedLongValue : self.bufferSize;
            dispatch_io_t io_write = dispatch_io_create_with_path(DISPATCH_IO_STREAM, outFile.path.UTF8String, (O_RDWR | O_CREAT | O_APPEND), (S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH), queue, NULL);
            dispatch_io_set_high_water(io_write, blockSizeWrite);
            
            [self.files enumerateObjectsUsingBlock:^(File* file, NSUInteger idx, BOOL *stop) {
                if (self.isStopRequested) {
                    [self cleanUpAndComplete];
                    *stop = YES;
                    return;
                }
                
                self.fileIndex = (int)idx + 1;
                
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                dispatch_group_enter(group);
                
                size_t blockSizeRead = (file.blockSize != nil && file.blockSize > 0) ? file.blockSize.unsignedLongValue : self.bufferSize;
                dispatch_io_t io_read = dispatch_io_create_with_path(DISPATCH_IO_STREAM, file.path.UTF8String, O_RDONLY, 0, queue, NULL);
                dispatch_io_set_high_water(io_read, blockSizeRead);
                
                dispatch_io_read(io_read, 0, SIZE_MAX, queue, ^(bool done, dispatch_data_t data, int error) {
                    if (error || self.isStopRequested) {
                        [self cleanUpAndComplete];
                        dispatch_io_close(io_write, 0);
                        *stop = YES;
//                        dispatch_group_leave(group); // bad exec
                        return;
                    }
                    
                    if (data) {
                        size_t bytesRead = dispatch_data_get_size(data);
                        if (bytesRead > 0) {
                            dispatch_group_enter(group);
                            dispatch_io_write(io_write, 0, data, queue, ^(bool doneWriting, dispatch_data_t dataToBeWritten, int errorWriting) {
                                if (errorWriting || self.isStopRequested) {
                                    self.stopRequested = YES;
                                    [self cleanUpAndComplete];
                                    dispatch_io_close(io_read, DISPATCH_IO_STOP);
                                    *stop = YES;
                                    dispatch_group_leave(group);
                                    return;
                                }
                                
                                if (self.delegate) {
                                    [self.delegate updateProgressPercentage:@(bytesRead)];
                                }
                                
                                if (doneWriting) {
                                    dispatch_group_leave(group);
                                }
                            });
                        }
                    }
                    
                    if (done) {
                        dispatch_io_close(io_read, 0);
                        file.processed = YES;
                        if (self.delegate) {
                            [self.delegate performProgressStep:@(idx)];
                        }
                        if (self.files.count == (idx+1)) {
                            dispatch_io_close(io_write, 0);
                            [self cleanUpAndComplete];
                        }
                        dispatch_group_leave(group);
                    }
                });
            }];
        });
    #endif
#endif
    }
}

-(void)cleanUpStream:(NSStream*)stream
{
    if (stream) {
        if (stream.streamStatus != NSStreamStatusNotOpen)
            [stream close];
        [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        stream = nil;
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
            [self.delegate updateProgressPercentage:@(bytesRead)];
    } else {
        NSLog(@"Buffer is empty.");
    }
}

-(void)goToNextFile
{    
    if (self.delegate)
        [self.delegate performProgressStep:@(self.fileIndex)];
    
    File* oldFile = self.files[self.fileIndex];
    oldFile.processed = YES;
    
    if (++self.fileIndex < [self.files count]) {
        self.readyToWrite = YES; // Must do this to keep things moving
        File* file = (self.files)[self.fileIndex];
        self.istream = [NSInputStream inputStreamWithFileAtPath:file.path];
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
