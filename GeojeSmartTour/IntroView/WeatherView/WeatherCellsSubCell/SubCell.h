//
//  SubCell.h
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 10. 17..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *skyImageView;
@property (weak, nonatomic) IBOutlet UILabel *TemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *wetLabel;
@property (weak, nonatomic) IBOutlet UILabel *rainLabel;

@property (weak, nonatomic) IBOutlet UIView *underLineView;
-(void)setInfo:(NSDictionary*)info;

@end
