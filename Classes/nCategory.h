//
//  nCategory.h
//  Conversa
//
//  Created by Edgar Gomez on 11/12/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface nCategory : NSObject

@property (strong, nonatomic) NSString *objectId;

- (NSString *)getObjectId;
- (NSString *)getCategoryName;

@end
