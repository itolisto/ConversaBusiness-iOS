//
// Copyright (c) 2015 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "Incoming.h"

#import "Log.h"
#import "Video.h"
#import "Account.h"
#import "Utilities.h"
#import "Constants.h"
#import "YapMessage.h"
#import "SettingsKeys.h"
#import "AudioMediaItem.h"
#import "PhotoMediaItem.h"
#import "VideoMediaItem.h"
#import "DatabaseManager.h"
#import "NSNumber+Conversa.h"
#import "NSFileManager+Conversa.h"
#import <JSQMessagesViewController/JSQLocationMediaItem.h>

@interface Incoming()
@end

@implementation Incoming

- (JSQMessage *)create:(YapMessage *)item {
    JSQMessage *message;

    if (item.messageType == kMessageTypeText) message = [self createTextMessage:item];
    if (item.messageType == kMessageTypeVideo) message = [self createVideoMessage:item];
    if (item.messageType == kMessageTypeImage) message = [self createPictureMessage:item];
    if (item.messageType == kMessageTypeAudio) message = [self createAudioMessage:item];
    if (item.messageType == kMessageTypeLocation) message = [self createLocationMessage:item];

    return message;
}

- (JSQMessage *)createTextMessage:(YapMessage *)item {
    NSString *name   = @"user";
    NSString *userId = [SettingsKeys getBusinessId];

    if (item.isIncoming) {
        name   = @"business";
        userId = item.buddyUniqueId;
    }

    NSDate   *date   = item.date;
    NSString *text   = item.text;

    return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date text:text];
}

- (JSQMessage *)createVideoMessage:(YapMessage *)item {
    NSString *name   = @"user";
    NSString *userId = [SettingsKeys getBusinessId];

    if (item.isIncoming) {
        name   = @"business";
        userId = item.buddyUniqueId;
    }

    NSDate   *date   = item.date;
    VideoMediaItem *mediaItem = [[VideoMediaItem alloc] initWithMaskAsOutgoing:!item.isIncoming];
    mediaItem.status = STATUS_LOADING;

    [self loadVideoMedia:item MediaItem:mediaItem];

    return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
}

- (void)loadVideoMedia:(YapMessage *)item MediaItem:(VideoMediaItem *)mediaItem {
    __weak typeof(YapMessage) *wMessage = item;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Create strong reference to the weakSelf inside the block so that it´s not released while the block is running

        NSString *videoData = [[NSFileManager defaultManager] loadVideoFromLibrary:wMessage.filename];

        UIImage *image = nil;
        if (videoData) {
            image = VideoThumbnail([NSURL fileURLWithPath:videoData]);
        }

        // When finished call back on the main thread:
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(YapMessage)*wStrongSelf = wMessage;

            mediaItem.image   = (image) ? image : [UIImage imageNamed:@"retry_media"];
            mediaItem.fileURL = [NSURL fileURLWithPath:videoData];
            mediaItem.status = STATUS_SUCCEED;

            if (videoData && wStrongSelf) {
                [[DatabaseManager sharedInstance].updateDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                    typeof(YapMessage)*sSelf = wMessage;
                    if (sSelf)
                        [sSelf touchMessageWithTransaction:transaction];
                }];
            }
        });
    });
}

- (JSQMessage *)createPictureMessage:(YapMessage *)item {
    NSString *name   = @"user";
    NSString *userId = [SettingsKeys getBusinessId];

    if (item.isIncoming) {
        name   = @"business";
        userId = item.buddyUniqueId;
    }

    NSDate   *date   = item.date;
    PhotoMediaItem *mediaItem = [[PhotoMediaItem alloc] initWithImage:nil
                                                                Width:[NSNumber numberWithCGFloat:item.width]
                                                               Height:[NSNumber numberWithCGFloat:item.height]];
    mediaItem.appliesMediaViewMaskAsOutgoing = !item.isIncoming;
    mediaItem.status = STATUS_LOADING;

    [self loadPhotoMedia:item MediaItem:mediaItem];

    return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
}

- (void)loadPhotoMedia:(YapMessage *)item MediaItem:(PhotoMediaItem *)mediaItem {
    __weak typeof(YapMessage) *wMessage = item;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        UIImage  *image  = [[NSFileManager defaultManager] loadImageFromLibrary:wMessage.filename];

        // When finished call back on the main thread:
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(YapMessage)*wStrongSelf = wMessage;
            if (image && wStrongSelf) {
                mediaItem.image  = image;
                mediaItem.status = STATUS_SUCCEED;

                [[DatabaseManager sharedInstance].updateDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                    typeof(YapMessage)*sSelf = wMessage;
                    if (sSelf)
                        [sSelf touchMessageWithTransaction:transaction];
                }];
            }
        });
    });
}

- (JSQMessage *)createAudioMessage:(YapMessage *)item {
    NSString *name   = @"user";
    NSString *userId = [SettingsKeys getBusinessId];

    if (item.isIncoming) {
        name   = @"business";
        userId = item.buddyUniqueId;
    }

    NSDate   *date   = item.date;
    AudioMediaItem *mediaItem = [[AudioMediaItem alloc] initWithFileURL:nil Duration:item.duration];
    mediaItem.appliesMediaViewMaskAsOutgoing = !item.isIncoming;
    mediaItem.status = STATUS_LOADING;

    [self loadAudioMedia:item MediaItem:mediaItem];

    return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
}

- (void)loadAudioMedia:(YapMessage *)item MediaItem:(AudioMediaItem *)mediaItem {
    __weak typeof(YapMessage) *wMessage = item;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        typeof(YapMessage)*wStrongSelf = wMessage;

        NSString *audioData = [[NSFileManager defaultManager] loadAudioFromLibrary:wStrongSelf.filename];

        // When finished call back on the main thread:
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(YapMessage)*wStrongSelf = wMessage;
            if (audioData && wStrongSelf) {
                mediaItem.fileURL = [NSURL fileURLWithPath:audioData];
                mediaItem.status = STATUS_SUCCEED;

                [[DatabaseManager sharedInstance].updateDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                    typeof(YapMessage)*sSelf = wMessage;
                    if (sSelf)
                        [sSelf touchMessageWithTransaction:transaction];
                }];
            }
        });
    });
}

- (JSQMessage *)createLocationMessage:(YapMessage *)item {
    NSString *name   = @"user";
    NSString *userId = [SettingsKeys getBusinessId];

    if (item.isIncoming) {
        name   = @"business";
        userId = item.buddyUniqueId;
    }

    NSDate   *date   = item.date;
    JSQLocationMediaItem *mediaItem = [[JSQLocationMediaItem alloc] initWithLocation:nil];
    mediaItem.appliesMediaViewMaskAsOutgoing = !item.isIncoming;
    //__weak typeof(YapMessage) *wMessage = item;
    [mediaItem setLocation:item.location withCompletionHandler:^{
        [[DatabaseManager sharedInstance].updateDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
        {
            //DDLogError(@"YapMessage: %@", item);
            //typeof(YapMessage)*sSelf = wMessage;
            if (item)
                [item touchMessageWithTransaction:transaction];
        }];
    }];

    return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
}

@end
