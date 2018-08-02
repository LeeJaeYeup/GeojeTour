//
//  ViewController.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BeaconDataManager.h"
#import "TopMenuView.h"
#import "IntroView.h"


@protocol ViewControllerDelegate;
@interface ViewController : UIViewController
{
    NSPointerArray      *delegateArray;
}

@property (nonatomic, readonly) BeaconDataManager * _Nonnull  beaconDataManager;
@property (nonatomic) BOOL useLandSscapeOrientation;

-(void)showLoadingView:(BOOL)show;
-(void)showWebViewWithUrl:(NSString* _Nullable)url;
-(void)showBeaconNotiViewWithBeaconInfo:(NSDictionary*_Nullable)beaconInfo contentsBeacon:(BOOL)isContentsBeacon;
-(void)addDelegate:(_Nonnull id <ViewControllerDelegate>)delegate;
-(TopMenuView * _Nonnull)topMenuView;
-(BOOL)isExistBeaconAlrimQueueWithAddBeacon:(NSDictionary*_Nonnull)beaconInfo;
//beaconFullPathLink 에서 비콘 컨텐츠 url 생성하기...
-(NSString* _Nullable)beaconContentsUrlWithFullPathLink:(NSString* _Nonnull)beaconFullPathLink;
-(void)guideViewSetHidden:(BOOL)hidden;

@end

@protocol ViewControllerDelegate <NSObject>

-(void)viewController:(ViewController*_Nonnull)vc didSelectNotiViewWithInfo:(NSDictionary*_Nullable)info;

@end
