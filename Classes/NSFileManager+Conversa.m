//
//  NSFileManager+Conversa.h
//  Conversa
//
//  Created by Edgar Gomez on 12/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//
//
//  FileSave.m
//
//  Created by Anthony Levings on 10/03/2014.
//  Copyright (c) 2014 Gylphi. All rights reserved. You are free to use this code but we'd grateful if you acknowledge the source when using the code or reproducing it.
//


#import "NSFileManager+Conversa.h"
#import "Constants.h"

@implementation NSFileManager (Conversa)

#pragma mark - Protection Files Methods -

- (void)enumerateFilesInDirectory:(NSString *)directory block:(void (^)(NSString *fullPath,BOOL *stop))enumerateBlock {
    BOOL isDirecotry = NO;
    BOOL exists = [self fileExistsAtPath:directory isDirectory:&isDirecotry];
    if (enumerateBlock && isDirecotry && exists) {
        NSDirectoryEnumerator *directoryEnumerator = [self enumeratorAtPath:directory];
        NSString *file = nil;
        BOOL stop = NO;
        while ((file = [directoryEnumerator nextObject]) && !stop) {
            NSString *path = [NSString pathWithComponents:@[directory,file]];
            enumerateBlock(path,&stop);
        }
    }
}

- (BOOL)setFileProtection:(NSString *)fileProtection forFilesInDirectory:(NSString *)directory {
    __block BOOL success = YES;
    [self enumerateFilesInDirectory:directory block:^(NSString *fullPath, BOOL *stop) {
        success = [self setAttributes:@{NSFileProtectionKey:fileProtection}
                         ofItemAtPath:fullPath error:nil];
        *stop = !success;
    }];
    return success;
}

- (BOOL)excudeFromBackUpFilesInDirectory:(NSString *)directory {
    __block BOOL success = YES;
    [self enumerateFilesInDirectory:directory block:^(NSString *fullPath, BOOL *stop) {
        success = [self setAttributes:@{NSURLIsExcludedFromBackupKey:@(YES)} ofItemAtPath:fullPath error:nil];
        *stop = !success;
    }];
    return success;
}

#pragma mark - Load Image/Video/Audio Methods -

- (UIImage*)loadAvatarFromLibrary:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString* path = [libraryDirectory stringByAppendingPathComponent:kMessageMediaAvatarLocation];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:filename];
    return [UIImage imageWithContentsOfFile:path];
}

- (UIImage*)loadImageFromLibrary:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString* path = [libraryDirectory stringByAppendingPathComponent:kMessageMediaImageLocation];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:filename];
    return [UIImage imageWithContentsOfFile:path];
}

- (NSString*)loadVideoFromLibrary:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString* path = [libraryDirectory stringByAppendingPathComponent:kMessageMediaVideoLocation];
    path = [path stringByAppendingString:@"/"];
    return [path stringByAppendingString:filename];
}

- (NSString*)loadAudioFromLibrary:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString* path = [libraryDirectory stringByAppendingPathComponent:kMessageMediaAudioLocation];
    path = [path stringByAppendingString:@"/"];
    return [path stringByAppendingString:filename];
}

#pragma mark - Save/Delete Data Methods -

- (BOOL)saveDataToDocumentsDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory {
    // Remove unnecessary slash if need
    path = [self stripSlashIfNeeded:path];
    directory = [self stripSlashIfNeeded:directory];
    // Create generic beginning to file save path
    NSMutableString *savePath = [[NSMutableString alloc] initWithFormat:@"%@/",[self applicationDocumentsDirectory].path];
    if (directory) {
        [savePath appendString:directory];
        [self createDirectory:[savePath copy]];
        [savePath appendString:@"/"];
    }
    // Add requested save path
    [savePath appendString:path];
    // Save the file and see if it was successful
    if ([[NSFileManager defaultManager] fileExistsAtPath:[savePath copy]]) {
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:savePath]) {
            if ([[NSFileManager defaultManager] removeItemAtPath:savePath error:nil]) {
                return [[NSFileManager defaultManager] createFileAtPath:[savePath copy] contents:fileData attributes:nil];
            } else {
                NSLog(@"saveDataToDocumentsDirectory: Error removing file at path: %@", path);
                return NO;
            }
        }

        return NO;
    } else {
        return [[NSFileManager defaultManager] createFileAtPath:[savePath copy] contents:fileData attributes:nil];
    }
}

- (BOOL)saveDataToLibraryDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory {
    // Remove unnecessary slash if need
    path = [self stripSlashIfNeeded:path];
    directory = [self stripSlashIfNeeded:directory];
    // Create generic beginning to file save path
    NSMutableString *savePath = [[NSMutableString alloc] initWithFormat:@"%@/",[self applicationLibraryDirectory].path];
    if (directory){
        [savePath appendString:directory];
        [self createDirectory:[savePath copy]];
        [savePath appendString:@"/"];
    }
    // Add requested save path
    [savePath appendString:path];
    NSLog(@"%@",savePath);
    // Save the file and see if it was successful
    if ([[NSFileManager defaultManager] fileExistsAtPath:[savePath copy]]) {
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:savePath]) {
            if ([[NSFileManager defaultManager] removeItemAtPath:savePath error:nil]) {
                return [[NSFileManager defaultManager] createFileAtPath:[savePath copy] contents:fileData attributes:nil];
            } else {
                NSLog(@"saveDataToLibraryDirectory: Error removing file at path: %@", path);
                return NO;
            }
        }

        return NO;
    } else {
        return [[NSFileManager defaultManager] createFileAtPath:[savePath copy] contents:fileData attributes:nil];
    }
}

- (BOOL)saveDataToCachesDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory {
    // Remove unnecessary slash if need
    path      = [self stripSlashIfNeeded:path];
    directory = [self stripSlashIfNeeded:directory];
    // Create generic beginning to file save path
    NSMutableString *savePath = [[NSMutableString alloc] initWithFormat:@"%@/",[self applicationCachesDirectory].path];
    if (directory){
        [savePath appendString:directory];
        [self createDirectory:[savePath copy]];
        [savePath appendString:@"/"];
    }

    // Add requested save path
    [savePath appendString:path];
    NSLog(@"%@",savePath);
    // Save the file and see if it was successful
    if ([[NSFileManager defaultManager] fileExistsAtPath:[savePath copy]]) {
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:savePath]) {
            if ([[NSFileManager defaultManager] removeItemAtPath:savePath error:nil]) {
                return [[NSFileManager defaultManager] createFileAtPath:[savePath copy] contents:fileData attributes:nil];
            } else {
                NSLog(@"saveDataToCachesDirectory: Error removing file at path: %@", path);
                return NO;
            }
        }

        return NO;
    } else {
        return [[NSFileManager defaultManager] createFileAtPath:[savePath copy] contents:fileData attributes:nil];
    }
}

- (BOOL)deleteDataInDocumentsDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error {
    NSString *path = [[self applicationDocumentsDirectory] absoluteString];
    path = [path stringByAppendingString:sub];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:filename];
    BOOL success = NO;

    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        if (error) {
            success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        } else {
            success = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }

        if (!success) {
            if (error) {
                NSLog(@"deleteDataInDocumentsDirectory: Error removing file at path: %@", error.localizedDescription);
            }
        }
    }

    return success;
}

- (BOOL)deleteDataInLibraryDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error {
    NSString *path = [[self applicationLibraryDirectory] absoluteString];
    path = [path stringByAppendingString:sub];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:filename];
    BOOL success = NO;

    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        if (error) {
            success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        } else {
            success = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }

        if (!success) {
            if (error) {
                NSLog(@"deleteDataInLibraryDirectory: Error removing file at path: %@", error.localizedDescription);
            }
        }
    }

    return success;
}

- (BOOL)deleteDataInCachesDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error {
    NSString *path = [[self applicationCachesDirectory] absoluteString];
    path = [path stringByAppendingString:sub];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:filename];
    BOOL success = NO;

    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        if (error) {
            success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        } else {
            success = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }

        if (!success) {
            if (error) {
                NSLog(@"deleteDataInCachesDirectory: Error removing file at path: %@", error.localizedDescription);
            }
        }
    }

    return success;
}

- (BOOL)deleteDataInDirectory:(NSString*)filename error:(NSError*)error {
    BOOL success = NO;

    if ([[NSFileManager defaultManager] isDeletableFileAtPath:filename]) {
        if (error) {
            success = [[NSFileManager defaultManager] removeItemAtPath:filename error:&error];
        } else {
            success = [[NSFileManager defaultManager] removeItemAtPath:filename error:nil];
        }

        if (!success) {
            if (error) {
                NSLog(@"deleteDataInDirectory: Error removing file at path: %@", error.localizedDescription);
            }
        }
    }

    return success;
}

#pragma mark - Directories Methods -

- (NSURL *)applicationCachesDirectory {
    NSString *cachesDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)
        cachesDirectory = [paths objectAtIndex:0];

    return [NSURL URLWithString:cachesDirectory];
    //return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationDocumentsDirectory {
    NSString *documentsDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)
        documentsDirectory = [paths objectAtIndex:0];

    return [NSURL URLWithString:documentsDirectory];
}

- (NSURL*)applicationLibraryDirectory {
    NSString *libraryDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)
        libraryDirectory = [paths objectAtIndex:0];

    return [NSURL URLWithString:libraryDirectory];
}

- (BOOL)createDirectory:(NSString *)directoryPath {
    NSError *error;
    BOOL isDir;
    BOOL exists = [self fileExistsAtPath:directoryPath isDirectory:&isDir];
    if (exists) {
        if (isDir) {
            /* Directory already exists, don't create it again */
            return YES;
        }
    }

    BOOL success = [self createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) NSLog(@"%@",error);

    return success;
}

- (NSString *)stripSlashIfNeeded:(NSString *)stringWithPossibleSlash {
    // If the file name contains a slash at the beginning then we remove so that we don't end up with two
    if ([stringWithPossibleSlash compare:@"/" options:NSLiteralSearch range:NSMakeRange(0, 1)]==NSOrderedSame) {
        stringWithPossibleSlash = [stringWithPossibleSlash substringFromIndex:1];
    }
    // Return the string with no slash at the beginning
    return stringWithPossibleSlash;
}

@end
