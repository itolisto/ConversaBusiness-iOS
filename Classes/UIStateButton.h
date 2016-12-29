//
//  UIStateButton.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/21/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;

@interface UIStateButton : UIButton

- (void)setBackgroundColor:(UIColor *)image forState:(UIControlState)state;

@property (nonatomic) IBInspectable UIColor *selectedBorderColor;
@property (nonatomic) IBInspectable UIColor *defaultBorderColor;
@property (nonatomic) IBInspectable CGFloat borderRadius;
@property (nonatomic) IBInspectable CGFloat borderWidth;

@end
