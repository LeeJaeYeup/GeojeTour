//
//  WeatherCell.h
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 10. 14..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeatherCell : UITableViewCell <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray *weatherArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) CGFloat rowHeight;
@property (weak, nonatomic) IBOutlet UILabel *headDateLabel;
@property (weak, nonatomic) IBOutlet UIView *backRoundView;

@end
