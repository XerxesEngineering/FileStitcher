//
//  File.m
//  FileStitcher
//
//  Created by Kevin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "File.h"

@interface File ()

@property (readwrite, retain) NSString* name;
@property (readwrite, retain) NSString* sortName;
@property (readwrite, retain) NSString* displaySize;
@property (readwrite, assign) unsigned long long bytes;

@end

@implementation File

@synthesize name;
@synthesize sortName;
@synthesize displaySize;
@synthesize bytes;

+ (File*)fileWithPath:(NSString*)filePath
{
    File* file = [File new];
    file.path = filePath;
    return [file autorelease];
}

- (NSString*)path
{
    id result;
    @synchronized(path)
    {
        result = [[path retain] autorelease];
    }
    return result;
}

- (void)setPath:(NSString*)filePath
{
    @synchronized(self)
    {
        if (path != filePath)
        {
            [path release];
            
            NSFileManager* fileMgr = [NSFileManager defaultManager];
            NSError* fileError;
            
            NSDictionary* fileAttr = [fileMgr attributesOfItemAtPath:filePath error:&fileError];
            NSNumber* fileExtensionHidden = [fileAttr objectForKey:NSFileExtensionHidden];
            
//                if (fileError != nil)
//                {
//                    NSLog(@"Error reading file (%@) attr: %@", filePath, fileError.localizedDescription);
//                    return NO;
//                }
            
            path = [filePath retain];
            self.name = [fileMgr displayNameAtPath:path];
            self.sortName = [fileExtensionHidden boolValue] ? name : [name stringByDeletingPathExtension];
            self.bytes = [fileAttr fileSize];
            self.displaySize = [NSString stringWithFormat:@"%.2f MB", bytes/1000000.0];
        }
    }
}

-(NSString*)description
{
    return [self autoDescription];
}

-(BOOL)isEqual:(File*)file
{
    return [self.path isEqualToString:file.path];
}

@end
