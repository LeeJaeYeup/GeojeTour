//
//  WeatherView.h
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 10. 11..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeatherView : UIView

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *currentLocationLabel;

@property (weak, nonatomic) IBOutlet UIView *selectLocationView;

@property (weak, nonatomic) IBOutlet UIImageView *currentSkyImgView;
@property (weak, nonatomic) IBOutlet UILabel *rn1Label;
@property (weak, nonatomic) IBOutlet UILabel *rehLabel;
@property (weak, nonatomic) IBOutlet UILabel *vec_wsdLabel;

@property (weak, nonatomic) IBOutlet UILabel *weather1HDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *T1H_SKYLabel;
@property (weak, nonatomic) IBOutlet UIView *T3hParentView;
@property (weak, nonatomic) IBOutlet UILabel *t3h_titleLabel;

@property (weak, nonatomic) IBOutlet UITableView *weatherTableView;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIView *loadingViewsBackgroundView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

//날씨정보 새로고침
-(void)reloadCurrentWeatherInfo;

@end
