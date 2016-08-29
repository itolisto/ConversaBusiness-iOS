//
//  OneSignalController.h
//  ConversaBusiness
//
//  Created by Edgar Gomez on 7/21/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YapDatabaseConnection, YapMessage, YapContact, PFFile;

@interface OneSignalController : NSObject

+ (void)processMessage:(NSDictionary *)pnMessage userState:(BOOL)state setView:(BOOL)view;
+ (void)saveMessageWithUser:(YapContact*)contact connection:(YapDatabaseConnection*)connection message:(YapMessage*)message file:(PFFile*)file thumbnail:(PFFile*)thumb;

@end
