//
//  SelectMenuViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 18..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "SelectMenuViewController.h"
#import "SmartTourismView.h"
#import "VRListView.h"
#import "CouponBookView.h"


@interface SelectMenuViewController () <VRListViewDelegate>
{
    VRListView *vrListView;
    SmartTourismView *smartTourismView;
    BOOL viewDidLayoutSubviews;
}

@property (weak, nonatomic) IBOutlet UIView *topNaviView;
@property (weak, nonatomic) IBOutlet UIView *contentsView;
@property (weak, nonatomic) IBOutlet UILabel *topNaviTitleLabel;
@property (strong, nonatomic) NSString *vr360TopNaviTitleStr;

@end

@implementation SelectMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];
    NSArray *mainMenuTitleArr = [languageInfoDic objectForKey:@"lk_intro_main_menu_text"];
    
    if(languageInfoDic != nil)
    {
        NSArray *titleArray = @[[mainMenuTitleArr objectAtIndex:0],
                                [mainMenuTitleArr objectAtIndex:1],
                                [mainMenuTitleArr objectAtIndex:3]];
        
        //타이틀 설정
        _topNaviTitleLabel.text = titleArray[_menuType];
        
        self.vr360TopNaviTitleStr = titleArray[1];
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if(viewDidLayoutSubviews == NO)
    {
        NSLog(@"viewDidLayoutSubviews");
        viewDidLayoutSubviews = YES;
        
        //스마트관광
        if(_menuType == SelectMenuTypeSmartTour)
        {
            smartTourismView = [[SmartTourismView alloc] initWithFrame:_contentsView.bounds];
            [_contentsView addSubview:smartTourismView];
        }
        //360VR
        else if(_menuType == SelectMenuType360VR)
        {
            vrListView = [[VRListView alloc] initWithFrame:_contentsView.bounds];
            vrListView.delegate = self;
            [_contentsView addSubview:vrListView];
        }
        //할인쿠폰
        else if(_menuType == SelectMenuTypeCoupon)
        {
            _couponBookView = [[CouponBookView alloc] initWithFrame:_contentsView.bounds];
            [_contentsView addSubview:_couponBookView];
        }
    }
}

#pragma mark - 상단 빽버튼

- (IBAction)pressedBackBtn:(id)sender
{
    if(vrListView)
    {
        if(vrListView.vrPlayerView != nil)
        {
            _topNaviTitleLabel.text = self.vr360TopNaviTitleStr;
            [vrListView.vrPlayerView removeFromSuperview];
            vrListView.vrPlayerView = nil;
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if(smartTourismView)
    {
        if([smartTourismView contentsListView].alpha > 0)
        {
            [UTILITY setAlphaAnimationWithView:[smartTourismView contentsListView]
                                         alpha:0.f
                                    completion:nil];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

#pragma mark -

-(void)didSelectListWithTitle:(NSString*)title
{
    _topNaviTitleLabel.text = title;
}


@end
