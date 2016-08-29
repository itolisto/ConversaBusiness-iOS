//
//  NSNumber+Conversa.h
//  Conversa
//
//  Created by Edgar Gomez on 1/13/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;

@interface NSNumber (Conversa)

+ (NSNumber*)numberWithCGFloat: (CGFloat)value;
- (CGFloat)CGFloatValue;

@end
