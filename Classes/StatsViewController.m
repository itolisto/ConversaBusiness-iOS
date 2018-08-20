//
//  StatsViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/23/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "StatsViewController.h"

#import "Colors.h"
#import "Utilities.h"
#import "SettingsKeys.h"
#import "Reachability.h"
#import "UIStateButton.h"
#import "ParseValidation.h"

#import <DGActivityIndicatorView/DGActivityIndicatorView.h>

@interface StatsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *sentLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedLabel;
@property (weak, nonatomic) IBOutlet UILabel *favsLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *linksLabel;
@property (weak, nonatomic) IBOutlet UIStateButton *retryButton;

@property (strong, nonatomic) DGActivityIndicatorView *activityIndicatorView;

@end

@implementation StatsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.shadowColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = label;
    label.text = @"Stats";
    [label sizeToFit];

    self.scrollView.contentInset = UIEdgeInsetsMake(14.0, 0.0, 14.0, 0.0);

    // Add border to Button
    [self.retryButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self.retryButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.retryButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    [self.retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeThreeDots
                                                                     tintColor:[Colors purple]
                                                                          size:50.0f];
    self.activityIndicatorView.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    [self.loadingView addSubview:self.activityIndicatorView];
    [self addConstraintsToLoading];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"EDQueueJobDidSucceed"
                                               object:nil];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:refreshControl];

    [self loadData:nil];
}

- (void)receivedNotification:(NSNotification *)notification
{
    NSDictionary *job = [notification valueForKey:@"object"];

    if ([[job objectForKey:@"task"] isEqualToString:@"businessDataJob"]) {
        if (!self.infoView.isHidden) {
            self.infoView.hidden = YES;
        }
        [self loadData:nil];
    }
}

- (IBAction)retryPressed:(UIStateButton *)sender {
    if (!self.infoView.isHidden) {
        self.infoView.hidden = YES;
    }
//    _pieChart.data = nil;
    [self loadData:nil];
}

- (void)refreshData:(UIRefreshControl *)refreshControl
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadData:refreshControl];
        });
    });
}

- (void)loadData:(UIRefreshControl *)refreshControl {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        if (self.loadingView.isHidden) {
            self.loadingView.hidden = NO;
        }
        if (self.infoView.isHidden) {
            self.infoView.hidden = NO;
        }
        if (refreshControl) {
            [refreshControl endRefreshing];
        }
    } else {
        if ([SettingsKeys getBusinessId] == nil || [SettingsKeys getBusinessId].length == 0) {
            if (self.loadingView.isHidden) {
                self.loadingView.hidden = NO;
            }
            if (self.infoView.isHidden) {
                self.infoView.hidden = NO;
            }
            if (refreshControl) {
                [refreshControl endRefreshing];
            }
        } else {
            [self.activityIndicatorView startAnimating];

            NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];

            if (![language isEqualToString:@"es"] && ![language isEqualToString:@"en"]) {
                language = @"en"; // Set to default language
            }
            // TODO: Replace with networking layer
//            [PFCloud callFunctionInBackground:@"getBusinessStatisticsAll"
//                               withParameters:@{@"businessId":[SettingsKeys getBusinessId], @"language":language}
//                                        block:^(NSString*  _Nullable jsonData, NSError * _Nullable error)
//             {
//                 [self.activityIndicatorView stopAnimating];
//
//                 if (refreshControl) {
//                     [refreshControl endRefreshing];
//                 }
//
//                 if (error) {
//                     if ([ParseValidation validateError:error]) {
//                         [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
//                     } else {
//                         if (self.loadingView.isHidden) {
//                             self.loadingView.hidden = NO;
//                         }
//                         if (self.infoView.isHidden) {
//                             self.infoView.hidden = NO;
//                         }
//                     }
//                 } else {
//                     id object = [NSJSONSerialization JSONObjectWithData:[jsonData dataUsingEncoding:NSUTF8StringEncoding]
//                                                                 options:0
//                                                                   error:&error];
//
//                     if (error) {
//                         if (self.loadingView.isHidden) {
//                             self.loadingView.hidden = NO;
//                         }
//                         if (self.infoView.isHidden) {
//                             self.infoView.hidden = NO;
//                         }
//                     } else {
//                         NSMutableDictionary *results = [object mutableCopy];
//
//                         long long sent = 0, received = 0, favs = 0, views = 0, conversations = 0, links = 0;
//
//                         if ([results objectForKey:@"all"]) {
//                             NSDictionary *all = [results objectForKey:@"all"];
//
//                             if ([all objectForKey:@"ms"]) {
//                                 sent = [[all objectForKey:@"ms"] longLongValue];
//                             }
//
//                             if ([all objectForKey:@"mr"]) {
//                                 received = [[all objectForKey:@"mr"] longLongValue];
//                             }
//
//                             if ([all objectForKey:@"nf"]) {
//                                 favs = [[all objectForKey:@"nf"] longLongValue];
//                             }
//
//                             if ([all objectForKey:@"np"]) {
//                                 views = [[all objectForKey:@"np"] longLongValue];
//                             }
//
//                             if ([all objectForKey:@"cn"]) {
//                                 conversations = [[all objectForKey:@"cn"] longLongValue];
//                             }
//
//                             if ([all objectForKey:@"lc"]) {
//                                 links = [[all objectForKey:@"lc"] longLongValue];
//                             }
//
//                             [results removeObjectForKey:@"all"];
//                         }
//
//                         [self setLabelText:self.sentLabel withValue:sent];
//                         [self setLabelText:self.receivedLabel withValue:received];
//                         [self setLabelText:self.favsLabel withValue:favs];
//                         [self setLabelText:self.viewsLabel withValue:views];
//                         [self setLabelText:self.conversationsLabel withValue:conversations];
//                         [self setLabelText:self.linksLabel withValue:links];
//
//                         self.loadingView.hidden = YES;
//                         self.infoView.hidden = YES;
//
//                         if ([results objectForKey:@"charts"]) {
//                             NSDictionary *charts = [results objectForKey:@"charts"];
//                             if ([self.childViewControllers count] > 0 && [charts count] > 0) {
//                                 // At this point is always sure first child view controller is the one we want
//                                 ChartPageViewController *vc = (ChartPageViewController*)[self.childViewControllers objectAtIndex:0];
//                                 [vc loadChartsWithData:charts];
//                             }
//                         }
//                     }
//                 }
//             }];
        }
    }
}

- (void)setLabelText:(UILabel*)label withValue:(long long)value {
    label.text = numberWithFormat(value);
}

- (void)addConstraintsToLoading {
    UIView *parent = self.loadingView;
    self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;

    //CenterX
    NSLayoutConstraint *centerx =[NSLayoutConstraint
                                   constraintWithItem:self.activityIndicatorView
                                   attribute:NSLayoutAttributeCenterX
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:parent
                                   attribute:NSLayoutAttributeCenterX
                                   multiplier:1.0f
                                   constant:0.0f];

    //CenterY
    NSLayoutConstraint *centery =[NSLayoutConstraint
                                 constraintWithItem:self.activityIndicatorView
                                 attribute:NSLayoutAttributeCenterY
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:parent
                                 attribute:NSLayoutAttributeCenterY
                                 multiplier:1.0f
                                 constant:0.0f];

    [parent addConstraint:centerx];
    [parent addConstraint:centery];
}

@end
