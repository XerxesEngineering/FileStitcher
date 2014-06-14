//
//  FileStitcher.h
//  FileStitcher
//
//  Created by Kevin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "File.h"
#import "ProgressStepDelegate.h"
#import "NSObject+AutoDescription.h"

@interface FileStitcher : NSObject <NSStreamDelegate>

@property (unsafe_unretained) id<ProgressStepDelegate> delegate;

@property (strong) NSInputStream* istream;
@property (strong) NSOutputStream* ostream;

@property (assign, getter = isReadyToRead) BOOL readyToRead;
@property (assign, getter = isReadyToWrite) BOOL readyToWrite;
@property (assign, getter = isStopRequested) BOOL stopRequested;

@property (strong) NSArray* files;
@property (assign) int fileIndex;

@property (assign) int bufferSize;

-(void)stitchFiles:(NSArray*)files toOutputFile:(File*)outFile;
-(void)cleanUpStream:(NSStream*)stream;
-(void)cleanUpAndComplete;
-(void)concatFiles;
-(void)goToNextFile;

@end
