//
//  BaseTableViewController.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/19/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;

#import "YapMessage.h"
#import "YapContact.h"
#import "SettingsKeys.h"
#import "DatabaseManager.h"
#import "CustomAblyRealtime.h"

#import "ConversaManager-Swift.h"

@interface BaseTableViewController : UITableViewController <ConversationListener>

- (UIViewController *)topViewController;

@end
