//
//  CustomBusinessCell.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CustomBusinessCell.h"

#import "nBusiness.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface CustomBusinessCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@end

@implementation CustomBusinessCell

- (void)awakeFromNib {
    // Circular
    [super awakeFromNib];
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
}

- (void)configureCellWith:(nBusiness*)business {
    self.business = business;
    self.nameLabel.text = business.displayName;
    self.idLabel.text = [@"@" stringByAppendingString:business.conversaId];

    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:business.avatarUrl]
                            placeholderImage:[UIImage imageNamed:@"ic_business_default"]];
}

@end
