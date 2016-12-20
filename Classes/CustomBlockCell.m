//
//  CustomBlockCell.m
//  Conversa
//
//  Created by Edgar Gomez on 3/1/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CustomBlockCell.h"

#import "YapContact.h"

@implementation CustomBlockCell

- (void)configureCellWith:(YapContact *)contact {
    self.contact = contact;
    self.usernameLabel.text   = contact.displayName;
    self.conversaIdLabel.text = @"";
}

@end
