//
//  OTRColors.m
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "Colors.h"

@implementation Colors

+ (UIColor*)yellowColor {
    // gold: #FFBB5C
    return [UIColor colorWithRed:245.f/255.f green:186.f/255.f blue:98.f/255.f alpha:1.f];
}

+ (UIColor*)greenColor {
    // green: #37FF77
    return [UIColor colorWithRed:55.0f/255.0f green:255.0f/255.0f blue:119.0f/255.0f alpha:1.0];
}

+ (UIColor*)purpleNavbarColor {
    // green: #ba8cea
    return [UIColor colorWithRed:186.0f/255.0f green:140.0f/255.0f blue:234.0f/255.0f alpha:1.0];
}

+ (UIColor*)whiteNavbarColor {
    // white: #F7F7F7
    return [UIColor colorWithRed:249.0f/255.0f green:249.0f/255.0f blue:249.0f/255.0f alpha:1.0];
}

+ (UIColor*)outgoingColor {
    // green: #69F0AE
    return [UIColor colorWithRed:105.0f/255.0f green:240.0f/255.0f blue:174.0f/255.0f alpha:1.0];
}

+ (UIColor*)incomingColor {
    // green: #F0F0F0
    return [UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0];
}

+ (UIColor*)greenSearchAnimationColor {
    // green: #7BFFA5
    return [UIColor colorWithRed:123.0f/255.0f green:255.0f/255.0f blue:165.0f/255.0f alpha:1.0];
}

+ (UIColor*)redColor {
    // red: #FF264A
    return [UIColor colorWithRed:255.0f/255.0f green:38.0f/255.0f blue:74.0f/255.0f alpha:1.0];
}

+ (UIColor*)blackColor {
    // black: #494949
    return [UIColor colorWithRed:73.0f/255.0f green:73.0f/255.0f blue:73.0f/255.0f alpha:1.0];
}

+ (UIColor*)whiteColor {
    // white: #F7F7F7
    return [UIColor colorWithRed:249.0f/255.0f green:249.0f/255.0f blue:249.0f/255.0f alpha:1.0];
}

+ (UIColor*)blueColor {
    // blue: #0A7BF6
    return [UIColor colorWithRed:10.0f/255.0f green:123.0f/255.0f blue:246.0f/255.0f alpha:1.0];
}

+ (UIColor*)searchBarColor {
    // white: #EDEEEE
    return [UIColor colorWithRed:237.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0];
}

+ (UIColor*)profileOnlineColor {
    // white: #00E676
    return [UIColor colorWithRed:237.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0];
}

+ (UIColor*)profileOfflineColor {
    // white: #F44336
    return [UIColor colorWithRed:237.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0];
}

+ (UIColor*)profileAwayColor {
    // white: #FFB300
    return [UIColor colorWithRed:237.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0];
}

+ (UIColor*)darkenColor:(UIColor*)color withValue:(CGFloat)value {
    NSUInteger totalComponents = CGColorGetNumberOfComponents(color.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;

    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(color.CGColor);
    CGFloat newComponents[4];

    if (isGreyscale) {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[2] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[3] = oldComponents[1];
    } else {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[1] - value < 0.0f ? 0.0f : oldComponents[1] - value;
        newComponents[2] = oldComponents[2] - value < 0.0f ? 0.0f : oldComponents[2] - value;
        newComponents[3] = oldComponents[3];
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
    CGColorSpaceRelease(colorSpace);

    UIColor *retColor = [UIColor colorWithCGColor:newColor];
    CGColorRelease(newColor);

    return retColor;
}

@end
