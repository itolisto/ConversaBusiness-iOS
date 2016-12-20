//
//  NSNumber+Conversa.m
//  Conversa
//
//  Created by Edgar Gomez on 1/13/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "NSNumber+Conversa.h"

@implementation NSNumber (Conversa)

+ (NSNumber*)numberWithCGFloat:(CGFloat)value
{
#if CGFLOAT_IS_DOUBLE
    return [NSNumber numberWithDouble: (double)value];
#else
    return [NSNumber numberWithFloat: value];
#endif
}

- (CGFloat)CGFloatValue
{
#if CGFLOAT_IS_DOUBLE
    return [self doubleValue];
#else
    return [self floatValue];
#endif
}

@end
