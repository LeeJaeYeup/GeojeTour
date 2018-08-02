//
//  AppDelegate.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//
// Git

#import "AppDelegate.h"
#import "TheConnection.h"
@import GoogleMaps;
#import <UserNotifications/UserNotifications.h>
#import "SelectMenuViewController.h"
#import "StampTourViewController.h"
#import <OneSignal/OneSignal.h>


#define kGoogleMapsApiKey           @"AIzaSyBbLwspQtKA5WbvDWjVb0q36aTEf6KqA4s"
#define kOneSignalAppId             @"83b79202-1b19-4d67-a566-fb7c87442f32"
#define kUrlCheckAppStoreVersion    @"http://itunes.apple.com/kr/lookup?bundleId="

typedef NS_ENUM(NSUInteger, AppDelConnectionType)
{
    AppDelConnectionTypeSendUserInfo
};

@interface AppDelegate () <TheConnectionDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic, strong) UNNotificationContent *receivedNotiContents;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *uuid = [UTILITY UUID];
//    NSLog(@"기기 uuid : %@",uuid);
    
    [GMSServices provideAPIKey:kGoogleMapsApiKey];
    
    //APNS 등록
    [self initializeRemoteNotification];
    
    //스토어 버전 확인
    if([self needsUpdate])
    {
        NSLog(@"업데이트 필요함!!");
    }
    
//    [OneSignal initWithLaunchOptions:launchOptions
//                               appId:kOneSignalAppId
//            handleNotificationAction:nil
//                            settings:@{kOSSettingsKeyAutoPrompt: @false}];
//    OneSignal.inFocusDisplayType = OSNotificationDisplayTypeNotification;
//
//    // Recommend moving the below line to prompt for push after informing the user about
//    //   how your app will use them.
//    [OneSignal promptForPushNotificationsWithUserResponse:^(BOOL accepted) {
//        NSLog(@"User accepted notifications: %d", accepted);
//    }];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    if(self.receivedNotiContents != nil)
    {
        [self excuteNotificationContents:self.receivedNotiContents];
        self.receivedNotiContents = nil;
    }
}

#pragma mark - APNS

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenStr = [[[deviceToken description]
                              stringByReplacingOccurrencesOfString: @"<" withString: @""]
                             stringByReplacingOccurrencesOfString: @">" withString: @""];
    
    deviceTokenStr = [deviceTokenStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    
//    NSLog(@"deviceTokenStr : %@",deviceTokenStr);
    
    //사용자 정보 및 푸시토큰 서버에 전달
    [self sendDeviceInfoToServerWithToken:deviceTokenStr];
}

#pragma mark - private

//앱스토어에 있는 앱 버전과 로컬 앱 버전 비교해서 최신인지 알려주기
-(BOOL)needsUpdate
{
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* appID = infoDictionary[@"CFBundleIdentifier"];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kUrlCheckAppStoreVersion,appID]];
//    NSLog(@"앱 버전확인 url : %@",url);
    NSData* data = [NSData dataWithContentsOfURL:url];
    
    if(data != nil)
    {
        NSDictionary* lookup = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//        NSLog(@"lookup : %@",lookup);
        
        //결과값이 있으면....
        if ([lookup[@"resultCount"] integerValue] >= 1)
        {
            NSString* appStoreVersion = lookup[@"results"][0][@"version"];
            NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];
            
            appStoreVersion = [appStoreVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
            currentVersion = [currentVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
            
            //버전 자리수가 다르면 글자길이가 작은애한테 0을 붙여준다.
            if([appStoreVersion length] != [currentVersion length])
            {
                int gapLength = 0;
                
                if([appStoreVersion length] < [currentVersion length])
                {
                    gapLength = (int)([currentVersion length] - [appStoreVersion length]);
                    
                    for(int j = 0; j < gapLength; j++)
                    {
                        appStoreVersion = [appStoreVersion stringByAppendingString:@"0"];
                    }
                }
                else
                {
                    gapLength = (int)([appStoreVersion length] - [currentVersion length]);
                    
                    for(int j = 0; j < gapLength; j++)
                    {
                        currentVersion = [currentVersion stringByAppendingString:@"0"];
                    }
                }
            }
            
//            NSLog(@"appStoreVersion : %@",appStoreVersion);
//            NSLog(@"currentVersion : %@",currentVersion);
            
            int storeVersion = [appStoreVersion intValue];
            int localVersion = [currentVersion intValue];
            
            if(storeVersion > localVersion)
            {
//                NSLog(@"Need to update [%@ != %@]",appStoreVersion ,currentVersion);
                return YES;
            }
            
        }
    }
    
    return NO;
}

//푸시알림 받은거 처리하기..
-(void)excuteNotificationContents:(UNNotificationContent*)notiContents
{
    NSString *remotePushUrl = [notiContents.userInfo objectForKey:@"url"];

    //리모트 푸시 처리하기
    if(remotePushUrl != nil)
    {
        NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL,remotePushUrl];
//        NSLog(@"푸시받음 url : %@",url);
        
        UINavigationController *rootViewNavi = (UINavigationController*)self.window.rootViewController;
        ViewController *rootViewController = rootViewNavi.viewControllers.firstObject;
        [rootViewController showWebViewWithUrl:url];
    }
    
    //로컬푸시 처리하기
    else
    {
        NSString *bodyStr = notiContents.body;
        NSLog(@"로컬노티 bodyStr : %@",bodyStr);
        
        if([bodyStr containsString:@"쿠폰"])
        {
            UINavigationController *rootViewNavi = (UINavigationController*)self.window.rootViewController;

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
        else if([bodyStr containsString:@"스탬프"])
        {
            UINavigationController *rootViewNavi = (UINavigationController*)self.window.rootViewController;
            
            NSString *stampTourCateCd = [notiContents.userInfo objectForKey:@"cateCd1"];
            
            if(stampTourCateCd != nil)
            {
                //스탬프투어 화면으로 넘기기
                StampTourViewController *stampTourViewController = [[StampTourViewController alloc] initWithNibName:@"StampTourViewController" bundle:nil];
                stampTourViewController.detailPageCateCd = stampTourCateCd;
                
                [[rootViewNavi visibleViewController].navigationController pushViewController:stampTourViewController animated:YES];
            }
        }
        //일반 컨텐츠
        else
        {
            NSString *url = nil;
            NSString *basicSid = nil;
            NSString *beaconFullPathLink = [notiContents.userInfo objectForKey:@"beaconFullPathLink"];
            NSLog(@"beaconFullPathLink : %@",beaconFullPathLink);
            
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
            
            [UTILITY.rootViewControllerPtr showWebViewWithUrl:url];
        }
    }
}

- (void)initializeRemoteNotification
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionBadge | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error)
     {
         if(error == nil)
         {
             [[UIApplication sharedApplication] performSelectorOnMainThread:@selector(registerForRemoteNotifications) withObject:nil waitUntilDone:NO];
         }
         else
         {
             NSLog(@"**** 리모트 푸시 서비스등록 실패 ****");
         }
     }];
}

//서버에 푸시토큰, UUID등등 기기정보 전송
-(void)sendDeviceInfoToServerWithToken:(NSString*)token
{
    NSString *uuid = [UTILITY UUID];
    
    NSString *url =
    [NSString stringWithFormat:
     @"%@/user/smartbeacon/push/pushInit.geoje?uuid=%@&regId=%@&osType=I",BASE_URL,uuid,token];
    
    NSLog(@"sendDeviceInfoToServerWithToken url : %@",url);
    
    [self startConnectionWithURL:url
                             tag:AppDelConnectionTypeSendUserInfo
                      identifier:token];
}

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
    NSLog(@"url : %@",url);
}

#pragma mark - TheConnection delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    AppDelConnectionType connectionType = connection.tag;
    
    NSLog(@"connection result : %@",result);
    
    if(error == nil)
    {
        //서버에 사용자 정보 전송
        if(connectionType == AppDelConnectionTypeSendUserInfo)
        {
            //서버전송 실패...
            if([[result objectForKey:@"result"] isEqualToString:@"Y"] == NO)
            {
                NSLog(@"**** 사용자 정보 전송 실패 : %@",[result objectForKey:@"msg"]);
            }
            else
            {
                NSLog(@"**** 사용자 정보 전송 완료!!");
            }
            
            //토큰을 seed암호화
//            NSString *seedEncToken = [SHARED_UTILITY seedEncriptWithText:connection.identifierStr];
//
//            //로컬저장소에 토큰값 저장하기
//            [self writePlistFileForKey:kDeviceTokenKey
//                                 value:seedEncToken
//                              fileName:SETTING_INFO_PLIST_FILE_NAME];
        }
        
    }
    else
    {
        NSLog(@"TheConnection error : %@",error);
        
        //재시도 하기...
        [self performSelector:@selector(sendDeviceInfoToServerWithToken:) withObject:connection.identifier afterDelay:5.f];
    }
}

#pragma mark - UNUserNotificationCenter Delegate for >= iOS 10

// 앱이 실행되고 있을때 푸시 데이터 처리
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSLog(@"Remote or Local notification2 : %@",notification.request.content.userInfo);
    //푸시 배너를 띄워준다
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
}

// 앱이 백그라운나 종료되어 있는 상태에서 푸시 데이터 처리
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler
{
    NSLog(@"Remote or Local notification2 : %@",response.notification.request.content.userInfo);
    NSLog(@"body : %@",response.notification.request.content.body);
    
    if(UTILITY.rootViewControllerPtr != nil)
        [self excuteNotificationContents:response.notification.request.content];
    else
        self.receivedNotiContents = response.notification.request.content;
    
    completionHandler();
    
}

@end
