//
//  CustomChatCellTableViewCell.h
//  Conversa
//
//  Created by Edgar Gomez on 11/16/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;
@class YapContact;

@interface CustomChatCell : UITableViewCell

@property (assign, nonatomic) NSInteger position;
@property (strong, nonatomic) YapContact *business;

- (void)configureCellWith:(YapContact *)buddy position:(NSInteger)position;
- (void)updateLastMessage:(BOOL)skipConversationText;

@end
