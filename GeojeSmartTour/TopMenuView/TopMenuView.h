//
//  TopMenuView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 14..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CouponBookView.h"

@interface TopMenuView : UIView

@property (nonatomic, readonly) CouponBookView   *couponBookView;
@property (nonatomic, readonly) UINavigationController *stampTourNavigationController;


@end


