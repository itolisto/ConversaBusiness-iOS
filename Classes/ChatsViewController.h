//
//  ChatsViewController.h
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;
#import "CustomAblyRealtime.h"

@interface ChatsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, ConversationListener>

@end