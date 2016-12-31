//
//  nCountry.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/30/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface nCountry : NSObject

@property (strong, nonatomic, getter=getObjectId) NSString *objectId;
@property (strong, nonatomic, getter=getName) NSString *name;

@end
