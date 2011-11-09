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

@interface FileStitcher : NSObject <NSStreamDelegate>

@property (assign) id<ProgressStepDelegate> delegate;

@property (retain) NSInputStream* istream;
@property (retain) NSOutputStream* ostream;

@property (assign) BOOL isReadyToRead;
@property (assign) BOOL isReadyToWrite;

@property (retain) NSArray* files;
@property (assign) int fileIndex;

@property (assign) int bufferSize;

-(void)stitchFiles:(NSArray*)files toOutputFile:(File*)outFile;
-(void)cleanUpStream:(NSStream*)stream;
-(void)concatFiles;
-(void)goToNextFile;

@end
