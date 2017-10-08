//
//  CustomCategoryCell.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/20/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;
@class nCategory;

@interface CustomCategoryCell : UITableViewCell

@property (strong, nonatomic) nCategory *category;

- (void)configureCellWith:(nCategory*)category detailText:(BOOL)show;

@end
