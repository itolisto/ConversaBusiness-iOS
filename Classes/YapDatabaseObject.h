//
//  OTRYapDatabaseObject.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import YapDatabase;
@import Mantle;

@interface YapDatabaseObject : MTLModel

@property (nonatomic, readonly) NSString *uniqueId;

- (instancetype)initWithUniqueId:(NSString *)uniqueId;
- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
+ (instancetype)fetchObjectWithUniqueID:(NSString*)uniqueID transaction:(YapDatabaseReadTransaction*)transaction;
+ (NSString *)collection;

@end
