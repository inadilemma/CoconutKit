//
//  HLSFileManager.m
//  CoconutKit
//
//  Created by Samuel Défago on 12/13/12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "HLSFileManager.h"

#import "NSArray+HLSExtensions.h"
#import "NSString+HLSExtensions.h"

// TODO: When available in CoconutKit (feature/url-connection branch), check protocol conformance (all methods from the
//       abstract protocol must be implemented, though they have been made optional to avoid compilation warnings)

static HLSFileManager *s_defaultManager = nil;
static NSMutableDictionary *s_rootDirectoryToFileManagerMap = nil;

@implementation HLSFileManager

#pragma mark Class methods

+ (HLSFileManager *)setDefaultManager:(HLSFileManager *)defaultManager
{
    @synchronized(self) {
        HLSFileManager *previousManager = [s_defaultManager autorelease];
        s_defaultManager = [defaultManager retain];
        return previousManager;
    }
}

+ (HLSFileManager *)defaultManager
{
    @synchronized(self) {
        return s_defaultManager;
    }
}

+ (void)registerRootDirectory:(NSString *)rootDirectory forFileManager:(HLSFileManager *)fileManager
{
    if (! [rootDirectory isFilled]) {
        HLSLoggerError(@"Missing root directory");
        return;
    }
    
    // TODO: Use original implementation (if availble) to check whether the root directory acutally
    //       exists or not. Return if this is the case
    
    if (! fileManager) {
        [self unregisterFileManagerForRootDirectory:rootDirectory];
        return;
    }
    
    if (! s_rootDirectoryToFileManagerMap) {
        s_rootDirectoryToFileManagerMap = [NSMutableDictionary dictionary];
    }
    [s_rootDirectoryToFileManagerMap setObject:fileManager forKey:rootDirectory];
    
    if ([s_rootDirectoryToFileManagerMap count] == 1) {
        // TODO: Swizzle methods (NSFileManager, NSData, NSString I/O, etc.). Document which methods are swizzled in .h
    }
}

+ (void)unregisterFileManagerForRootDirectory:(NSString *)rootDirectory
{
    if (! [rootDirectory isFilled]) {
        HLSLoggerError(@"Missing root directory");
        return;
    }
    
    [s_rootDirectoryToFileManagerMap removeObjectForKey:rootDirectory];
    
    if ([s_rootDirectoryToFileManagerMap count] == 0) {
        // TODO: Remove swizzling
    }
}

+ (NSString *)fileManagerForPath:(NSString *)path
{
    NSString *firstPathComponent = [[path componentsSeparatedByString:@"/"] firstObject_hls];
    return [s_rootDirectoryToFileManagerMap objectForKey:firstPathComponent];
}

+ (NSString *)effectivePathForPath:(NSString *)path
{
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    NSString *firstPathComponent = [pathComponents firstObject_hls];
    if ([s_rootDirectoryToFileManagerMap objectForKey:firstPathComponent]) {
        pathComponents = [pathComponents arrayByRemovingObjectAtIndex:0];
        return [pathComponents componentsJoinedByString:@"/"];
    }
    else {
        return path;
    }
}

#pragma mark Convenience methods

- (BOOL)fileExistsAtPath:(NSString *)path
{
    return [self fileExistsAtPath:path isDirectory:NULL];
}

@end
