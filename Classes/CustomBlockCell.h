//
//  CustomBlockCell.h
//  Conversa
//
//  Created by Edgar Gomez on 3/1/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;
@class YapContact;

@interface CustomBlockCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversaIdLabel;

@property (strong, nonatomic) YapContact *contact;
- (void)configureCellWith:(YapContact *)contact;

@end
