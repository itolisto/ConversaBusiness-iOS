//
//  OTRColors.h
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface Colors : NSObject

+ (UIColor *) yellowColor;
+ (UIColor *) greenColor;
+ (UIColor *) redColor;
+ (UIColor *) blackColor;
+ (UIColor *) whiteColor;
+ (UIColor *) blueColor;
+ (UIColor *) searchBarColor;
+ (UIColor *)darkenColor:(UIColor *)color withValue:(CGFloat)value;

@end