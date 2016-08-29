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

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)configureCellWith:(YapContact *)contact {
    self.contact = contact;
    self.usernameLabel.text   = contact.displayName;
    self.conversaIdLabel.text = @"";
}

@end
