//
//  HLSFileManager.m
//  CoconutKit
//
//  Created by Samuel Défago on 12/13/12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "HLSFileManager.h"

#import "HLSRuntime.h"
#import "NSArray+HLSExtensions.h"
#import "HLSLogger.h"
#import "NSString+HLSExtensions.h"

// TODO: When available in CoconutKit (feature/url-connection branch), check protocol conformance (all methods from the
//       abstract protocol must be implemented, though they have been made optional to avoid compilation warnings)

static HLSFileManager *s_defaultManager = nil;
static NSMutableDictionary *s_rootDirectoryToFileManagerMap = nil;

static BOOL (*s_NSFileManager__createDirectoryAtPath_withIntermediateDirectories_attributes_error_Imp)(id, SEL, id, BOOL, id, id *) = NULL;
static id (*s_NSFileManager__contentsOfDirectoryAtPath_error_Imp)(id, SEL, id, id *) = NULL;
static BOOL (*s_NSFileManager__fileExistsAtPath_isDirectory_Imp)(id, SEL, id, BOOL *) = NULL;
static BOOL (*s_NSFileManager__copyItemAtPath_toPath_error_Imp)(id, SEL, id, id, id *) = NULL;
static BOOL (*s_NSFileManager__moveItemAtPath_toPath_error_Imp)(id, SEL, id, id, id *) = NULL;
static id (*s_NSFileManager__contentsAtPath_Imp)(id, SEL, id) = NULL;
static BOOL (*s_NSFileManager__createFileAtPath_contents_attributes_Imp)(id, SEL, id, id, id) = NULL;

static BOOL (*s_NSData__writeToFile_atomically_Imp)(id, SEL, id, BOOL) = NULL;
static BOOL (*s_NSData__writeToFile_options_error_Imp)(id, SEL, id, NSDataWritingOptions, id *) = NULL;
static id (*s_NSData__initWithContentsOfFile_options_error_Imp)(id, SEL, id, NSDataReadingOptions, id *) = NULL;

// TODO: Same for NSString. Swizzle all public methods, regardless of how they are actually implemented

static BOOL swizzled_NSFileManager__createDirectoryAtPath_withIntermediateDirectories_attributes_error_Imp(NSFileManager *self, SEL _cmd, NSString *path, BOOL createIntermediates, NSDictionary *attributes, NSError **pError);
static NSArray *swizzled_NSFileManager__contentsOfDirectoryPath_error_Imp(NSFileManager *self, SEL _cmd, NSString *path, NSError **pError);
static BOOL swizzled_NSFileManager__fileExistsAtPath_isDirectory_Imp(NSFileManager *self, SEL _cmd, NSString *path, BOOL *pIsDirectory);
static BOOL swizzled_NSFileManager__copyItemAtPath_toPath_error_Imp(NSFileManager *self, SEL _cmd, NSString *fromPath, NSString *toPath, NSError **pError);
static BOOL swizzled_NSFileManager__moveItemAtPath_toPath_error_Imp(NSFileManager *self, SEL _cmd, NSString *fromPath, NSString *toPath, NSError **pError);
static NSData *swizzled_NSFileManager__contentsAtPath_Imp(NSFileManager *self, SEL _cmd, NSString *path);
static BOOL swizzled_NSFileManager__createFileAtPath_contents_attributes_Imp(NSFileManager *self, SEL _cmd, NSString *path, NSData *data, NSDictionary *attributes);

static BOOL swizzled_NSData__writeToFile_atomically_Imp(NSData *self, SEL _cmd, NSString *path, BOOL atomically);
static BOOL swizzled_NSData__writeToFile_options_error_Imp(NSData *self, SEL _cmd, NSString *path, NSDataWritingOptions options, NSError **pError);
static id swizzled_NSData__initWithContentsOfFile_options_error_Imp(NSData *self, SEL _cmd, NSString *path, NSDataReadingOptions options, NSError **pError);

@implementation HLSFileManager

#pragma mark Class method

+ (void)load
{
    s_NSFileManager__createDirectoryAtPath_withIntermediateDirectories_attributes_error_Imp = (BOOL (*)(id, SEL, id, BOOL, id, id *))HLSSwizzleSelector([NSFileManager class], @selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:), (IMP)swizzled_NSFileManager__createDirectoryAtPath_withIntermediateDirectories_attributes_error_Imp);
    s_NSFileManager__contentsOfDirectoryAtPath_error_Imp = (id (*)(id, SEL, id, id *))HLSSwizzleSelector([NSFileManager class], @selector(contentsOfDirectoryAtPath:error:), (IMP)swizzled_NSFileManager__contentsOfDirectoryPath_error_Imp);
    s_NSFileManager__fileExistsAtPath_isDirectory_Imp = (BOOL (*)(id, SEL, id, BOOL *))HLSSwizzleSelector([NSFileManager class], @selector(fileExistsAtPath:isDirectory:), (IMP)swizzled_NSFileManager__fileExistsAtPath_isDirectory_Imp);
    s_NSFileManager__copyItemAtPath_toPath_error_Imp = (BOOL (*)(id, SEL, id, id, id *))HLSSwizzleSelector([NSFileManager class], @selector(copyItemAtPath:toPath:error:), (IMP)swizzled_NSFileManager__copyItemAtPath_toPath_error_Imp);
    s_NSFileManager__moveItemAtPath_toPath_error_Imp = (BOOL (*)(id, SEL, id, id, id *))HLSSwizzleSelector([NSFileManager class], @selector(moveItemAtPath:toPath:error:), (IMP)swizzled_NSFileManager__moveItemAtPath_toPath_error_Imp);
    s_NSFileManager__contentsAtPath_Imp = (id (*)(id, SEL, id))HLSSwizzleSelector([NSFileManager class], @selector(contentsAtPath:), (IMP)swizzled_NSFileManager__contentsAtPath_Imp);
    s_NSFileManager__createFileAtPath_contents_attributes_Imp = (BOOL (*)(id, SEL, id, id, id))HLSSwizzleSelector([NSFileManager class], @selector(createFileAtPath:contents:attributes:), (IMP)swizzled_NSFileManager__createFileAtPath_contents_attributes_Imp);
    
    s_NSData__writeToFile_atomically_Imp = (BOOL (*)(id, SEL, id, BOOL))HLSSwizzleSelector([NSData class], @selector(writeToFile:atomically:), (IMP)swizzled_NSData__writeToFile_atomically_Imp);
    s_NSData__writeToFile_options_error_Imp = (BOOL (*)(id, SEL, id, NSDataWritingOptions, id *))HLSSwizzleSelector([NSData class], @selector(writeToFile:options:error:), (IMP)swizzled_NSData__writeToFile_options_error_Imp);
    s_NSData__initWithContentsOfFile_options_error_Imp = (id (*)(id, SEL, id, NSDataReadingOptions, id *))HLSSwizzleSelector([NSData class], @selector(initWithContentsOfFile:options:error:), (IMP)swizzled_NSData__initWithContentsOfFile_options_error_Imp);
}

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

+ (HLSFileManager *)fileManagerForPath:(NSString *)path
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

#pragma mark Swizzled method implementations

static BOOL swizzled_NSFileManager__createDirectoryAtPath_withIntermediateDirectories_attributes_error_Imp(NSFileManager *self, SEL _cmd, NSString *path, BOOL createIntermediates, NSDictionary *attributes, NSError **pError)
{
    HLSFileManager *fileManager = [HLSFileManager fileManagerForPath:path];
    if (! fileManager) {
        return s_NSFileManager__createDirectoryAtPath_withIntermediateDirectories_attributes_error_Imp(self, _cmd, path, createIntermediates, attributes, pError);
    }
    
    NSString *effectivePath = [HLSFileManager effectivePathForPath:path];
    return [fileManager createDirectoryAtPath:effectivePath withIntermediateDirectories:createIntermediates error:pError];
}

static NSArray *swizzled_NSFileManager__contentsOfDirectoryPath_error_Imp(NSFileManager *self, SEL _cmd, NSString *path, NSError **pError)
{
    HLSFileManager *fileManager = [HLSFileManager fileManagerForPath:path];
    if (! fileManager) {
        return s_NSFileManager__contentsOfDirectoryAtPath_error_Imp(self, _cmd, path, pError);
    }
    
    NSString *effectivePath = [HLSFileManager effectivePathForPath:path];
    return [fileManager contentsOfDirectoryAtPath:effectivePath error:pError];
}

static BOOL swizzled_NSFileManager__fileExistsAtPath_isDirectory_Imp(NSFileManager *self, SEL _cmd, NSString *path, BOOL *pIsDirectory)
{
    HLSFileManager *fileManager = [HLSFileManager fileManagerForPath:path];
    if (! fileManager) {
        return s_NSFileManager__fileExistsAtPath_isDirectory_Imp(self, _cmd, path, pIsDirectory);
    }
    
    NSString *effectivePath = [HLSFileManager effectivePathForPath:path];
    return [fileManager fileExistsAtPath:effectivePath isDirectory:pIsDirectory];
}

static BOOL swizzled_NSFileManager__copyItemAtPath_toPath_error_Imp(NSFileManager *self, SEL _cmd, NSString *fromPath, NSString *toPath, NSError **pError)
{
    // TODO: Implement so that paths in & out of the file manager storage can be simultaneously specified
    return s_NSFileManager__copyItemAtPath_toPath_error_Imp(self, _cmd, fromPath, toPath, pError);
}

static BOOL swizzled_NSFileManager__moveItemAtPath_toPath_error_Imp(NSFileManager *self, SEL _cmd, NSString *fromPath, NSString *toPath, NSError **pError)
{
    // TODO: Implement so that paths in & out of the file manager storage can be simultaneously specified
    return s_NSFileManager__moveItemAtPath_toPath_error_Imp(self, _cmd, fromPath, toPath, pError);
}

static NSData *swizzled_NSFileManager__contentsAtPath_Imp(NSFileManager *self, SEL _cmd, NSString *path)
{
    HLSFileManager *fileManager = [HLSFileManager fileManagerForPath:path];
    if (! fileManager) {
        return s_NSFileManager__contentsAtPath_Imp(self, _cmd, path);
    }
    
    NSString *effectivePath = [HLSFileManager effectivePathForPath:path];
    return [fileManager contentsOfFileAtPath:effectivePath error:NULL];
}

static BOOL swizzled_NSFileManager__createFileAtPath_contents_attributes_Imp(NSFileManager *self, SEL _cmd, NSString *path, NSData *data, NSDictionary *attributes)
{
    HLSFileManager *fileManager = [HLSFileManager fileManagerForPath:path];
    if (! fileManager) {
        return s_NSFileManager__createFileAtPath_contents_attributes_Imp(self, _cmd, path, data, attributes);
    }
    
    NSString *effectivePath = [HLSFileManager effectivePathForPath:path];
    return [fileManager createFileAtPath:effectivePath contents:data error:NULL];
}

static BOOL swizzled_NSData__writeToFile_atomically_Imp(NSData *self, SEL _cmd, NSString *path, BOOL atomically)
{
    HLSFileManager *fileManager = [HLSFileManager fileManagerForPath:path];
    if (! fileManager) {
        return s_NSData__writeToFile_atomically_Imp(self, _cmd, path, atomically);
    }
    
    NSString *effectivePath = [HLSFileManager effectivePathForPath:path];
    return [fileManager createFileAtPath:effectivePath contents:self error:NULL];
}

static BOOL swizzled_NSData__writeToFile_options_error_Imp(NSData *self, SEL _cmd, NSString *path, NSDataWritingOptions options, NSError **pError)
{
    return s_NSData__writeToFile_options_error_Imp(self, _cmd, path, options, pError);
}

static id swizzled_NSData__initWithContentsOfFile_options_error_Imp(NSData *self, SEL _cmd, NSString *path, NSDataReadingOptions options, NSError **pError)
{
    return s_NSData__initWithContentsOfFile_options_error_Imp(self, _cmd, path, options, pError);
}
