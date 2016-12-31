//
//  AppJobs.m
//  Conversa
//
//  Created by Edgar Gomez on 11/30/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "AppJobs.h"

#import "EDQueue.h"
#import "YapContact.h"

@implementation AppJobs

+ (void)addBusinessDataJob
{
    [[EDQueue sharedInstance] enqueueWithData:nil forTask:@"businessDataJob"];
}

+ (void)addDownloadFileJob:(NSString*)messageId url:(NSString*)url messageType:(NSInteger)messageType
{
    if (url == nil || [url length] == 0) {
        return;
    }

    [[EDQueue sharedInstance] enqueueWithData:@{@"messageId" : messageId,
                                                @"url" : url,
                                                @"type" : @(messageType)}
                                      forTask:@"downloadFileJob"];
}

+ (void)addDownloadAvatarJob:(NSString*)url
{
    if (url == nil || [url length] == 0) {
        return;
    }

    [[EDQueue sharedInstance] enqueueWithData:@{@"url" : url}
                                      forTask:@"downloadAvatarJob"];
}

+ (void)addStatusChangeJob:(NSInteger)status oldStatus:(NSInteger)old {
    [[EDQueue sharedInstance] enqueueWithData:@{@"status" : @(status), @"old": @(old)}
                                      forTask:@"statusChangeJob"];
}

+ (void)addRedirectToConversaJob:(BOOL)redirect {
    [[EDQueue sharedInstance] enqueueWithData:@{@"redirect" : @(redirect)}
                                      forTask:@"redirectToConversaJob"];
}

@end
