//
//  DatabaseManager.m
//  Conversa
//
//  Created by Edgar Gomez on 7/18/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "DatabaseManager.h"

@import SAMKeychain;
#import "Log.h"
#import "Constants.h"
#import "YapMessage.h"
#import "DatabaseView.h"

#import <YapDatabase/YapDatabaseRelationship.h>

@interface DatabaseManager ()

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) NSString *inMemoryPassphrase;
@property (nonatomic, strong) YapDatabaseConnection *updateDatabaseConnection;

@end

@implementation DatabaseManager

#pragma mark - Singleton Method -

+ (instancetype)sharedInstance
{
    static id databaseManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        databaseManager = [[self alloc] init];
    });
    return databaseManager;
}

#pragma mark - Setup Methods -

- (BOOL) setupDatabaseWithName:(NSString*)databaseName
{
    if ([self setupYapDatabaseWithName:databaseName] )
        return YES;

    return NO;
}

- (BOOL)setupYapDatabaseWithName:(NSString *)name
{
    // Define password for encryption
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.cipherKeyBlock = ^{
        NSString *passphrase = [self databasePassphrase];
        NSData *keyData = [passphrase dataUsingEncoding:NSUTF8StringEncoding];

        if (!keyData.length) {
            [NSException raise:@"Must have passphrase of length > 0" format:@"password length is %d.", (int)keyData.length];
        }

        return keyData;
    };

    // Check if database directory isn't created, if is not, create otherwise do nothing
    NSString *databaseDirectory = [[self class] yapDatabaseDirectory];

    if (![[NSFileManager defaultManager] fileExistsAtPath:databaseDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:databaseDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    // Init database instance
    NSString *databasePath = [[self class] yapDatabasePathWithName:name];
    self.database = [[YapDatabase alloc] initWithPath:databasePath
                                           serializer:nil
                                         deserializer:nil
                                              options:options];

    self.database.defaultObjectPolicy = YapDatabasePolicyShare;
    self.database.defaultObjectCacheLimit = 900;

    self.updateDatabaseConnection = [self.database newConnection];
    self.updateDatabaseConnection.name = @"updateDatabaseConnection";

    // After initialize database, register standard views, it's almost impossible to get an error here
    [DatabaseView registerRelationshipDatabase];
    [DatabaseView registerConversationDatabaseView];
    [DatabaseView registerChatDatabaseView];
    [DatabaseView registerSecondaryIndexes];

    if (self.database) {
        return YES;
    } else {
        //        UIAlertController * view =  [UIAlertController
        //                                     alertControllerWithTitle:nil
        //                                     message:@"No se ha podido desencriptar la base de datos. Si la aplicación no funciona correctamente, puede que sea necesario reinstalarla"
        //                                     preferredStyle:UIAlertControllerStyleActionSheet];
        //        UIAlertAction* ok = [UIAlertAction
        //                                 actionWithTitle:@"Cancelar"
        //                                 style:UIAlertActionStyleCancel
        //                                 handler:^(UIAlertAction * action) {
        //                                     [view dismissViewControllerAnimated:YES completion:nil];
        //                                 }];
        //
        //        [view addAction:ok];
        //        [self presentViewController:view animated:YES completion:nil];
        return NO;
    }
}

- (YapDatabaseConnection *)newConnection
{
    return [self.database newConnection];
}

+ (NSString *)yapDatabaseDirectory
{
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSString *directory = [applicationSupportDirectory stringByAppendingPathComponent:applicationName];
    return directory;
}

+ (NSString *)yapDatabasePathWithName:(NSString *)name
{
    return [[self yapDatabaseDirectory] stringByAppendingPathComponent:name];
}

+ (BOOL)existsYapDatabase
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self yapDatabasePathWithName:kYapDatabaseName]];
}

- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error
{
    if (rememeber) {
        self.inMemoryPassphrase = nil;
        [SAMKeychain setPassword:passphrase forService:kYapDatabaseServiceName account:kYapDatabasePassphraseAccountName error:error];
    } else {
        [SAMKeychain deletePasswordForService:kYapDatabaseServiceName account:kYapDatabasePassphraseAccountName];
        self.inMemoryPassphrase = passphrase;
    }
}

- (BOOL)hasPassphrase
{
    return [self databasePassphrase].length != 0;
}

- (NSString *)databasePassphrase
{
    if (self.inMemoryPassphrase) {
        return self.inMemoryPassphrase;
    } else {
        return [SAMKeychain passwordForService:kYapDatabaseServiceName account:kYapDatabasePassphraseAccountName];
    }
}

@end
