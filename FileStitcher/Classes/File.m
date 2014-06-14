//
//  File.m
//  FileStitcher
//
//  Created by Kevin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "File.h"

static dispatch_queue_t path_accessor_queue()
{
    static dispatch_queue_t _path_accessor_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _path_accessor_queue = dispatch_queue_create([NSString stringWithFormat:@"%@.File.path_accessor_queue", [[NSBundle mainBundle].infoDictionary objectForKey:(id)kCFBundleIdentifierKey]].UTF8String, DISPATCH_QUEUE_SERIAL);
    });
    
    return  _path_accessor_queue;
}

#pragma mark -

@interface File ()

@property (readwrite, strong) NSString* name;
@property (readwrite, strong) NSString* sortName;
@property (readwrite, strong) NSString* displaySize;
@property (readwrite, assign) unsigned long long bytes;
@property (readwrite, strong) NSNumber* blockSize;

@end

@implementation File

+ (File*)fileWithPath:(NSString*)filePath
{
    File* file = [File new];
    file.path = filePath;
    return file;
}

+ (NSSet *)keyPathsForValuesAffectingPath
{
    return [NSSet setWithObjects:
            NSStringFromSelector(@selector(name)),
            NSStringFromSelector(@selector(sortName)),
            NSStringFromSelector(@selector(bytes)),
            NSStringFromSelector(@selector(blockSize)),
            NSStringFromSelector(@selector(displaySize)),
            nil];
}

- (NSString*)path
{
    __block id result;
    dispatch_sync(path_accessor_queue(), ^{
        result = _path;
    });
    return result;
}

- (void)setPath:(NSString*)path
{
    dispatch_sync(path_accessor_queue(), ^{
        if (_path != path) {
            NSFileManager* fileMgr = [NSFileManager defaultManager];
            NSError* fileError;
            
            NSDictionary* fileAttr = [fileMgr attributesOfItemAtPath:path error:&fileError];
            NSNumber* fileExtensionHidden = fileAttr[NSFileExtensionHidden];
            
            NSNumber* blockSize;
            NSURL* folderURL = [[NSURL alloc] initFileURLWithPath:[path stringByDeletingLastPathComponent]]; // get the containing folder, as the file may not exist
            [folderURL getResourceValue:&blockSize forKey:NSURLPreferredIOBlockSizeKey error:nil];
            
//                if (fileError != nil) {
//                    NSLog(@"Error reading file (%@) attr: %@", path, fileError.localizedDescription);
//                    return NO;
//                }
            
            _path = path;
            self.name = [fileMgr displayNameAtPath:_path];
            self.sortName = [fileExtensionHidden boolValue] ? _name : [_name stringByDeletingPathExtension];
            self.bytes = [fileAttr fileSize];
            self.blockSize = blockSize;
            self.displaySize = [NSString stringWithFormat:@"%.2f MB", _bytes/1000000.0];
        }
    });
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
