//
//  SelectMenuViewController.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 18..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SelectMenuType)
{
    SelectMenuTypeSmartTour,
    SelectMenuType360VR,
    SelectMenuTypeCoupon
};


@interface SelectMenuViewController : UIViewController

@property (nonatomic, assign) SelectMenuType menuType;
@property (nonatomic, readonly) CouponBookView *couponBookView;

@end

