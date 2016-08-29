//
//  NSFileManager+Conversa.h
//  Conversa
//
//  Created by Edgar Gomez on 12/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;

@interface NSFileManager (Conversa)

- (void)enumerateFilesInDirectory:(NSString *)directory block:(void (^)(NSString *fullPath,BOOL *stop))enumerateBlock;
- (BOOL)setFileProtection:(NSString *)fileProtection forFilesInDirectory:(NSString *)directory;
- (BOOL)excudeFromBackUpFilesInDirectory:(NSString *)directory;

#pragma mark - Load Image/Video/Audio Methods -

- (UIImage*)loadImageFromCache:(NSString*)filename;
- (NSString*)loadVideoFromCache:(NSString*)filename;
- (NSString*)loadAudioFromCache:(NSString*)filename;

#pragma mark - Save/Delete Data Methods -

- (BOOL)saveDataToDocumentsDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory;
- (BOOL)saveDataToLibraryDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory;
- (BOOL)saveDataToCachesDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory;
- (BOOL)deleteDataInCachesDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error;

#pragma mark - Directories Methods -

- (NSURL *)applicationCachesDirectory;
- (NSURL *)applicationDocumentsDirectory;
- (NSURL*)applicationLibraryDirectory;
- (BOOL)createDirectory:(NSString *)directoryPath;

@end
