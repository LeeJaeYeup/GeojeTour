//
//  SettingView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 27..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AlrimSettingType)
{
    AlrimSettingTypeBeaconContents = 0,         //비콘알림
    AlrimSettingTypeSound,                      //비콘사운드
    AlrimSettingTypeVibrate,                    //비콘진동
    AlrimSettingTypeRemoteNotification,         //푸시알림
    AlrimSettingTypeRemoteNotificationSound     //푸시알림 사운드
};

typedef NS_ENUM(NSInteger, LanguageSettingType)
{
    LanguageSettingTypeKor,
    LanguageSettingTypeEng
};

@protocol SettingViewDelegate;
@interface SettingView : UIView

//설정값 리턴해주기
-(BOOL)beaconAlrimEnableValueWithSettingType:(AlrimSettingType)settingType;
//현재 언어설정타입 리턴
-(LanguageSettingType)currentLanguageSettingType;
-(NSDictionary*)currenetLanguageDict;

@property (nonatomic, weak) id <SettingViewDelegate> delegate;

@end

@protocol SettingViewDelegate <NSObject>

-(void)settingView:(SettingView*)settingView didChangeLanguage:(LanguageSettingType)languageType;

@end
