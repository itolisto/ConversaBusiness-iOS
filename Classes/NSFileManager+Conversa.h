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

- (UIImage*)loadAvatarFromLibrary:(NSString*)filename;
- (UIImage*)loadImageFromLibrary:(NSString*)filename;
- (NSString*)loadVideoFromLibrary:(NSString*)filename;
- (NSString*)loadAudioFromLibrary:(NSString*)filename;

#pragma mark - Save/Delete Data Methods -

- (BOOL)saveDataToDocumentsDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory;
- (BOOL)saveDataToLibraryDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory;
- (BOOL)saveDataToCachesDirectory:(NSData *)fileData withName:(NSString *)path andDirectory:(NSString *)directory;

- (BOOL)deleteDataInDocumentsDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error;
- (BOOL)deleteDataInLibraryDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error;
- (BOOL)deleteDataInCachesDirectory:(NSString*)filename inSubDirectory:(NSString*)sub error:(NSError*)error;
- (BOOL)deleteDataInDirectory:(NSString*)filename error:(NSError*)error;

#pragma mark - Directories Methods -

- (NSURL *)applicationCachesDirectory;
- (NSURL *)applicationDocumentsDirectory;
- (NSURL*)applicationLibraryDirectory;
- (BOOL)createDirectory:(NSString *)directoryPath;

@end
