//
//  FolderStorageFileManager.m
//  CoconutKit
//
//  Created by Samuel Défago on 12/12/12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "FolderStorageFileManager.h"

@implementation FolderStorageFileManager

- (NSString *)mainFolderPath
{
    static NSString *s_mainFolderPath = nil;
    if (! s_mainFolderPath) {
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        s_mainFolderPath = [[documentPath stringByAppendingPathComponent:@"FolderStorage"] retain];
    }
    return s_mainFolderPath;
}

#pragma mark HLSFileManagerAbstract protocol implementation

- (NSData *)contentsOfFileAtPath:(NSString *)path error:(NSError *__autoreleasing *)pError
{
    NSString *fullPath = [[self mainFolderPath] stringByAppendingPathComponent:path];
    return [NSData dataWithContentsOfFile:fullPath options:NSDataReadingMappedIfSafe error:pError];
}

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)contents error:(NSError *__autoreleasing *)pError
{
    NSString *fullPath = [[self mainFolderPath] stringByAppendingPathComponent:path];
    return [contents writeToFile:fullPath options:NSDataWritingAtomic error:pError];
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)withIntermediateDirectories error:(NSError *__autoreleasing *)pError
{
    NSString *fullPath = [[self mainFolderPath] stringByAppendingPathComponent:path];
    return [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:withIntermediateDirectories attributes:nil error:pError];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)pError
{
    NSString *fullPath = [[self mainFolderPath] stringByAppendingPathComponent:path];
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:pError];
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)pIsDirectory
{
    NSString *fullPath = [[self mainFolderPath] stringByAppendingPathComponent:path];
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:pIsDirectory];
}

- (BOOL)copyItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError *__autoreleasing *)pError
{
    NSString *fullSourcePath = [[self mainFolderPath] stringByAppendingPathComponent:sourcePath];
    NSString *fullDestinationPath = [[self mainFolderPath] stringByAppendingPathComponent:destinationPath];
    return [[NSFileManager defaultManager] copyItemAtPath:fullSourcePath toPath:fullDestinationPath error:pError];
}

- (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError *__autoreleasing *)pError
{
    NSString *fullSourcePath = [[self mainFolderPath] stringByAppendingPathComponent:sourcePath];
    NSString *fullDestinationPath = [[self mainFolderPath] stringByAppendingPathComponent:destinationPath];
    return [[NSFileManager defaultManager] moveItemAtPath:fullSourcePath toPath:fullDestinationPath error:pError];
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError *__autoreleasing *)pError;
{
    NSString *fullPath = [[self mainFolderPath] stringByAppendingPathComponent:path];
    return [[NSFileManager defaultManager] removeItemAtPath:fullPath error:pError];
}

@end
