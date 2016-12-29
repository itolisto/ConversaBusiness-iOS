//
//  UIStateButton.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/21/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "UIStateButton.h"

@interface UIStateButton ()

@property (nonatomic, assign) BOOL initialized;

@end

@implementation UIStateButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _defaultBorderColor = [UIColor clearColor];
        _selectedBorderColor = [UIColor clearColor];
        _borderRadius = 0.0f;
        _borderWidth = 0.0f;
        _initialized = NO;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _defaultBorderColor = [UIColor clearColor];
        _selectedBorderColor = [UIColor clearColor];
        _borderRadius = 0.0f;
        _borderWidth = 0.0f;
        _initialized = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_borderRadius > 0) {
        if (!_initialized) {
            [[self layer] setBorderWidth:_borderWidth];
            [[self layer] setCornerRadius:_borderRadius];
            [[self layer] setMasksToBounds:YES];
            [[self layer] setBorderColor:_defaultBorderColor.CGColor];
            _initialized = YES;
        }
    }
}

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), color.CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setBackgroundImage:colorImage forState:state];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (_borderWidth > 0) {
        if (highlighted) {
            [[self layer] setBorderColor:_selectedBorderColor.CGColor];
        } else {
            [[self layer] setBorderColor:_defaultBorderColor.CGColor];
        }
    }
}

@end
