//
//  BusinessListViewController.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;

@class nBusiness;

@interface BusinessListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray<nBusiness *> *businessList;

@end
