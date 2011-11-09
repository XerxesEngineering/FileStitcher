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
    NSString* path;
}

@property (retain) NSString* path;
@property (retain, readonly) NSString* name;
@property (retain, readonly) NSString* sortName;
@property (retain, readonly) NSString* displaySize;
@property (assign, readonly) unsigned long long bytes;

+ (File*)fileWithPath:(NSString*)filePath;

- (NSString*)path;
- (void)setPath:(NSString*)filePath;

@end
