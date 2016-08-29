//
//  Message.m
//  Conversa
//
//  Created by Edgar Gomez on 12/28/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Message.h"

#import "Constants.h"
#import <Parse/PFObject+Subclass.h>

@implementation Message

@dynamic file;
@dynamic thumbnail;
@dynamic location;
@dynamic text;
@dynamic width;
@dynamic height;
@dynamic duration;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return kClassMessage;
}

@end