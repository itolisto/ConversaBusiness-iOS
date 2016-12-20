//
//  Log.h
//  Conversa
//
//  Created by Edgar Gomez on 9/28/15.
//  Copyright © 2015 Conversa. All rights reserved.
//
// Solution #1 [implemented]
// Build Settings -> Allow non modular... was set to true

// Solution #2
// Actually an easier way to fix this is to move the #import statement to the top of the .m file instead (instead of having it in your header file). This way it won't complain that it's including a non-modular header file. I had this problem where 'Allow non-module includes' set to YES did NOT work and so by moving it to my implementation file, it stopped complaining.

@import CocoaLumberjack;

#ifdef DEBUG
static int ddLogLevel = DDLogLevelVerbose;
#else
static int ddLogLevel = DDLogLevelOff;
#endif
