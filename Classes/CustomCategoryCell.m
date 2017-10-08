//
//  CustomCategoryCell.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/20/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CustomCategoryCell.h"

#import "nCategory.h"

@interface CustomCategoryCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@implementation CustomCategoryCell

- (void)configureCellWith:(nCategory*)category detailText:(BOOL)show {
    self.category = category;
    self.titleLabel.text = [category getName];
    self.detailLabel.hidden = show;
}

@end
