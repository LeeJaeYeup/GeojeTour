
//  ViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "ViewController.h"
#import "NearbyTourContentsDetect.h"
#import "MainWebView.h"
#import <UserNotifications/UserNotifications.h>
#import "TheConnection.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "StampTourViewController.h"
#import "SelectMenuViewController.h"
#import "GuideView.h"
#import "CommunityViewController.h"
#import "BeaconFindNotiView.h"
#import "SumAndSumGilViewController.h"



#define kUrlGetBeaconDataVersion        [NSString stringWithFormat:@"%@/cms/beacon/openapi_setting.sko",BASE_URL]
#define kRfcBeaconDataVersionKey        @"rfcBeaconDataVersion"
#define kBeaconQueueMaxNum              999

@interface UINavigationController (CompletionHandler)

- (void)completionhandler_pushViewController:(UIViewController *)viewController
                                    animated:(BOOL)animated
                                  completion:(void (^)(void))completion;

@end

@implementation UINavigationController (CompletionHandler)

- (void)completionhandler_pushViewController:(UIViewController *)viewController
                                    animated:(BOOL)animated
                                  completion:(void (^)(void))completion
{
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
    [CATransaction commit];
}

@end


@interface ViewController ()
<NearbyTourcontentsDetectDelegate, IntroViewDelegate, BeaconDataManagerDelegate, TheConnectionDelegate, UINavigationControllerDelegate, BeaconFindNotiViewDelegate, SettingViewDelegate>
{
    NearbyTourContentsDetect    *nearbyTourContentsDetecter;
    MainWebView                 *webView;
    SettingView                 *myPageView;
    
    GuideView                   *guideView;
    
    //비콘발견 알림 queueArr(앱이 foreground 상태일때)
    NSMutableArray              *beaconNotiQueueArray;
    
    //비콘발견 알림 queueArr(앱 bacground 상태일때)
    NSMutableArray              *backgroundBeaconNotiQueueArray;
    
    //한번에 하나의 노티뷰만 띄워주기 위해 현재 노티뷰를 보여주고있는 비콘정보를 저장한다
    NSMutableArray              *beaconNotiShowingQueueArray;
}

@property (weak, nonatomic) IBOutlet IntroView *introView;
@property (weak, nonatomic, readwrite) IBOutlet TopMenuView * _Nullable topMenuView;

//로딩뷰...
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingBgImgView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *loadingViewTextLabel;
@property (weak, nonatomic) IBOutlet UIImageView *appIcoImgView;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.navigationController.delegate = self;
    
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!granted) {
                //Show alert asking to go to settings and allow permission
//                [UTILITY makeAlertWithTitle:@"알림"
//                                    message:@"로컬알림 수신을 거부 하셨습니다.\n알림수신 거부 상태에서는 사용자 주변 비콘 발견시 알림을 받으실 수 없습니다.아이폰의 설정앱 -> 알림 -> 거제앱에 대한 알림여부를 허용으로 변경해 주십시오."
//                             viewController:self];
            }
        }];
    }
    application.applicationIconBadgeNumber = 0;
    
    //메인ViewController 포인터 저장해놓기
    [UTILITY setRootViewcontrollerPtr:self];
    beaconNotiQueueArray = [[NSMutableArray alloc] initWithCapacity:kBeaconQueueMaxNum];
    backgroundBeaconNotiQueueArray = [[NSMutableArray alloc] initWithCapacity:kBeaconQueueMaxNum];
    beaconNotiShowingQueueArray = [[NSMutableArray alloc] initWithCapacity:kBeaconQueueMaxNum];
    delegateArray = [NSPointerArray weakObjectsPointerArray];
    
    //로딩뷰 배경이미지 설정
    NSString *bgImgName = [NSString stringWithFormat:@"loading_bg_%ld",[UTILITY screenType]];
    _loadingBgImgView.image = [UIImage imageNamed:bgImgName];
    
    //비콘데이터 관리객체...
    _beaconDataManager = [[BeaconDataManager alloc] init];
    _beaconDataManager.delegate = self;
    
    //그외...
    _introView.delegate = self;
    
    //비콘 히스토리 db 값 초기화
    [self beaconDetectedHistoryInit];

    //rfc 비콘 데이터 버젼확인
    [self startConnectionWithURL:kUrlGetBeaconDataVersion
                             tag:0
                      identifier:nil];

    //로딩화면 보여주기..
    _progressView.hidden = _loadingViewTextLabel.hidden = _appIcoImgView.hidden = YES;
    [self showLoadingView:YES];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if(webView == nil)
    {
        webView = [[MainWebView alloc] initWithFrame:_introView.frame];
        webView.alpha = 0.f;
        
        //마이페이지 뷰
        myPageView = [[SettingView alloc] initWithFrame:_introView.frame];
        myPageView.delegate = self;
        [self.view addSubview:myPageView];
        myPageView.alpha = 0.f;
        
        //가이드 뷰
        guideView = [[GuideView alloc] initWithFrame:_introView.frame];
        [self.view addSubview:guideView];
        guideView.hidden = YES;
    }
}

#pragma mark - private

//비콘발견 노티뷰 닫기 눌렀을때 호출
-(void)updateClosedBeaconNotiHistoryShowingYNWithBeaconInfo:(NSDictionary*)info
{
    //beaconNotiShowingYN값 업데이트
    NSString *beaconFullPathLink = [info objectForKey:@"beaconFullPathLink"];
    NSString *groupSid = [info objectForKey:@"groupSid"];

    [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface] updateWithTableName:kTableNameDetectedBeaconHistory
                                                                                  values:@{@"detectDate" : [UTILITY currentDateWithDateFormat:nil], @"beaconNotiShowingYN" : @"N"}
                                                                                   where:[NSString stringWithFormat:@"where beaconFullPathLink = '%@' and groupSid = '%@'",beaconFullPathLink, groupSid]];
}

//비콘 히스토리 beaconNotiShowingYN값 초기화
-(void)beaconDetectedHistoryInit
{
    NSArray *historyArray = [[_beaconDataManager dbInterface] selectAllWithTableName:kTableNameDetectedBeaconHistory
                                                                               where:nil];
    
    for(int i = 0; i < historyArray.count; i ++)
    {
        [[_beaconDataManager dbInterface] updateWithTableName:kTableNameDetectedBeaconHistory
                                                       values:@{@"beaconNotiShowingYN" : @"N"}
                                                        where:nil];
    }
}

//beaconFullPathLink 에서 비콘 컨텐츠 url 생성하기...
-(NSString*)beaconContentsUrlWithFullPathLink:(NSString*)beaconFullPathLink
{
    //웹뷰에 테울 url 구성하기...
    NSString *url = nil;
    NSString *basicSid = nil;
    
    NSRange range = [beaconFullPathLink rangeOfString:@"?basicSid="];
    
    if(range.location != NSNotFound)
    {
        basicSid = [beaconFullPathLink stringByReplacingCharactersInRange:NSMakeRange(0, range.location + 1) withString:@""];

        url = [NSString stringWithFormat:@"%@/user/smarttour/view.geoje?menuCd=DOM_000008511001000000&%@",BASE_URL,basicSid];
    }
    else
    {
        url = beaconFullPathLink;
    }
    
    return url;
}

//비콘알림 큐에 저장된 비콘정보중 하나를 삭제한다.
-(void)removeBeaconNotiInfoInQueue:(NSDictionary*)beaconInfo
{
    for(int i = 0; i < beaconNotiQueueArray.count; i++)
    {
        NSString *queueFullPathLink = [[[beaconNotiQueueArray objectAtIndex:i] objectForKey:@"beaconInfo"] objectForKey:@"beaconFullPathLink"];
        NSString *queueGroupSid = [[[beaconNotiQueueArray objectAtIndex:i] objectForKey:@"beaconInfo"] objectForKey:@"groupSid"];
        NSString *removeBeaconFullPathLink = [beaconInfo objectForKey:@"beaconFullPathLink"];
        NSString *removeBeaconGroupSid = [beaconInfo objectForKey:@"groupSid"];
        
        if([queueFullPathLink isEqualToString:removeBeaconFullPathLink] &&
           [queueGroupSid isEqualToString:removeBeaconGroupSid])
        {
            [beaconNotiQueueArray removeObjectAtIndex:i];
            break;
        }
    }
}

//비콘발견 노티뷰 화면에 보여주기...
-(void)setVisibleBeaconNotiViewWithInfo:(NSDictionary*)info
{
    //비콘발견 알림뷰 띄우기
    UIViewController *currentStackTopViewController = [self.navigationController visibleViewController];
    BeaconFindNotiView *beaconFindNotiView = [[BeaconFindNotiView alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height - 70, self.view.frame.size.width - 20, 60)];
    beaconFindNotiView.delegate = self;
    [beaconFindNotiView setVisibleWithInfo:info onView:currentStackTopViewController.view];

    if([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
    {
        BOOL soundYN = [[UTILITY settingView] beaconAlrimEnableValueWithSettingType:AlrimSettingTypeSound];
        BOOL vibrateYN = [[UTILITY settingView] beaconAlrimEnableValueWithSettingType:AlrimSettingTypeVibrate];
        
        if(soundYN)
        {
            NSError* error;
            [[AVAudioSession sharedInstance]
             setCategory:AVAudioSessionCategoryPlayAndRecord
             error:&error];
            if (error == nil)
            {
                SystemSoundID myAlertSound;
                NSURL *url = [NSURL URLWithString:@"/System/Library/Audio/UISounds/sms-received1.caf"];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &myAlertSound);
                AudioServicesPlaySystemSound(myAlertSound);
            }
        }
        if(vibrateYN)   AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        [self performSelector:@selector(removeBeaconNotiShowingInfo) withObject:nil afterDelay:2.f];
    }
}

//보여지고 있는 알림뷰 큐 배열에서 하나를 삭제하고 남은 비콘알림을 보여준다.
-(void)removeBeaconNotiShowingInfo
{
    if(beaconNotiShowingQueueArray.count > 0)
    {
        [beaconNotiShowingQueueArray removeObjectAtIndex:0];
        
        if(beaconNotiShowingQueueArray.count > 0)
        {
            [self setVisibleBeaconNotiViewWithInfo:[beaconNotiShowingQueueArray firstObject]];
        }
    }
}

//비콘발견 알림큐에 알림 추가
-(void)addBeaconNotiWithInfo:(NSDictionary*)info isContentsBeacon:(BOOL)isContentsBeacon
{
    NSString *isContentsBeaconYN = @"Y";
    
    if(isContentsBeacon == NO)  isContentsBeaconYN = @"N";
    
    NSDictionary *detectedBeaconInfo = @{@"beaconInfo" : info, @"isContentsBeaconYN" : isContentsBeaconYN};
    
    //추가하기...
    [beaconNotiQueueArray addObject:detectedBeaconInfo];    //컨텐츠 중복방지를 위해 저장
    [beaconNotiShowingQueueArray addObject:detectedBeaconInfo]; //한번에 하나의 비콘알림뷰만 띄우기 위해 저장
    
    //노티알림 보여주는게 없으면...
    if(beaconNotiShowingQueueArray.count == 1)
        [self setVisibleBeaconNotiViewWithInfo:detectedBeaconInfo];
}

-(void)createBeaconDetectManager
{
    if(nearbyTourContentsDetecter == nil)
    {
        //비콘 검색 객체..
        nearbyTourContentsDetecter = [[NearbyTourContentsDetect alloc] init];
        nearbyTourContentsDetecter.delegate = self;
    }
}

-(void)startLoadingViewAppIconFlipAnimation
{
    static int xTransform = -1;
    
    [UIView animateWithDuration:1.5f delay:0.0f options:UIViewAnimationOptionTransitionFlipFromRight
                     animations:^(void)
     {
         self->_appIcoImgView.transform = CGAffineTransformMakeScale(xTransform, 1);
     }
                     completion:^(BOOL finished)
     {
         //로딩뷰 히든될때까지 무한반복..
         if(self->_loadingView.hidden == NO)
         {
             xTransform = -xTransform;
             [self startLoadingViewAppIconFlipAnimation];
         }
     }];
}

//rfc 비콘버전 앱 내부에 저장하기
-(void)saveBeaconDataVersion:(NSString*)verStr
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setValue:verStr forKey:kRfcBeaconDataVersionKey];
    [userDefault synchronize];
}

//저장된 rfc 비콘 버젼 가져오기
-(NSString*)getBeaconDataVersion
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    return [userDefault objectForKey:kRfcBeaconDataVersionKey];
}

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

//로컬알림 등록하기...
-(void)showLocalNotiWithTitle:(NSString *)title beaconData:(NSDictionary*)beaconData
{
    static int localNotiNum = 0;
    
    UNMutableNotificationContent *localNotification = [UNMutableNotificationContent new];
    localNotification.body = [NSString localizedUserNotificationStringForKey:title arguments:nil];
    localNotification.userInfo = beaconData;
    
    UNNotificationSound *notiSound = [UNNotificationSound defaultSound];
    
    BOOL soundEnable = [[UTILITY settingView] beaconAlrimEnableValueWithSettingType:AlrimSettingTypeSound];
    
    //사운드 꺼짐 상태면 무음 사운드파일 재생...
    if(soundEnable == NO)
        notiSound = [UNNotificationSound soundNamed:@"mute.mp3"];
    
    localNotification.sound = notiSound;
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.5f repeats:NO];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"beacon local Notification %d",localNotiNum++] content:localNotification trigger:trigger];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"Notification created error : %@",error);
    }];
    
    if(localNotiNum > kBeaconQueueMaxNum)
        localNotiNum = 0;
    
    [backgroundBeaconNotiQueueArray addObject:beaconData];
}

#pragma mark - public

-(void)guideViewSetHidden:(BOOL)hidden
{
    if(hidden == NO)
    {
        [guideView setPage:1 animation:NO];
    }
    
    guideView.hidden = hidden;
}

//비콘알림 대기열에 추가할려는 비콘과 같은 컨텐츠URL과 같은 그룹sid를 가진비콘이 있는지 확인한다.
-(BOOL)isExistBeaconAlrimQueueWithAddBeacon:(NSDictionary*)beaconInfo
{
    BOOL exist = NO;
    
    //같은 컨텐츠 url을 가진 알림이 있으면 추가하지 않는다.
    for(NSDictionary *beaconDic in beaconNotiQueueArray)
    {
        NSString *fullpathLink01 = [[beaconDic objectForKey:@"beaconInfo"] objectForKey:@"beaconFullPathLink"];
        NSString *fullpathLink02 = [beaconInfo objectForKey:@"beaconFullPathLink"];
        
        NSString *groupSid01 = [[beaconDic objectForKey:@"beaconInfo"] objectForKey:@"groupSid"];
        NSString *groupSid02 = [beaconInfo objectForKey:@"groupSid"];
        
        if([fullpathLink01 isEqualToString:fullpathLink02] &&
           [groupSid01 isEqualToString:groupSid02])
        {
            exist = YES;
            break;
        }
    }
    
    return exist;
}

-(TopMenuView * _Nonnull)topMenuView
{
    return _topMenuView;
}

-(void)addDelegate:(_Nonnull id <ViewControllerDelegate>)delegate
{
    [delegateArray addPointer:(__bridge void * _Nonnull)(delegate)];
}

//비콘발견 노티뷰 띄우기
-(void)showBeaconNotiViewWithBeaconInfo:(NSDictionary*_Nullable)beaconInfo contentsBeacon:(BOOL)isContentsBeacon
{
    //마이페이지 비콘 수신여부가 off면 return 시키기...
    if([[UTILITY settingView] beaconAlrimEnableValueWithSettingType:AlrimSettingTypeBeaconContents] == NO)        return;
    
    //대기열에 똑같은 알림이 이미 존재하는지 확인한다
    NSString *currentBeaconFullPathLink = [beaconInfo objectForKey:@"beaconFullPathLink"];
    NSString *currentBeaconGroupSid = [beaconInfo objectForKey:@"groupSid"];
    if(currentBeaconFullPathLink == nil)
    {
        currentBeaconFullPathLink = [[beaconInfo objectForKey:@"data"] objectForKey:@"beaconFullPathLink"];
        currentBeaconGroupSid = [[beaconInfo objectForKey:@"data"] objectForKey:@"groupSid"];
    }
    
    BOOL bNeedAddBeaconInfo = YES;
    
    UIApplicationState currentAppState = [[UIApplication sharedApplication] applicationState];
    NSLog(@"currentAppState : %ld",currentAppState);
    
    //앱이 포어그라운드 상태일때.
    if(currentAppState == UIApplicationStateActive)
    {
        for(int i = 0; i < beaconNotiQueueArray.count; i ++)
        {
            NSString *queueBeaconFullPathLink = [[[beaconNotiQueueArray objectAtIndex:i] objectForKey:@"beaconInfo"] objectForKey:@"beaconFullPathLink"];
            NSString *queueGroupSid = [[[beaconNotiQueueArray objectAtIndex:i] objectForKey:@"beaconInfo"] objectForKey:@"groupSid"];
            NSLog(@"=====================================================");
            NSLog(@"currentBeaconFullPathLink : %@",currentBeaconFullPathLink);
            NSLog(@"queueBeaconFullPathLink : %@",queueBeaconFullPathLink);
            NSLog(@"=====================================================");
            
            if([currentBeaconFullPathLink isEqualToString:queueBeaconFullPathLink] &&
               [currentBeaconGroupSid isEqualToString:queueGroupSid])
            {
                NSLog(@"이미 똑같은 컨텐츠 url이 존재함 - 1!!");
                bNeedAddBeaconInfo = NO;
                break;
            }
        }
        
        if(bNeedAddBeaconInfo == YES)
        {
//            //추가하기전에 대기열이 200개 이상이면 하나 삭제한다...
//            if(beaconNotiQueueArray.count >= kBeaconQueueMaxNum)
//                [beaconNotiQueueArray removeObjectAtIndex:1];
            
            //비콘알림 큐에 등록하기...
            [self addBeaconNotiWithInfo:beaconInfo isContentsBeacon:isContentsBeacon];
        }
    }
    //앱이 백그라운드 상태일때
    else if(currentAppState == UIApplicationStateBackground)
    {
        for(int i = 0; i < backgroundBeaconNotiQueueArray.count; i ++)
        {
            NSString *queueBeaconFullPathLink = [[backgroundBeaconNotiQueueArray objectAtIndex:i] objectForKey:@"beaconFullPathLink"];
            NSString *queueGroupSid = [[backgroundBeaconNotiQueueArray objectAtIndex:i] objectForKey:@"groupSid"];
            NSLog(@"currentBeaconFullPathLink : %@",currentBeaconFullPathLink);
            NSLog(@"queueBeaconFullPathLink : %@",queueBeaconFullPathLink);

            if([currentBeaconFullPathLink isEqualToString:queueBeaconFullPathLink] &&
               [currentBeaconGroupSid isEqualToString:queueGroupSid])
            {
                NSLog(@"이미 똑같은 컨텐츠 url이 존재함 - 2!!");
                bNeedAddBeaconInfo = NO;
                break;
            }
        }
        
        if(bNeedAddBeaconInfo == YES)
        {
//            //추가하기전에 대기열이 200개 이상이면 하나 삭제한다...
//            if(backgroundBeaconNotiQueueArray.count >= kBeaconQueueMaxNum)
//                [backgroundBeaconNotiQueueArray removeObjectAtIndex:1];
            
            //로컬알림 등록하기
            NSString *notiTitleStr = nil;
            NSDictionary *beaconData = nil;
            
            //쿠폰 또는 스탬프 일때...
            if(isContentsBeacon == NO)
            {
                notiTitleStr = [beaconInfo objectForKey:@"msg"];
                beaconData = [beaconInfo objectForKey:@"data"];
            }
            else
            {
                notiTitleStr = [NSString stringWithFormat:@"%@(이)가 발견 되었습니다.",[beaconInfo objectForKey:@"beaconTitle"]];
                beaconData = beaconInfo;
            }
            
            NSLog(@"====================================");
            NSLog(@"로컬알림 title : %@",[beaconInfo objectForKey:@"beaconTitle"]);
            NSLog(@"로컬알림 mac : %@",[beaconInfo objectForKey:@"beaconMac"]);
            NSLog(@"로컬알림 fullPathLink : %@",[beaconInfo objectForKey:@"beaconFullPathLink"]);
            [self showLocalNotiWithTitle:notiTitleStr beaconData:beaconData];
        }
    }
}

//웹뷰 보여주기....
-(void)showWebViewWithUrl:(NSString*)url
{
    if(url == nil || [url length] <= 1)
    {
        NSLog(@"잘못된 url 형식....");
        return;
    }
    
    [webView setHomeUrlStr:url];
    [webView loadRequestWithUrl:url];
    [[self.navigationController viewControllers].lastObject.view addSubview:webView];
    
    [webView setHidden:NO completion:nil];
}

-(void)showLoadingView:(BOOL)show
{
    NSLog(@"_loadingView : %@",_loadingView);
    
    _loadingView.hidden = !show;
    
    if(show)
    {
        [self startLoadingViewAppIconFlipAnimation];
    }
}

#pragma mark - IntroView Delegate

//인트로화면 동그라미 버튼들 선택시 호출됨...
-(void)introView:(IntroView*)introView didSelectMainMenuIndex:(NSInteger)index
{
    if(index >= 0 && index < 4)
    {
        NSLog(@"메인화면 메뉴버튼 선택됨 : %ld",index);
        
        if(index == 2)
        {
            StampTourViewController *stampTourViewController = [[StampTourViewController alloc] initWithNibName:@"StampTourViewController" bundle:nil];
            [self.navigationController pushViewController:stampTourViewController animated:YES];
        }
        else
        {
            SelectMenuType menuType = -999;
            
            if(index == 0)
                menuType = SelectMenuTypeSmartTour;
            else if(index == 1)
                menuType = SelectMenuType360VR;
            else
                menuType = SelectMenuTypeCoupon;
            
            NSInteger currentDateNumber = [[UTILITY currentDateWithDateFormat:@"yyyyMMdd"] integerValue];
            
            //할인쿠폰뷰 예외처리..
            if(menuType == SelectMenuTypeCoupon)
            {
                if(currentDateNumber >= 20180601 && currentDateNumber <= 20180831)
                {
                    [UTILITY makeAlertWithTitle:@"알림"
                                        message:@"기존 할인쿠폰 서비스가 2018.5.31.로 종료되었습니다.새로운 할인쿠폰 서비스는 2018. 9.1.부터 시작됩니다.더 나은 서비스로 찾아뵙도록 하겠습니다.감사합니다."
                                 viewController:UTILITY.rootViewControllerPtr];
                    return;
                }
                
                NSLog(@"currentDateNumber : %ld",currentDateNumber);
            }
            
            SelectMenuViewController *selectMenuViewController = [[SelectMenuViewController alloc] initWithNibName:@"SelectMenuViewController" bundle:nil];
            selectMenuViewController.menuType = menuType;
//            [self.navigationController pushViewController:selectMenuViewController animated:YES];
            [self.navigationController completionhandler_pushViewController:selectMenuViewController
                                                                   animated:YES
                                                                 completion:^()
             {
                 
                 if(currentDateNumber >= 20180520 && currentDateNumber <= 20180531)
                 {
                     [UTILITY makeAlertWithTitle:@"알림"
                                         message:@"기존 할인쿠폰 서비스는 2018.5.31.로 종료 되고,새로운 할인쿠폰 서비스가 2018.9.1.부터 시작 됩니다.발급 받은 쿠폰은 서비스 종료 전에 사용하시기 바랍니다."
                                  viewController:UTILITY.rootViewControllerPtr];
                 }
             }];
        }
    }
    else
    {
        //섬앤섬길
        if(index == 6)
        {
            SumAndSumGilViewController *sumsumViewController = [[SumAndSumGilViewController alloc] initWithNibName:@"SumAndSumGilViewController" bundle:nil];
            [self.navigationController pushViewController:sumsumViewController animated:YES];
        }
        //거제여행, 커뮤니티, 교통정보센터
        else
        {
            //거제여행, 커뮤니티, 교통정보센터 주소
            NSArray *linkArr = @[[NSString stringWithFormat:@"%@/index.geoje",BASE_URL],
                                 [NSString stringWithFormat:@"%@/board/list.geoje?boardId=BBS_0000008&menuCd=DOM_000008513001000000&contentsSid=8445&cpath=",BASE_URL_SSL],
                                 @"",
                                 @"http://its.geoje.go.kr/m/M_Main.do"];
            
            NSString *url = linkArr[index - 4];
            
            //커뮤니티
            if(index == 5)
            {
                CommunityViewController *commViewController = [[CommunityViewController alloc]
                                                               initWithNibName:@"CommunityViewController"
                                                               bundle:nil];
                commViewController.webViewUrl = url;
                [self.navigationController pushViewController:commViewController animated:YES];
            }
            //나머지 두군데
            else
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
                                                   options:@{}
                                         completionHandler:nil];

            }
        }

    }
}

#pragma mark - BeaconDataManager Delegate

//sql db에 데이터 인서트 진행사항 콜백
-(void)beaconDataManager:(BeaconDataManager*)bdm didProgressInsertInDbWithIndex:(int)index totalCount:(int)total
{
    float percent = (float)((float)index / (float)total);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_progressView setProgress:percent animated:YES];
    });
}

//모든 비콘데이터 다운로드 후 db 인서트 완료시...
-(void)didFinishGetAllBeaconData:(BeaconDataManager*)bdm beaconVersion:(NSString *)version
{
    NSString *beaconDataVersion = [self getBeaconDataVersion];
    
    if(beaconDataVersion == nil)
    {
        guideView.hidden = NO;
    }
    
    //비콘 검색 객체..
    [self createBeaconDetectManager];

    //다운받은 비콘 버젼저장
    [self saveBeaconDataVersion:version];
    
    
    [self showLoadingView:NO];
}

#pragma mark - button Event

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
        //비콘 데이터 버젼확인.
        if(connection.tag == 0)
        {
            NSLog(@"비콘 데이터 버젼 result : %@",result);
            NSString *beaconVersion = [[[result objectForKey:@"RFCSettingData"] firstObject] objectForKey:@"beaconVersion"];
            NSLog(@"beaconVersion : %@",beaconVersion);
            
            NSString *currentBeaconDataVersion = [self getBeaconDataVersion];
            
            //앱 실행이 최초가 아닐때...
            if(currentBeaconDataVersion != nil)
                _loadingViewTextLabel.text = @"앱 실행에 필요한 데이터를 업데이트 중입니다.";
            
            if([beaconVersion isEqualToString:currentBeaconDataVersion] == NO)
            {
                NSLog(@"저장된 버전과 다름!!");
                _progressView.hidden = _loadingViewTextLabel.hidden = _appIcoImgView.hidden = NO;
                [_beaconDataManager getAllBeaconDataWithVersion:beaconVersion];
            }
            else
            {
                NSLog(@"비콘 버젼이 최신임!!!");
                [self showLoadingView:NO];
                [self createBeaconDetectManager];
            }
        }
    }
}

#pragma mark - UINavigationViewController delegate

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    UIInterfaceOrientationMask orientationMask = UIInterfaceOrientationMaskPortrait;
    
    if(_useLandSscapeOrientation == YES)
        orientationMask = UIInterfaceOrientationMaskLandscape;
    
    return orientationMask;
}

#pragma mark - NSNotification

- (void)appDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"did become active notification");
    [backgroundBeaconNotiQueueArray removeAllObjects];
}

#pragma mark - BeaconFindNotiView Delegate

//비콘 노티뷰 숨김 완료시 호출됨.
-(void)beaconFindNotiView:(BeaconFindNotiView*)bfnv didFinishInvisibleWithInfo:(NSDictionary*)info
{
    //선택된 비콘알림 정보를 큐에서 삭제하기
    [self removeBeaconNotiInfoInQueue:info];
    
    [bfnv removeFromSuperview];
    bfnv = nil;
    
    //beaconNotiShowingYN값 업데이트
    [self updateClosedBeaconNotiHistoryShowingYNWithBeaconInfo:info];
}

//비콘 노티뷰 닫기버튼 선택시 호출됨.
-(void)didSelectCloseBtnWithBeaconFindNotiView:(BeaconFindNotiView *)bfnv
{
    [bfnv setInvisible];
}

//비콘 노티뷰 몸통 선택시 호출됨.
-(void)didSelectNotiViewBodyWithBeaconFindNotiView:(BeaconFindNotiView *)bfnv
{
    NSLog(@"노티뷰 선택함!!!!!");
    NSDictionary *currentNotiViewBeaconInfo = [bfnv currentShowingNotiInfo];
    
    //beaconNotiShowingYN값 업데이트
    [self updateClosedBeaconNotiHistoryShowingYNWithBeaconInfo:currentNotiViewBeaconInfo];
    
    //웹뷰에 테울 url 구성하기...
    if(currentNotiViewBeaconInfo != nil)
    {
        NSString *notiTitleStr = [bfnv currentShowTitle];
        NSLog(@"notiTitleStr : %@",notiTitleStr);
        
        if([notiTitleStr containsString:@"쿠폰"])
        {
            UINavigationController *rootViewNavi = (UINavigationController*)UTILITY.rootViewControllerPtr.navigationController;
            
            UIViewController *visibleViewController = [rootViewNavi visibleViewController];
            
            if([visibleViewController isKindOfClass:[SelectMenuViewController class]])
            {
                SelectMenuViewController *menuViewController = (SelectMenuViewController*)visibleViewController;
                
                if(menuViewController.menuType == SelectMenuTypeCoupon)
                    return;
            }
            
            //할인쿠폰 화면으로 넘기기
            SelectMenuViewController *selectMenuViewController = [[SelectMenuViewController alloc] initWithNibName:@"SelectMenuViewController" bundle:nil];
            selectMenuViewController.menuType = SelectMenuTypeCoupon;
            [visibleViewController.navigationController pushViewController:selectMenuViewController animated:YES];
        }
        else if([notiTitleStr containsString:@"스탬프"])
        {
            UINavigationController *rootViewNavi = (UINavigationController*)UTILITY.rootViewControllerPtr.navigationController;
            
            NSString *stampTourCateCd = [currentNotiViewBeaconInfo objectForKey:@"cateCd1"];
            
            if(stampTourCateCd != nil)
            {
                //스탬프투어 화면으로 넘기기
                StampTourViewController *stampTourViewController = [[StampTourViewController alloc] initWithNibName:@"StampTourViewController" bundle:nil];
                stampTourViewController.detailPageCateCd = stampTourCateCd;
                
                [[rootViewNavi visibleViewController].navigationController pushViewController:stampTourViewController animated:YES];
            }
            else
            {
                NSLog(@"*** stampTourCateCd값이 없음!!!!");
            }
        }
        //일반 컨텐츠
        else
        {
            NSString *url = nil;
            NSString *beaconFullPathLink = [currentNotiViewBeaconInfo objectForKey:@"beaconFullPathLink"];
            
            if(beaconFullPathLink == nil)
                beaconFullPathLink = [[currentNotiViewBeaconInfo objectForKey:@"data"] objectForKey:@"beaconFullPathLink"];
            
            url = [self beaconContentsUrlWithFullPathLink:beaconFullPathLink];
            
            //컨텐츠 웹뷰를 보여준다.
            [self showWebViewWithUrl:url];
        }
        
        //알림창 없애기
        [bfnv setInvisible];

        //델리게이트 콜백함수 호출 해주기...
        for(id <ViewControllerDelegate> delegate in delegateArray)
        {
            if([delegate respondsToSelector:@selector(viewController:didSelectNotiViewWithInfo:)])
                [delegate viewController:self didSelectNotiViewWithInfo:currentNotiViewBeaconInfo];
        }
    }
}

#pragma mark - SettingView Delegate

-(void)settingView:(SettingView*)settingView didChangeLanguage:(LanguageSettingType)languageType
{
    [_introView setAllUIText];
}

@end
