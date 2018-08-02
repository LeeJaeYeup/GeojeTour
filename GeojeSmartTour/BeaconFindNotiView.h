//
//  BeaconFindNotiView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 2. 13..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BeaconFindNotiViewDelegate;
@interface BeaconFindNotiView : UIView

-(void)setVisibleWithInfo:(NSDictionary*)info onView:(UIView*)view;
-(void)setInvisible;
-(NSDictionary*)currentShowingNotiInfo;
-(NSString*)currentShowTitle;

@property (nonatomic, weak) id <BeaconFindNotiViewDelegate> delegate;

@end

@protocol BeaconFindNotiViewDelegate <NSObject>

-(void)beaconFindNotiView:(BeaconFindNotiView*)bfnv didFinishInvisibleWithInfo:(NSDictionary*)info;
-(void)didSelectCloseBtnWithBeaconFindNotiView:(BeaconFindNotiView *)bfnv;
-(void)didSelectNotiViewBodyWithBeaconFindNotiView:(BeaconFindNotiView *)bfnv;

@end
