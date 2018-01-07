//
//  CustomBusinessCell.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import <UIKit/UIKit.h>

@class nBusiness;

@interface CustomBusinessCell : UITableViewCell

@property (strong, nonatomic) nBusiness *business;

- (void)configureCellWith:(nBusiness*)business;

@end
