//
//  OTRSettingTableViewself.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "CustomSettingCell.h"
//#import "BoolSetting.h"
//#import "ViewSetting.h"
//#import "DoubleSetting.h"
//#import "IntSetting.h"

@implementation CustomSettingCell
//@synthesize compareSetting;


//- (void) setSetting:(Setting *)setting {
//    self.textLabel.text = setting.title;
//    self.detailTextLabel.text = setting.settingDescription;
//    
//    if(setting.imageName) {
//        self.imageView.image = [UIImage imageNamed:setting.imageName inBundle:[ConversaAssets resourcesBundle] compatibleWithTraitCollection:nil];
//    } else {
//        self.imageView.image = nil;
//    }
//    
//    UIView *accessoryView = nil;
//    
//    if ([setting isKindOfClass:[BoolSetting class]]) {
//        BoolSetting *boolSetting = (BoolSetting*)setting;
//        UISwitch *boolSwitch = nil;
//        BOOL animated;
//        if (compareSetting == setting) {
//            boolSwitch = (UISwitch*)self.accessoryView;
//            animated = YES;
//        } else {
//            boolSwitch = [[UISwitch alloc] init];
//            [boolSwitch addTarget:boolSetting action:@selector(toggle) forControlEvents:UIControlEventValueChanged];
//            animated = NO;
//        }
//        
//        [boolSwitch setOn:[boolSetting enabled] animated:animated];
//        accessoryView = boolSwitch;
//        self.accessoryType = UITableViewCellAccessoryNone;
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
//    } 
//    else if ([setting isKindOfClass:[ViewSetting class]])
//    {
//        self.accessoryType = ((ViewSetting *)setting).accessoryType;
//        self.selectionStyle = UITableViewCellSelectionStyleBlue;
//    }
//    else if ([setting isKindOfClass:[DoubleSetting class]])
//    {
//        DoubleSetting *doubleSetting = (DoubleSetting*)setting;
//        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
//        valueLabel.backgroundColor = [UIColor clearColor];
//        valueLabel.text = doubleSetting.stringValue;
//        accessoryView = valueLabel;
//    }
//    else if ([setting isKindOfClass:[IntSetting class]])
//    {
//        IntSetting * intSetting = (IntSetting*)setting;
//        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
//        valueLabel.backgroundColor = [UIColor clearColor];
//        valueLabel.text = intSetting.stringValue;
//        accessoryView = valueLabel;
//    }
//    
//    self.accessoryView = accessoryView;
//    compareSetting = setting;
//}

@end
