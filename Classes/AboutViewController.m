//
//  AboutViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 2/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end