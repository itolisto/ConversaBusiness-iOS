//
//  DatabaseManager.h
//  Conversa
//
//  Created by Edgar Gomez on 7/18/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;
@import YapDatabase;

@interface DatabaseManager : NSObject

@property (nonatomic, readonly) YapDatabase *database;
//@property (nonatomic, readonly) YapDatabaseConnection *readOnlyDatabaseConnection;
//@property (nonatomic, readonly) YapDatabaseConnection *readWriteDatabaseConnection;
@property (nonatomic, readonly) YapDatabaseConnection *updateDatabaseConnection;

/**
 This method sets up both the yap database and IOCipher media storage
 Before this method is called the passphrase needs to be set.
 
 @param databaseName the name of the database. The media storage with be databaseName-media
 @return whether setup was successful
 */
- (BOOL)setupDatabaseWithName:(NSString*)databaseName;
- (YapDatabaseConnection *)newConnection;
- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error;

/** This only works after calling setDatabasePassphrase */
- (BOOL)hasPassphrase;
- (NSString *)databasePassphrase;
+ (BOOL)existsYapDatabase;
+ (NSString *)yapDatabasePathWithName:(NSString *)name;
+ (instancetype)sharedInstance;

@end