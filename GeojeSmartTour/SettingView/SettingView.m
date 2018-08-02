//
//  SettingView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 27..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "SettingView.h"
#import "TheConnection.h"

//언어설정 관련
#define kSaveLanguageState              @"languageState"
#define kSetLanguageKor                 @"languageKor"
#define kSetLanguageEng                 @"languageEng"

#define kReceiveBeaconAlrim             @"receiveBeaconAlrim"
#define kBeaconSoundYN                  @"beaconSoundYN"
#define kBeaconVibrateYN                @"beaconVibrateYN"
#define kRemoteNotificationYN           @"remoteNotificationYN"
#define kRemoteNotificationSouond       @"remoteNotificationSoundYN"

#define kUrlRemoteNotificationYN        [NSString stringWithFormat:@"%@/user/app/push/setPushUse.do?",BASE_URL]
#define kUrlRemoteNotificationSoundYN   [NSString stringWithFormat:@"%@/user/app/push/pushSet.do?",BASE_URL]

@interface SettingView () <TheConnectionDelegate>
{
    NSMutableDictionary     *currentSettingConnectionInfo;
    LanguageSettingType     currentLanguageSettingType;
}

@property (strong, nonatomic) IBOutlet UIView *xibMainView;
@property (weak, nonatomic) IBOutlet UIButton *beaconAlrimOnOffSwitchBtn;
@property (weak, nonatomic) IBOutlet UIButton *beaconSoundYNBtn;
@property (weak, nonatomic) IBOutlet UIButton *beaconVibrateYNBtn;
@property (weak, nonatomic) IBOutlet UIButton *remotePushYNBtn;
@property (weak, nonatomic) IBOutlet UIButton *remotePushSoundYNBtn;

//언어설정
@property (weak, nonatomic) IBOutlet UIButton *setLanguageKorBtn;
@property (weak, nonatomic) IBOutlet UIButton *setLanguageEngBtn;
@property (strong, nonatomic) NSDictionary *currenetLanguageDict;

//텍스트 라벨
@property (weak, nonatomic) IBOutlet UILabel *topTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *receiveInfoTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconInfoReceiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconSoundSetLabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconVibrateSetLabel;
@property (weak, nonatomic) IBOutlet UILabel *pushReceiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *pushSoundSetLabel;
@property (weak, nonatomic) IBOutlet UILabel *languageSetLabel;

@property (weak, nonatomic) IBOutlet UILabel *versionInfoStr;

@end

@implementation SettingView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"SettingView" owner:self options:nil];
        [_xibMainView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_xibMainView];
        [UTILITY setSettingView:self];
        
        currentSettingConnectionInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        _beaconAlrimOnOffSwitchBtn.selected = [self beaconAlrimEnableValueWithSettingType:AlrimSettingTypeBeaconContents];
        _beaconSoundYNBtn.selected = [self beaconAlrimEnableValueWithSettingType:AlrimSettingTypeSound];
        _beaconVibrateYNBtn.selected = [self beaconAlrimEnableValueWithSettingType:AlrimSettingTypeVibrate];
        _remotePushYNBtn.selected = [self beaconAlrimEnableValueWithSettingType:AlrimSettingTypeRemoteNotification];
        _remotePushSoundYNBtn.selected = [self beaconAlrimEnableValueWithSettingType:AlrimSettingTypeRemoteNotificationSound];
        
        //언어 설정값 불러와서 UI에 반영하기..
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *languageState = [defaults objectForKey:kSaveLanguageState];
        
        if(languageState == nil)
            languageState = kSetLanguageKor;
        
//        NSLog(@"languageState : %@",languageState);
        
        //영어가 선택되어 있을때
        if([languageState isEqualToString:kSetLanguageEng])
        {
            [_setLanguageEngBtn setSelected:YES];
            currentLanguageSettingType = LanguageSettingTypeEng;
        }
        //한국어
        else if([languageState isEqualToString:kSetLanguageKor])
        {
            [_setLanguageKorBtn setSelected:YES];
            currentLanguageSettingType = LanguageSettingTypeKor;
        }
        
        //설정된 언어값에 따라서 UI텍스트를 설정한다
        [self setAllUITextWithLanguageType:currentLanguageSettingType];
        
        //앱 버전정보
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersionStr = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
        _versionInfoStr.text = appVersionStr;
    }
    
    return self;
}

//설정값 리턴해주기
-(BOOL)beaconAlrimEnableValueWithSettingType:(AlrimSettingType)settingType
{
    NSString *settingKey = nil;
    
    if(settingType == AlrimSettingTypeBeaconContents)
        settingKey = kReceiveBeaconAlrim;
    else if(settingType == AlrimSettingTypeSound)
        settingKey = kBeaconSoundYN;
    else if(settingType == AlrimSettingTypeVibrate)
        settingKey = kBeaconVibrateYN;
    else if(settingType == AlrimSettingTypeRemoteNotification)
        settingKey = kRemoteNotificationYN;
    else if(settingType == AlrimSettingTypeRemoteNotificationSound)
        settingKey = kRemoteNotificationSouond;
    
    NSString *isOn = [UTILITY textInKeyChainWithIdentifier:settingKey];
    
    if([isOn isEqualToString:@"Y"] || isOn.length < 1)      return YES;
    
    return NO;
}

//현재 언어설정타입 리턴
-(LanguageSettingType)currentLanguageSettingType
{
    return currentLanguageSettingType;
}

//현재 언어설정에 맞는 텍스트가 들어있는 NSDictionary 리턴
-(NSDictionary*)currenetLanguageDict
{
    return _currenetLanguageDict;
}

#pragma mark - private

-(void)setAllUITextWithLanguageType:(LanguageSettingType)languageType
{
    //사용자가 선택한 언어가 저장되어 있는 딕셔너리 파일을 불러온다.
    NSString *languageState = kSetLanguageKor;
    
    if(languageType == LanguageSettingTypeEng)
        languageState = kSetLanguageEng;
    
    NSString *languagePlistPath = [[NSBundle mainBundle] pathForResource:languageState ofType:@"plist"];
    self.currenetLanguageDict = [NSDictionary dictionaryWithContentsOfFile:languagePlistPath];
    
    _topTitleLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_top_title"];
    _receiveInfoTitleLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_receive_title"];
    _beaconInfoReceiveLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_beacon_receive_text1"];
    _beaconSoundSetLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_beacon_receive_text2"];
    _beaconVibrateSetLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_beacon_receive_text3"];
    
    _pushReceiveLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_push_receive_text1"];
    _pushSoundSetLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_push_receive_text2"];
    _languageSetLabel.text = [_currenetLanguageDict objectForKey:@"lk_setting_info_language_text"];
}

//설정값 저장하기
-(void)saveBeaconAlrimEnableValue:(BOOL)enable settingType:(AlrimSettingType)settingType
{
    NSString *isOn = @"Y";
    if(enable == NO)
        isOn = @"N";

    NSString *keyStr = nil;
    
    if(settingType == AlrimSettingTypeBeaconContents)
        keyStr = kReceiveBeaconAlrim;
    else if(settingType == AlrimSettingTypeSound)
        keyStr = kBeaconSoundYN;
    else if(settingType == AlrimSettingTypeVibrate)
        keyStr = kBeaconVibrateYN;
    else if(settingType == AlrimSettingTypeRemoteNotification)
        keyStr = kRemoteNotificationYN;
    else if(settingType == AlrimSettingTypeRemoteNotificationSound)
        keyStr = kRemoteNotificationSouond;

    //푸시알림 설정값 변경시...
    if(settingType == AlrimSettingTypeRemoteNotification
       || settingType == AlrimSettingTypeRemoteNotificationSound)
    {
        //서버에 설정값 전송
        TheConnection *prevConnection = [currentSettingConnectionInfo objectForKey:keyStr];
        
        if(prevConnection != nil)
        {
            [prevConnection stopRequest];
        }
        
        NSString *url = nil;
        NSString *uuid = [UTILITY UUID];
        
        //푸시알림 on/off
        if(settingType == AlrimSettingTypeRemoteNotification)
        {
            url = [NSString stringWithFormat:@"%@uuid=%@&pValue=%@",kUrlRemoteNotificationYN, uuid, isOn];
        }
        //푸시알림 사운드 on/off
        else
        {
            url = [NSString stringWithFormat:@"%@uuid=%@&no=0&pValue=%@",kUrlRemoteNotificationSoundYN, uuid, isOn];
        }
        
        NSLog(@"AlrimSettingTypeRemoteNotification url : %@",url);
        
        TheConnection *connection = [[TheConnection alloc] init];
        [connection setInfo:@{@"value" : isOn, @"key" : keyStr}];
        [connection startConnectionWithUrl:url
                                  delegate:self
                                 queueName:nil];
        
        [currentSettingConnectionInfo setObject:connection forKey:keyStr];
    }
    else
    {
        //키체인에 저장하기.
        [UTILITY saveTextInKeyChainWithIdentifier:keyStr
                                         saveText:isOn];
    }
}

#pragma mark - button Event

- (IBAction)pressedBackBtn:(id)sender
{
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:0.f
                            completion:nil];
}

//비콘알림 and 푸시알림on/off 버튼
- (IBAction)pressedSwitchBtn:(id)sender
{
    UIButton *btn = sender;
    btn.selected = !btn.selected;
    
    AlrimSettingType settingType = btn.tag;
    
    //수신 on/off값을 저장한다..
    [self saveBeaconAlrimEnableValue:btn.selected
                         settingType:settingType];
}

//언어설정 버튼
- (IBAction)pressedSetLanguageBtn:(id)sender
{
    UIButton *btn = sender;
    
    NSLog(@"언어설정 btn.tag : %ld",btn.tag);
    LanguageSettingType languageType = btn.tag;
    
    if(currentLanguageSettingType == languageType)
        return;
    
    btn.selected = YES;
    
    NSString *saveLanguageStr = nil;
    
    if(languageType == LanguageSettingTypeKor)
    {
        [_setLanguageEngBtn setSelected:NO];
        saveLanguageStr = kSetLanguageKor;
    }
    else if(languageType == LanguageSettingTypeEng)
    {
        [_setLanguageKorBtn setSelected:NO];
        saveLanguageStr = kSetLanguageEng;
    }
    
    //설정값 저장하기...
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:saveLanguageStr forKey:kSaveLanguageState];
    [defaults synchronize];
    
    currentLanguageSettingType = languageType;
    
    //언어설정값 UI에 적용하기...
    [self setAllUITextWithLanguageType:languageType];
    
    if([self.delegate respondsToSelector:@selector(settingView:didChangeLanguage:)])
        [self.delegate settingView:self didChangeLanguage:languageType];
}

//가이드화면 보기
- (IBAction)pressedShowGuideView:(id)sender
{
    [UTILITY.rootViewControllerPtr guideViewSetHidden:NO];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    NSDictionary *connectionInfo = connection.info;
    NSString *keyStr = [connectionInfo objectForKey:@"key"];
    NSString *value = [connectionInfo objectForKey:@"value"];
    
    if(error == nil)
    {
        if([[result objectForKey:@"result"] isEqualToString:@"Y"])
        {
            NSLog(@"푸시알림 설정 서버전송결과 : %@",result);
            //키체인에 저장하기.
            [UTILITY saveTextInKeyChainWithIdentifier:keyStr
                                             saveText:value];
        }
    }
    
    [currentSettingConnectionInfo removeObjectForKey:keyStr];
}

@end
