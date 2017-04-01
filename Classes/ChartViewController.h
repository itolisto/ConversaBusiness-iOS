//
//  ChartViewController.h
//  ConversaManager
//
//  Created by Edgar Gomez on 3/29/17.
//  Copyright © 2017 Conversa. All rights reserved.
//

@import UIKit;

#import "ChartType.h"

@interface ChartViewController : UIViewController

@property (nonatomic, getter = getStatus) ChartType chartType;

- (void)createChartWith:(ChartType)type title:(NSString*)title data:(NSDictionary *)data;

@end
