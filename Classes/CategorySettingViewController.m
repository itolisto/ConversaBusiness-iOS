//
//  CategorySettingViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/21/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CategorySettingViewController.h"

#import "Colors.h"
#import "nCategory.h"
#import "SettingsKeys.h"
#import "UIStateButton.h"
#import "ParseValidation.h"
#import "CustomCategoryCell.h"

#import <Parse/Parse.h>

@interface CategorySettingViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property(strong, nonatomic) NSMutableArray *categories;
@property(strong, nonatomic) NSMutableArray *selectedCategories;
@property(strong, nonatomic) NSArray *originalCategories;
@property(assign, nonatomic) NSInteger limit;

@end

@implementation CategorySettingViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.categories = [[NSMutableArray alloc] initWithCapacity:30];
    self.selectedCategories = [[NSMutableArray alloc] initWithCapacity:1];
    self.limit = 3;

    // Remove extra lines
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];

    [self loadObjects];
}

- (void)loadObjects {
    NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];

    if (![language isEqualToString:@"es"] && ![language isEqualToString:@"en"]) {
        language = @"en"; // Set to default language
    }

    [PFCloud callFunctionInBackground:@"getBusinessCategories"
                       withParameters:@{@"objectId": [SettingsKeys getBusinessId], @"language": language}
                                block:^(NSString*  _Nullable json, NSError * _Nullable error)
    {
        if (error) {
            if ([ParseValidation validateError:error]) {
                [ParseValidation _handleInvalidSessionTokenError:self];
            }
        } else {
            id object = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                        options:0
                                                          error:&error];
            if (error) {
                // Show error
            } else {
                NSDictionary *results = object;

                NSArray *unsortedIds;
                __block NSMutableArray *unsortedCategory = [NSMutableArray arrayWithCapacity:30];
                NSMutableArray *selectedIds = [NSMutableArray arrayWithCapacity:3];

                if ([results objectForKey:@"ids"] && [results objectForKey:@"ids"] != [NSNull null]) {
                    unsortedIds = [results objectForKey:@"ids"];
                }

                if ([results objectForKey:@"select"] && [results objectForKey:@"select"] != [NSNull null]) {
                    selectedIds = [NSMutableArray arrayWithArray:[results objectForKey:@"select"]];
                }

                if ([results objectForKey:@"limit"] && [results objectForKey:@"limit"] != [NSNull null]) {
                    self.limit = [[results objectForKey:@"limit"] integerValue];
                }

                self.infoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"settings_account_category_limit", nil), self.limit];

                [unsortedIds enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    nCategory *category = [[nCategory alloc] init];
                    category.objectId = [obj objectForKey:@"id"];
                    category.name = [obj objectForKey:@"na"];
                    [unsortedCategory addObject:category];
                }];

                NSArray *sortedArray = [unsortedCategory sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    NSString *first = [(nCategory*)obj1 getName];
                    NSString *second = [(nCategory*)obj2 getName];
                    return [first compare:second];
                }];

                NSMutableArray *sortedCategory = [NSMutableArray arrayWithArray:sortedArray];

                NSMutableArray *unsortedSelectedCategory = [NSMutableArray arrayWithCapacity:3];

                NSInteger size = [sortedCategory count];
                NSInteger selectedSize = [selectedIds count];

                if (selectedSize > 0) {
                    for (int i = 0; i < size; i++) {
                        nCategory *category = (nCategory*)[sortedCategory objectAtIndex:i];
                        if ([category.objectId isEqualToString:[selectedIds objectAtIndex:0]]) {
                            // Add category to selected
                            [unsortedSelectedCategory addObject:category];
                            // Remove from both arrays
                            [sortedCategory removeObjectAtIndex:i];
                            [selectedIds removeObjectAtIndex:0];
                            // Restart counter
                            i = -1;
                            // Decrement selected size array count
                            selectedSize--;
                            size--;

                            if (selectedSize == 0) {
                                break;
                            }
                        }
                    }
                }

                NSArray *sortedSelectedArray = [unsortedSelectedCategory sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    NSString *first = [(nCategory*)obj1 getName];
                    NSString *second = [(nCategory*)obj2 getName];
                    return [first compare:second];
                }];

                self.categories = sortedCategory;
                self.selectedCategories = [NSMutableArray arrayWithArray:sortedSelectedArray];
                self.originalCategories = [NSArray arrayWithArray:sortedSelectedArray];

                self.loadingView.hidden = YES;
                
                [self reload];
            }
        }
    }];
}

#pragma mark - UITableViewDataSource Methods -

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return ([self.selectedCategories count] == 0) ? NSLocalizedString(@"settings_account_profile_category_category", nil) : NSLocalizedString(@"settings_account_profile_category_selected", nil);
    } else {
        return NSLocalizedString(@"settings_account_profile_category_category", nil);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([self.selectedCategories count] == 0) ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return ([self.selectedCategories count] == 0) ? [self.categories count] : [self.selectedCategories count];
    } else {
        return [self.categories count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCategoryCell" forIndexPath:indexPath];

    if ([indexPath section] == 0) {
        if ([self.selectedCategories count] == 0) {
            [cell configureCellWith:[self.categories objectAtIndex:[indexPath row]]];
        } else {
            [cell configureCellWith:[self.selectedCategories objectAtIndex:[indexPath row]]];
        }
    } else {
        [cell configureCellWith:[self.categories objectAtIndex:[indexPath row]]];
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([indexPath section] == 0) ? YES : NO;
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger section = 1;

    if ([self.selectedCategories count] == 0) {
        section = 0;
    }

    if ([indexPath section] == section) {
        if ([self.selectedCategories count] < self.limit) {
            [self.selectedCategories addObject:[self.categories objectAtIndex:[indexPath row]]];
            [self.categories removeObjectAtIndex:[indexPath row]];

            NSArray *sortedSelectedArray = [self.selectedCategories sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSString *first = [(nCategory*)obj1 getName];
                NSString *second = [(nCategory*)obj2 getName];
                return [first compare:second];
            }];

            self.selectedCategories = [NSMutableArray arrayWithArray:sortedSelectedArray];
            
            [self reload];
        } else {
            // Show alert
        }
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                            title:NSLocalizedString(@"chats_cell_action_delete", nil)
                                                                          handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        [self.categories addObject:[self.selectedCategories objectAtIndex:[indexPath row]]];
        [self.selectedCategories removeObjectAtIndex:[indexPath row]];

        NSArray *sortedSelectedArray = [self.categories sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *first = [(nCategory*)obj1 getName];
            NSString *second = [(nCategory*)obj2 getName];
            return [first compare:second];
        }];

        self.categories = [NSMutableArray arrayWithArray:sortedSelectedArray];

        [self reload];
    }];
    
    return @[deleteAction];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([indexPath section] == 0) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

#pragma mark - Action Method -

- (void)reload {
    [self.tableView reloadData];

    if ([self.originalCategories isEqualToArray:self.selectedCategories]) {
        [[self.view viewWithTag:5971] removeFromSuperview];
    } else {
        if ([self.view viewWithTag:5971] == nil) {
            UIStateButton *goToTop = [UIStateButton buttonWithType:UIButtonTypeCustom];

            float X_Co = self.view.frame.size.width - 80;
            float Y_Co = self.view.frame.size.height - 80;
            [goToTop setFrame:CGRectMake(X_Co, Y_Co, 60, 60)];

            [goToTop setTitle:@"Save" forState:UIControlStateNormal];

            [goToTop setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [goToTop setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

            [goToTop setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
            [goToTop setBackgroundColor:[Colors purple] forState:UIControlStateHighlighted];

            [goToTop.layer setBorderColor:[[UIColor whiteColor] CGColor]];
            goToTop.layer.cornerRadius = 30;
            goToTop.clipsToBounds = YES;

            [goToTop addTarget:self action:@selector(saveCategories) forControlEvents:UIControlEventTouchUpInside];
            goToTop.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];

            [goToTop setTag:5971];

            [self.view addSubview:goToTop];
        }
    }
}

- (void)saveCategories {
    __block NSMutableArray *select = [NSMutableArray arrayWithCapacity:self.limit];

    [self.selectedCategories enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [select addObject:((nCategory*)obj).objectId];
    }];


    [PFCloud callFunctionInBackground:@"updateBusinessCategory"
                       withParameters:@{@"categories": select,
                                        @"objectId": [SettingsKeys getBusinessId],
                                        @"limit": @(self.limit)}
                                block:^(id  _Nullable object, NSError * _Nullable error)
    {
        if (error) {
            if (self.isViewLoaded && self.view.window) {
                [[self.view viewWithTag:5971] removeFromSuperview];
            }

            if ([ParseValidation validateError:error]) {
                [ParseValidation _handleInvalidSessionTokenError:self];
            }
        } else {

            if (self.isViewLoaded && self.view.window) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }];
}

@end
