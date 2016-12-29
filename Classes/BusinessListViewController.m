//
//  BusinessListViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "BusinessListViewController.h"

#import "nBusiness.h"
#import "CustomBusinessCell.h"
#import "ContactViewController.h"

@interface BusinessListViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation BusinessListViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    // Remove extra lines
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];

    if (self.businessList == nil) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource Methods -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"CustomBusinessCell";
    CustomBusinessCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];

    if (cell == nil) {
        cell = [[CustomBusinessCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }

    [cell configureCellWith:[self businessForIndexPath:indexPath]];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.businessList count];
}

#pragma mark - Find Method -

- (nBusiness *)businessForIndexPath:(NSIndexPath *)indexPath {
    return [self.businessList objectAtIndex:indexPath.row];
}

#pragma mark - Navigation Method -

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"contactRequestSegue"]) {
        ContactViewController *destination = [segue destinationViewController];
        destination.objectId = ((CustomBusinessCell*)sender).business.objectId;
    }
}

@end
