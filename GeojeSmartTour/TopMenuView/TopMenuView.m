//
//  TopMenuView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 14..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "TopMenuView.h"
#import "SmartTourismView.h"
#import "StampTourViewController.h"
#import "TopLogoView.h"

@interface TopMenuView ()
{
    TopLogoView                     *topLogoView;
    UIScrollView                    *mainScrollView;
    
    SmartTourismView                *smartTourismView;
    NSInteger                       currentSelectTabIndex;
}

@end

@implementation TopMenuView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]){}
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if(topLogoView == nil)
    {
        //상단 로고뷰
        topLogoView = [[TopLogoView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 100)];
        [self addSubview:topLogoView];
    }
}

@end
