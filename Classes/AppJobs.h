//
//  AppJobs.h
//  Conversa
//
//  Created by Edgar Gomez on 11/30/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import Foundation;

@class YapContact;

@interface AppJobs : NSObject

+ (void)addBusinessDataJob;
+ (void)addDownloadFileJob:(NSString*)messageId url:(NSString*)url messageType:(NSInteger)messageType;
+ (void)addDownloadAvatarJob:(NSString*)url;
+ (void)addStatusChangeJob:(NSInteger)status oldStatus:(NSInteger)old;
+ (void)addRedirectToConversaJob:(BOOL)redirect;

@end
