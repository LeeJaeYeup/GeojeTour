//
//  TopLogoView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 15..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TopLogoViewDelegate;
@interface TopLogoView : UIView

@property (nonatomic, weak) id <TopLogoViewDelegate> delegate;

//상단탭바 선택하기
-(void)setSelectTabbarBtnWithIndex:(NSInteger)index;
//상단탭바 뒤로가기 뷰 설정...
-(void)showBackBtnView:(BOOL)bShow action:(SEL)backBtnAction target:(id)target;

@end


@protocol TopLogoViewDelegate <NSObject>

@optional
-(void)topLogoView:(TopLogoView*)tlView didSelectMenuWithIndex:(NSInteger)index;
-(void)didSelectTopLogoWithLogoView:(UIView*)logoView;

@end
