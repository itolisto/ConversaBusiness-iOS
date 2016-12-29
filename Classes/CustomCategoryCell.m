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

@end

@implementation CustomCategoryCell

- (void)configureCellWith:(nCategory*)category {
    self.category = category;
    self.titleLabel.text = [category getCategoryName];
}

@end
