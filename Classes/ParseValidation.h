//
//  ParseValidation.h
//  Conversa
//
//  Created by Edgar Gomez on 11/12/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;

@interface ParseValidation : NSObject

+ (void)validateError:(NSError *)error controller:(UIViewController *)fromController;

@end