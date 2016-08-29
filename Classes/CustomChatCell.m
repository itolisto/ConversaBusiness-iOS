//
//  CustomChatCellTableViewCell.m
//  Conversa
//
//  Created by Edgar Gomez on 11/16/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "CustomChatCell.h"

#import "Colors.h"
#import "Business.h"
#import "Constants.h"
#import "YapMessage.h"
#import "YapContact.h"
#import "DatabaseManager.h"
#import "NSFileManager+Conversa.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface CustomChatCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversationLabel;
@property (weak, nonatomic) IBOutlet PFImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *unreadMessage;

@end

@implementation CustomChatCell

- (void)awakeFromNib {
    // Circular
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.unreadMessage.layer.cornerRadius   = self.unreadMessage.frame.size.width / 2;
}

- (void)configureCellWith:(YapContact *)business {
    self.business = business;
    self.avatarImageView.image = [[NSFileManager defaultManager] loadImageFromCache:[business.uniqueId stringByAppendingString:@"_avatar.jpg"]];
    self.nameLabel.text = business.displayName;
    [self updateLastMessage:NO];
}

- (void)updateLastMessage:(BOOL)skipConversationText {
    // Regresar a ultimo mensaje
    __block YapMessage *lastMessage = nil;
    
    [[DatabaseManager sharedInstance].newConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        lastMessage = [self.business lastMessageWithTransaction:transaction];
    }];
    
    if (lastMessage) {
        [self setDateString:lastMessage.date];
        
        if (skipConversationText) {
            return;
        }
        
        UIFont *currentFont = self.conversationLabel.font;
        CGFloat fontSize = currentFont.pointSize;
        self.conversationLabel.text = [self getDisplayText:lastMessage];
        self.unreadMessage.backgroundColor = [UIColor clearColor];
        
        if (lastMessage.isView) {
            self.nameLabel.font = [UIFont systemFontOfSize:fontSize];
            self.nameLabel.textColor = [UIColor blackColor];
        } else {
            self.nameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
            self.nameLabel.textColor = [UIColor blackColor];
            if (lastMessage.isIncoming) {
                self.unreadMessage.backgroundColor = [Colors blueColor];
            }
        }
    } else {
        self.conversationLabel.text = @"¡Comienza a chatear con este negocio!";
        self.dateLabel.text = @"";
    }
}

- (void)setIsTypingText:(BOOL)value {
    if (value) {
        self.conversationLabel.text = @"Escribiendo...";
    } else {
        [self updateLastMessage:NO];
    }
}

- (void)setDateString:(NSDate *)date {
    self.dateLabel.text = [self dateString:date];
}

- (NSString *)dateString:(NSDate *)messageDate {
    NSTimeInterval timeInterval = fabs([messageDate timeIntervalSinceNow]);
    NSString * dateString = nil;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *startOfToday, *startOfOtherDay;
    [cal rangeOfUnit:NSCalendarUnitDay startDate:&startOfToday interval:NULL forDate:[NSDate date]];
    [cal rangeOfUnit:NSCalendarUnitDay startDate:&startOfOtherDay interval:NULL forDate:messageDate];
    NSDateComponents *components = [cal components:NSCalendarUnitDay fromDate:startOfOtherDay toDate:startOfToday options:0];
    NSInteger days = [components day];
    
    if (days == 1) {
        dateString = @"Ayer";
    } else if (timeInterval < 60){
        dateString = @"Ahora";
    } else if (timeInterval < 60*60) {
        int minsInt = timeInterval/60;
        NSString * minString = @"mins";
        
        if (minsInt == 1) {
            minString = @"min";
        }
        
        dateString = [NSString stringWithFormat:@"%d %@",minsInt,minString];
    } else if (timeInterval < 60*60*24){
        // show time in format 11:00 PM
        dateString = [NSDateFormatter localizedStringFromDate:messageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    } else if (timeInterval < 60*60*24*7) {
        // show time in format Monday, Tuesday, Wednesday,...
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEE" options:0 locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    } else if (timeInterval < 60*60*25*365) {
        // show time in format 11/05
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMM" options:0
                                                                    locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    } else {
        // show time in format 11/05/2014
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMYYYY" options:0
                                                                    locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    
    return dateString;
}

- (NSString *)getDisplayText:(YapMessage *)message {
    switch (message.messageType) {
        case kMessageTypeText: {
            return message.text;
        }
        case kMessageTypeLocation: {
            return (message.isIncoming) ? @"Ubicación recibida" : @"Ubicación enviada";
        }
        case kMessageTypeImage: {
            return (message.isIncoming) ? @"Imagen recibida" : @"Imagen enviada";
        }
        case kMessageTypeVideo: {
            return (message.isIncoming) ? @"Video recibido" : @"Video enviado";
        }
        case kMessageTypeAudio: {
            return (message.isIncoming) ? @"Grabación recibida" : @"Grabación enviada";
        }
    }
    
    return @"";
}

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}

@end