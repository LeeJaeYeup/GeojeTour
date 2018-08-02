//
//  Utility.h
//  GoChangAlime
//
//  Created by min su kwon on 2017. 5. 2..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "SettingView.h"
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, ScreenType)
{
    ScreenType_Unknown,
    ScreenType_3_5,     //960
    ScreenType_4_0,     //1136
    ScreenType_4_7,     //1334
    ScreenType_5_5      //2208
};

@interface Utility : NSObject

@property (nonatomic, readonly) NSMutableDictionary * _Nullable objectSaveDictionary;
@property (nonatomic, readonly) ViewController * _Nullable rootViewControllerPtr;
@property (nonatomic, weak)     SettingView * _Nullable settingView;
@property (nonatomic, readonly) dispatch_queue_t _Nonnull beaconProcessQueue;
@property (nonatomic, readonly) CLLocationManager * _Nullable locationManager;
@property (nonatomic, readonly) BOOL keyBoardVisible;

+(Utility*_Nonnull)sharedObject;

-(ScreenType)screenType;
-(void)setRootViewcontrollerPtr:(ViewController*_Nonnull)ptr;
-(void)setLocationManagerPtr:(CLLocationManager*_Nonnull)ptr;

-(void)setAlphaAnimationWithView:(UIView*_Nonnull)view alpha:(CGFloat)alpha completion:(void (^ __nullable)(BOOL finished))completion;
-(void)setMoveAnimationWithView:(UIView*_Nonnull)view newFrame:(CGRect)frame completion:(void (^ __nullable)(BOOL finished))completion;

-(NSString* _Nullable)textInKeyChainWithIdentifier:(NSString* _Nonnull)identifier;
-(void)saveTextInKeyChainWithIdentifier:(NSString* _Nonnull)identifier saveText:(NSString* _Nonnull)text;
-(NSString*_Nonnull)UUID;
-(NSString*_Nonnull)currentDateWithDateFormat:(NSString*_Nullable)dateFormat;

-(void)makeAlertWithTitle:(NSString* _Nonnull)title message:(NSString* _Nonnull)msg viewController:(UIViewController* _Nonnull)vc;

//토스트 메시지 생성
-(void)showToastWithText:(NSString*_Nullable)text duration:(CGFloat)duration;

@end

