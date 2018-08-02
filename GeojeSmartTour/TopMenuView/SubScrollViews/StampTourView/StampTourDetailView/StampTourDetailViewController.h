//
//  StampTourDetailViewController.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StampTourDetailViewController : UIViewController

@property (nonatomic, strong) NSDictionary *contentsInfoDic;

-(void)loadStampData;

@end
