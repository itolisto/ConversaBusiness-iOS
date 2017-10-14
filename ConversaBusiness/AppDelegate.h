//
//  AppDelegate.h
//  Conversa
//
//  Created by Edgar Gomez on 12/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;

@import Ably;
#import "EDQueue.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, EDQueueDelegate, ARTPushRegistererDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSTimer *timer;

@end

