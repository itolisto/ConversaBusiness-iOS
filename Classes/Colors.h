//
//  OTRColors.h
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface Colors : NSObject

+ (UIColor*)purpleNavbar;
+ (UIColor*)whiteNavbar;
+ (UIColor*)outgoing;
+ (UIColor*)incoming;
+ (UIColor*)green;
+ (UIColor*)black;
+ (UIColor*)white;
+ (UIColor*)blue;
+ (UIColor*)purple;
+ (UIColor*)secondaryPurple;

+ (UIColor*)profileOnline;
+ (UIColor*)profileOffline;
+ (UIColor*)profileAway;

+ (UIColor*)pieChartReceived;
+ (UIColor*)pieChartSent;

+ (UIColor*)darkenColor:(UIColor*)color withValue:(CGFloat)value;

@end
