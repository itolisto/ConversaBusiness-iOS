//
//  Message.h
//  Conversa
//
//  Created by Edgar Gomez on 12/28/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;
#import <Parse/Parse.h>

@interface Message : PFObject<PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) PFFile *file;
@property (nonatomic, strong) PFFile *thumbnail;
@property (nonatomic, strong) PFGeoPoint *location;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSNumber *width;   // For image
@property (nonatomic, strong) NSNumber *height;  // For image
@property (nonatomic, strong) NSNumber *duration;// For video and audio

@end