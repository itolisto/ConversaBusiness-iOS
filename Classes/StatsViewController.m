//
//  StatsViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/23/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "StatsViewController.h"

#import "Colors.h"
#import "SettingsKeys.h"
#import "Reachability.h"
#import "UIStateButton.h"
#import "ParseValidation.h"

#import <Parse/Parse.h>
#import <Charts/Charts-Swift.h>
#import <DGActivityIndicatorView/DGActivityIndicatorView.h>

@interface StatsViewController () <ChartViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet PieChartView *pieChart;
@property (weak, nonatomic) IBOutlet UILabel *sentLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedLabel;
@property (weak, nonatomic) IBOutlet UILabel *favsLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (weak, nonatomic) IBOutlet UIStateButton *retryButton;
@property (strong, nonatomic) DGActivityIndicatorView *activityIndicatorView;

@end

@implementation StatsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    label.shadowColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = label;
    label.text = @"Stats";
    [label sizeToFit];

    self.scrollView.contentInset = UIEdgeInsetsMake(14.0, 0.0, 14.0, 0.0);

    [self setupPieChartView:_pieChart];

    // Add border to Button
    [self.retryButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self.retryButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.retryButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    [self.retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeThreeDots
                                                                     tintColor:[Colors purple]
                                                                          size:50.0f];
    self.activityIndicatorView.frame = CGRectMake((self.loadingView.frame.size.width/2) - 35,
                                                  (self.loadingView.frame.size.height/2) - 35,
                                                  70.0f,
                                                  70.0f);
    [self.loadingView addSubview:self.activityIndicatorView];

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
    _pieChart.data = nil;
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
            [PFCloud callFunctionInBackground:@"getBusinessStatisticsAll"
                               withParameters:@{@"business": [SettingsKeys getBusinessId]}
                                        block:^(NSString*  _Nullable jsonData, NSError * _Nullable error)
             {
                 [self.activityIndicatorView stopAnimating];

                 if (refreshControl) {
                     [refreshControl endRefreshing];
                 }

                 if (error) {
                     if ([ParseValidation validateError:error]) {
                         [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
                     } else {
                         if (self.loadingView.isHidden) {
                             self.loadingView.hidden = NO;
                         }
                         if (self.infoView.isHidden) {
                             self.infoView.hidden = NO;
                         }
                     }
                 } else {
                     self.loadingView.hidden = YES;
                     self.infoView.hidden = YES;
                     id object = [NSJSONSerialization JSONObjectWithData:[jsonData dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:&error];
                     if (error) {
                         if (self.loadingView.isHidden) {
                             self.loadingView.hidden = NO;
                         }
                         if (self.infoView.isHidden) {
                             self.infoView.hidden = NO;
                         }
                     } else {
                         NSDictionary *results = object;

                         int sent = 0, received = 0, favs = 0, views = 0;

                         if ([results objectForKey:@"ms"] && [results objectForKey:@"ms"] != [NSNull null]) {
                             sent = [[results objectForKey:@"ms"] doubleValue];
                         }

                         if ([results objectForKey:@"mr"] && [results objectForKey:@"mr"] != [NSNull null]) {
                             received = [[results objectForKey:@"mr"] doubleValue];
                         }

                         if ([results objectForKey:@"nf"] && [results objectForKey:@"nf"] != [NSNull null]) {
                             favs = [[results objectForKey:@"nf"] doubleValue];
                         }

                         if ([results objectForKey:@"np"] && [results objectForKey:@"np"] != [NSNull null]) {
                             views = [[results objectForKey:@"np"] doubleValue];
                         }

                         NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

                         [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                         [formatter setMaximumFractionDigits:1];
                         [formatter setMinimumFractionDigits:1];
                         [formatter setRoundingMode:NSNumberFormatterRoundDown];

                         NSString *sentString, *receivedString, *favsString, *viewsString;

                         if (sent > 999) {
                             sentString = [[formatter stringFromNumber:[NSNumber numberWithDouble:sent/1000.0]] stringByAppendingString:@"K"];
                         } else {
                             sentString = [NSString stringWithFormat:@"%d", sent];
                         }

                         if (received > 999) {
                             receivedString = [[formatter stringFromNumber:[NSNumber numberWithDouble:received/1000.0]] stringByAppendingString:@"K"];
                         } else {
                             receivedString = [NSString stringWithFormat:@"%d", received];
                         }

                         if (favs > 999) {
                             favsString = [[formatter stringFromNumber:[NSNumber numberWithDouble:favs/1000.0]] stringByAppendingString:@"K"];
                         } else {
                             favsString = [NSString stringWithFormat:@"%d", favs];
                         }

                         if (views > 999) {
                             viewsString = [[formatter stringFromNumber:[NSNumber numberWithDouble:views/1000.0]] stringByAppendingString:@"K"];
                         } else {
                             viewsString = [NSString stringWithFormat:@"%d", views];
                         }


                         self.sentLabel.text = sentString;
                         self.receivedLabel.text = receivedString;
                         self.favsLabel.text = favsString;
                         self.viewsLabel.text = viewsString;

                         [self updateChartData:sent received:received];
                     }
                 }
             }];
        }
    }
}

- (void)setupPieChartView:(PieChartView *)chartView
{
    chartView.usePercentValuesEnabled = YES;
    chartView.drawSlicesUnderHoleEnabled = YES;
    chartView.holeRadiusPercent = 0.58;
    chartView.transparentCircleRadiusPercent = 0.61;
    chartView.chartDescription.enabled = NO;

    chartView.drawHoleEnabled = NO;
    chartView.rotationAngle = 0.0;
    chartView.rotationEnabled = NO;
    chartView.highlightPerTapEnabled = YES;

    ChartLegend *l = chartView.legend;
    l.horizontalAlignment = ChartLegendHorizontalAlignmentRight;
    l.verticalAlignment = ChartLegendVerticalAlignmentTop;
    l.orientation = ChartLegendOrientationVertical;
    l.drawInside = NO;
    l.xEntrySpace = 7.0;
    l.yEntrySpace = 0.0;
    l.yOffset = 0.0;

    chartView.delegate = self;

    // entry label styling
    chartView.entryLabelColor = UIColor.whiteColor;
    chartView.entryLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.f];
    [chartView animateWithXAxisDuration:1.4 easingOption:ChartEasingOptionEaseOutBack];
}

- (void)updateChartData:(double)sent received:(double)received
{
    NSMutableArray *values = [[NSMutableArray alloc] init];

    [values addObject:[[PieChartDataEntry alloc] initWithValue:sent
                                                         label:NSLocalizedString(@"stats_pie_chart_sent_label", nil)]];
    [values addObject:[[PieChartDataEntry alloc] initWithValue:received
                                                         label:NSLocalizedString(@"stats_pie_chart_received_label", nil)]];

    PieChartDataSet *dataSet = [[PieChartDataSet alloc] initWithValues:values
                                                                 label:nil];
    dataSet.sliceSpace = 3.0;

    // add a lot of colors
    NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:2];
    [colors addObject:[Colors pieChartReceived]];
    [colors addObject:[Colors pieChartSent]];

    dataSet.colors = colors;

    PieChartData *data = [[PieChartData alloc] initWithDataSet:dataSet];

    NSNumberFormatter *pFormatter = [[NSNumberFormatter alloc] init];
    pFormatter.numberStyle = NSNumberFormatterPercentStyle;
    pFormatter.maximumFractionDigits = 1;
    pFormatter.multiplier = @1.f;
    pFormatter.percentSymbol = @"%";
    [data setValueFormatter:[[ChartDefaultValueFormatter alloc] initWithFormatter:pFormatter]];
    [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:11.f]];
    [data setValueTextColor:[Colors black]];

    _pieChart.data = data;
    [_pieChart highlightValues:nil];
    [_pieChart setNeedsDisplay];
}

@end
