//
//  ChartViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 3/29/17.
//  Copyright © 2017 Conversa. All rights reserved.
//

#import "ChartViewController.h"

#import "Colors.h"
#import <Charts/Charts-Swift.h>

@interface ChartViewController () <ChartViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *noDataView;
@property (weak, nonatomic) IBOutlet UIView *uivChartInfo;
@property (weak, nonatomic) IBOutlet UILabel *uilMessage;

@end

@implementation ChartViewController

- (void)createChartWith:(ChartType)type title:(NSString*)title data:(NSDictionary *)data {
    self.chartType = type;
    self.titleLabel.text = title;

    switch (type) {
        case PieType: {
            [self setupPieChartView:data];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)setupPieChartView:(NSDictionary*)numbers
{
    double messagesSent = ([numbers objectForKey:@"ms"]) ? [[numbers objectForKey:@"ms"] doubleValue] : 0;
    double messagesReceived = ([numbers objectForKey:@"mr"]) ? [[numbers objectForKey:@"mr"] doubleValue] : 0;

    // Setting data
    if (messagesSent > 0 || messagesReceived > 0) {
        // Create chart
        self.uivChartInfo.hidden = YES;
        PieChartView *chartsView = [[PieChartView alloc] init];

        chartsView.noDataText = NSLocalizedString(@"stats_chart_no_data", nil);

        chartsView.usePercentValuesEnabled = YES;
        chartsView.drawSlicesUnderHoleEnabled = YES;
        chartsView.holeRadiusPercent = 0.58;
        chartsView.transparentCircleRadiusPercent = 0.61;
        chartsView.chartDescription.enabled = NO;

        chartsView.drawHoleEnabled = NO;
        chartsView.rotationAngle = 0.0;
        chartsView.rotationEnabled = NO;
        chartsView.highlightPerTapEnabled = YES;

        ChartLegend *l = chartsView.legend;
        l.horizontalAlignment = ChartLegendHorizontalAlignmentRight;
        l.verticalAlignment = ChartLegendVerticalAlignmentTop;
        l.orientation = ChartLegendOrientationVertical;
        l.drawInside = NO;
        l.xEntrySpace = 0.0;
        l.yEntrySpace = 0.0;
        l.yOffset = 0.0;

        chartsView.delegate = self;

        // entry label styling
        chartsView.entryLabelColor = UIColor.whiteColor;
        chartsView.entryLabelFont = [UIFont systemFontOfSize:12.0f weight:UIFontWeightLight];
        [chartsView animateWithXAxisDuration:1.4 easingOption:ChartEasingOptionEaseOutBack];

        // Add constraints
//        [self.view addSubview:chartsView];
        [self.view insertSubview:chartsView belowSubview:self.titleLabel];
        [self addConstraintsToChart:chartsView];
        self.noDataView.hidden = YES;

        NSMutableArray *values = [[NSMutableArray alloc] init];

        [values addObject:[[PieChartDataEntry alloc] initWithValue:messagesSent
                                                             label:NSLocalizedString(@"stats_pie_chart_sent_label", nil)]];
        [values addObject:[[PieChartDataEntry alloc] initWithValue:messagesReceived
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
        [data setValueFont:[UIFont systemFontOfSize:11.f weight:UIFontWeightLight]];
        [data setValueTextColor:[Colors black]];
        
        chartsView.data = data;

        [chartsView highlightValues:nil];
        [chartsView setNeedsDisplay];
    } else {
        self.uilMessage.text = NSLocalizedString(@"chart_no_data_message", @"Information message when chart data won't display in a correct way");
    }
}

- (void)addConstraintsToChart:(ChartViewBase*)chart {
    UIView *parent = self.view;
    chart.translatesAutoresizingMaskIntoConstraints = NO;

    //Trailing
    NSLayoutConstraint *trailing =[NSLayoutConstraint
                                   constraintWithItem:chart
                                   attribute:NSLayoutAttributeTrailing
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:parent
                                   attribute:NSLayoutAttributeTrailing
                                   multiplier:1.0f
                                   constant:4.0f];

    //Leading
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:chart
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:parent
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.0f
                                   constant:4.0f];

    //Bottom
    NSLayoutConstraint *bottom =[NSLayoutConstraint
                                 constraintWithItem:chart
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:parent
                                 attribute:NSLayoutAttributeBottom
                                 multiplier:1.0f
                                 constant:0.f];

    //Top
    NSLayoutConstraint *height = [NSLayoutConstraint
                                  constraintWithItem:chart
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.titleLabel
                                  attribute:NSLayoutAttributeBottom
                                  multiplier:1.0f
                                  constant:7.0f];


    [parent addConstraint:trailing];
    [parent addConstraint:bottom];
    [parent addConstraint:leading];
    [parent addConstraint:height];
}

@end
