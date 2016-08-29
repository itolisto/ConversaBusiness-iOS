//
//  SettingsViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "SettingsViewController.h"

#import "Colors.h"
#import "Account.h"
#import "Utilities.h"
#import "NetworkUtilities.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor = [Colors greenColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath section] == 2) {
        // Change status connection
        if ([indexPath row] == 0) {
            [self didSelectShareSetting:indexPath];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath section] == 1) {
        // Change status connection
    }
}

- (void)didSelectShareSetting:(NSIndexPath*)indexPath {
    NSString *textToShare = @"Descarga esta app que está genial para contactar a cualquier negocio";
    NSURL *myWebsite = [NSURL URLWithString:@"http://www.conversachat.com/"];
    
    NSArray *objectsToShare = @[textToShare, myWebsite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}




@end
