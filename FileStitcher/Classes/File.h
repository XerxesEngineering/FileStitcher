//
//  File.h
//  FileStitcher
//
//  Created by Kevin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+AutoDescription.h"

@interface File : NSObject
{
    NSString* _path;
}

@property (strong) NSString* path;
@property (strong, readonly) NSString* name;
@property (strong, readonly) NSString* sortName;
@property (strong, readonly) NSString* displaySize;
@property (assign, readonly) unsigned long long bytes;
@property (assign, getter = isProcessed) BOOL processed;

+ (File*)fileWithPath:(NSString*)filePath;

- (NSString*)path;
- (void)setPath:(NSString*)filePath;

@end
