//
//  NearbyTourContentsDetect.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "NearbyTourContentsDetect.h"
#import "StampTourViewController.h"
#import "StampTourDetailViewController.h"
#import "SelectMenuViewController.h"


#define kBeaconResearchTimeForDEBUG_MODE        10     //디버그 모드에서 비콘 재검색 시간(sec)

typedef NS_ENUM(NSInteger, beaconContentsType)
{
    beaconContentsTypeUnknown,
    beaconContentsTypeCoupon,
    beaconContentsTypeStamp,
    beaconContentsTypeTourContents
};

typedef NS_ENUM(NSInteger, nearbyTourContentsConnectionType)
{
    nearbyTourContentsConnectionTypeUnknown,
    nearbyTourContentsConnectionTypeCouponRegist,
    nearbyTourContentsConnectionTypeStampRegist,
    nearbyTourContentsConnectionTypeGetBeaconData
};

#define kUrlGetBeaconData       [NSString stringWithFormat:@"%@/cms/beacon/openapi_beacon.sko?",BASE_URL]
#define kUrlCouponRegist        [NSString stringWithFormat:@"%@/user/smartbeacon/push/couponInit.geoje?",BASE_URL]
#define kUrlStampRegist         [NSString stringWithFormat:@"%@/user/smartbeacon/push/stampInit.geoje?",BASE_URL]


@interface NearbyTourContentsDetect ()
@end

@implementation NearbyTourContentsDetect

-(instancetype)init
{
    if(self = [super init])
    {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager requestAlwaysAuthorization];
        
        [UTILITY setLocationManagerPtr:locationManager];
        
        NSString *alertStr = nil;
        
        //모니터링 기능 사용가능 여부 확인...
        if([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
        {
            //지오펜스용 객체...
            geofenceManager = [[GeofenceManager alloc] initWithLocationManager:locationManager];
            geofenceManager.delegate = self;

            //비콘용 객체..
            if([CLLocationManager isRangingAvailable])
            {
                beaconManager = [[BeaconManager alloc] initWithLocationManager:locationManager];
                beaconManager.delegate = self;
            }
            else
            {
                NSLog(@"********** 비콘 레인징 사용 불가능 기기!! **********");
                alertStr = @"사용자의 기기는 비콘 감지기능을 지원하지 않습니다.\n주변 관광컨텐츠 알림을 받을 수 없습니다.";
            }
        }
        else
        {
            NSLog(@"********** region 모니터링 기능 지원 안하는 기기!! **********");
            alertStr = @"사용자의 기기는 지역 모니터링 기능을 지원하지 않습니다.\n주변 관광컨텐츠 알림을 받을 수 없습니다.";
        }
        
        if(alertStr != nil)
            [UTILITY makeAlertWithTitle:@"알림"
                                message:alertStr
                         viewController:UTILITY.rootViewControllerPtr];
    }
    
    return self;
}

#pragma mark - private

-(NSArray*)detectedBeaconHistoryArrWithContentsUrl:(NSString*)url groupSid:(NSString*)groupSid
{
    NSString *selectWhereQuery = [NSString stringWithFormat:@"where beaconFullPathLink = '%@' and groupSid = '%@'",url, groupSid];
    
//    NSLog(@"비콘 히스토리 selectWhereQuery : %@",selectWhereQuery);
    
    return [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
            selectAllWithTableName:kTableNameDetectedBeaconHistory
            where:selectWhereQuery];
}

//비콘이 검색됐을 경우 호출함(물리 가상 둘다)
-(void)detectedBeaconWithInfo:(NSDictionary*)info beacon:(CLBeacon *)beacon
{
    dispatch_async(UTILITY.beaconProcessQueue, ^{
       
        BOOL bNeedBeaconDetectAlrim = YES;
        NSString *beaconFullPathLink = [info objectForKey:@"beaconFullPathLink"];
        NSString *groupSid = [info objectForKey:@"groupSid"];
        
        //발견된 비콘이 쿠폰인지 확인
        beaconContentsType beaconType = [self beaconTypeWithBeaconInfo:info];

        //컨텐츠 url이 없으면 리턴
        if(beaconFullPathLink == nil || [beaconFullPathLink length] == 0)       return;
        else if(beaconType == beaconContentsTypeCoupon)
        {
            ///<2018.6.1. ~ 2018.8.31.> 사이에는 쿠폰비콘이 발견되도 무시하기...
            NSInteger currentDateNumber = [[UTILITY currentDateWithDateFormat:@"yyyyMMdd"] integerValue];
            currentDateNumber = 20180601;
            
            if(currentDateNumber >= 20180601 && currentDateNumber <= 20180831)
                return;
        }
        
        NSLog(@"-------------------------------------------------------------");
        NSLog(@"CLBeacon객체 : %@",beacon);
        NSLog(@"발견된 비콘 타이틀 : %@",[info objectForKey:@"beaconTitle"]);
        
        NSLog(@"발견된 비콘 beaconFullPathLink : %@",beaconFullPathLink);
        NSLog(@"발견된 비콘 groupSid : %@",groupSid);
        
        ViewController *rootViewController = UTILITY.rootViewControllerPtr;
        BOOL isAlreadyShowingContents = [rootViewController isExistBeaconAlrimQueueWithAddBeacon:info];
        
        if(isAlreadyShowingContents == YES)
        {
            NSLog(@"이미 %@ 컨텐츠에 대한 알림을 보여주고 있으므로 리턴함!!",beaconFullPathLink);
            return;
        }
        
        //검색된 비콘 히스토리에 있는지 확인하기
        NSArray *detectedBeaconHistorySelectArr =
        [self detectedBeaconHistoryArrWithContentsUrl:beaconFullPathLink
                                             groupSid:groupSid];
        
        NSLog(@"detectedBeaconHistorySelectArr : %@",detectedBeaconHistorySelectArr);
        NSLog(@"beaconNotiShowingYN : %@",[[detectedBeaconHistorySelectArr lastObject] objectForKey:@"beaconNotiShowingYN"]);
        
        //이전에 검색된 이력이 있는 비콘이면...
        if(detectedBeaconHistorySelectArr.count > 0)
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale    = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            formatter.timeZone  = [NSTimeZone timeZoneForSecondsFromGMT:60*60*9];
            NSString *currentDateStr = [UTILITY currentDateWithDateFormat:nil];
            
            //스탬프 또는 쿠폰인지 확인..
            if([[[detectedBeaconHistorySelectArr lastObject] objectForKey:@"stampOrCouponYN"] isEqualToString:@"Y"])
            {
                //사용된 쿠폰인지 확인해서 쿠폰이 사용된 시간이 24시간이 넘었으면 다시 등록될 수 있도록 한다.
                NSDictionary *beaconHistoryInfoDic = [detectedBeaconHistorySelectArr lastObject];
                
                if([[beaconHistoryInfoDic objectForKey:@"couponUseYN"] isEqualToString:@"Y"])
                {
//                    NSString *couponUseDate = [beaconHistoryInfoDic objectForKey:@"couponUseDate"];
                    NSDate *couponUseDate = [formatter dateFromString:[beaconHistoryInfoDic objectForKey:@"couponUseDate"]];
                    NSDate *currentDate = [formatter dateFromString:currentDateStr];
                    CGFloat timeDiff = [currentDate timeIntervalSinceDate:couponUseDate];
                    
                    NSLog(@"쿠폰이 사용되고 지난 시간(sec) : %lf",timeDiff);
                    
                    //쿠폰 사용한지 24시간이 지났으면...
                    if(timeDiff >= 86400)
                    {
                        //db에서 히스토리 삭제하기.
                        [[[rootViewController beaconDataManager] dbInterface] deleteRowWithTableName:kTableNameDetectedBeaconHistory where:[NSString stringWithFormat:@"where beaconFullPathLink = '%@' and groupSid = '%@'",[beaconHistoryInfoDic objectForKey:@"beaconFullPathLink"],[beaconHistoryInfoDic objectForKey:@"groupSid"]]];
                    }
                    else
                    {
                        NSLog(@"쿠폰이 사용된지 아직 24시간이 안지나서 리턴함");
                        return;
                    }
                }
                else
                {
                    NSLog(@"이미 사용자가 가지고 있는 쿠폰 또는 스탬프 이므로 리턴");
                    
                    //발견된 비콘이 쿠폰일때....
                    if(beaconType == beaconContentsTypeCoupon)
                    {
                        //발견한지 10일이 지난 쿠폰이면 히스토리에서 삭제한다.
                        NSDate *detectDate = [formatter dateFromString:[beaconHistoryInfoDic objectForKey:@"detectDate"]];
                        NSDate *currentDate = [formatter dateFromString:currentDateStr];
                        NSTimeInterval timeDiff = [currentDate timeIntervalSinceDate:detectDate];
                        
                        //발견한지 10일이상이 경과했으면...
                        if(timeDiff >= 864000)
                        {
                            //db에서 히스토리 삭제하기.
                            [[[rootViewController beaconDataManager] dbInterface] deleteRowWithTableName:kTableNameDetectedBeaconHistory where:[NSString stringWithFormat:@"where beaconFullPathLink = '%@' and groupSid = '%@'",[beaconHistoryInfoDic objectForKey:@"beaconFullPathLink"],[beaconHistoryInfoDic objectForKey:@"groupSid"]]];
                        }
                    }
                    
                    return;
                }
            }
            
            NSDictionary *detectBeaconInfo = [detectedBeaconHistorySelectArr lastObject];
            NSString *detectedDateStr = [detectBeaconInfo objectForKey:@"detectDate"];
            //        NSString *beaconResearchTime = [detectBeaconInfo objectForKey:@"beaconResearchTime"];
            
            NSDate *startDate = [formatter dateFromString:currentDateStr];
            NSDate *endDate = [formatter dateFromString:detectedDateStr];
            CGFloat timeDifference = [startDate timeIntervalSinceDate:endDate];
            
            if(timeDifference < 0)
                timeDifference *= -1;
            
            //        CGFloat researchTimeSecNum = [beaconResearchTime integerValue] * 3600;
            //재검색시간 24시간으로 설정
            CGFloat researchTimeSecNum = 3600 * 24;
            
#ifdef DEBUG
            //디버그모드 재검색시간....
            researchTimeSecNum = kBeaconResearchTimeForDEBUG_MODE;
#endif
            NSLog(@"***********************");
            NSLog(@"재검색시간(sec) : %.1f",researchTimeSecNum);
            NSLog(@"마지막으로 검색되고 지난 시간(sec) : %.1f",timeDifference);
            NSLog(@"다음 알림까지 남은 시간(sec) : %.1f",researchTimeSecNum - timeDifference);
            NSLog(@"***********************");
            
            //마지막으로 비콘이 검색된 시간이 재검색 기준 시간보다 크면 다시 알림을 보낼 수 있게한다.
            if(timeDifference < researchTimeSecNum)
                bNeedBeaconDetectAlrim = NO;
        }
        
        //비콘과 사용자와의 거리를 확인해서 조건을 만족하는지 확인한다.
        if(bNeedBeaconDetectAlrim == YES)
        {
            if(beacon != nil)
            {
                //거리값 계산해서 적용하기...
                int distanceNum = - [[info objectForKey:@"beaconDistanceIOS"] intValue];
                //            NSLog(@"distanceNum : %d",distanceNum);
                //            NSLog(@"beacon.rssi : %ld",beacon.rssi);
                
                //설정된 거리값 조건을 만족한다면...
                if((beacon.rssi != 0 && (beacon.rssi >= distanceNum)) == NO)
                {
                    bNeedBeaconDetectAlrim = NO;
                }
            }
        }
        
        if(bNeedBeaconDetectAlrim == YES)
        {
            //검색된 비콘 정보를 서버에서 조회한다...
            [self lookUpDetectedBeaconInfo:info beacon:beacon];
        }
    });
}

-(void)lookUpDetectedBeaconInfo:(NSDictionary*)beaconInfo beacon:(CLBeacon*)beacon
{
    //발견한 비콘에 대한 최신데이터를 서버에서 들고온다..
    NSString *beaconMac = [beaconInfo objectForKey:@"beaconMac"];
    NSString *url = [NSString stringWithFormat:@"%@beaconMac=%@",kUrlGetBeaconData,beaconMac];
    
    NSLog(@"비콘 조회하기 url : %@",url);
    
    [self startConnectionWithURL:url
                             tag:nearbyTourContentsConnectionTypeGetBeaconData
                      identifier:beacon
                            info:nil];
}

//비콘 컨텐츠타입을 리턴해줌...
-(beaconContentsType)beaconTypeWithBeaconInfo:(NSDictionary*)beaconInfo
{
    beaconContentsType type = beaconContentsTypeUnknown;
    
    NSString *beaconType = [beaconInfo objectForKey:@"beaconType"];
    NSString *cateCd1 = [beaconInfo objectForKey:@"cateCd1"];
    NSString *groupSid = [beaconInfo objectForKey:@"groupSid"];
    NSString *basicCouponyn = [beaconInfo objectForKey:@"basicCouponyn"];
    
    //groupSid값이 73이고, basicCouponyn값이 Y일때
    if([groupSid isEqualToString:kCouponGroupSid] && [basicCouponyn isEqualToString:@"Y"])
    {
        type = beaconContentsTypeCoupon;        //쿠폰
    }
    else if([cateCd1 isEqualToString:@"0"] || [cateCd1 length] == 0)    //관광 컨텐츠 비콘
        type = beaconContentsTypeTourContents;
    else
        type = beaconContentsTypeStamp;     //스탬프 비콘
    
    NSLog(@"----------------------------");
    NSLog(@"beaconType : %@",beaconType);
    NSLog(@"cateCd1 : %@",cateCd1);
    NSLog(@"비콘 타입 : %ld",type);
//    NSLog(@"beaconInfo : %@",beaconInfo);
    
    return type;
}

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier info:(NSDictionary*)info
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.info = info;
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

#pragma mark - CLLocationManager Delegate

//위치서비스 사용 승인여부 콜백 함수...승인결정 전에도 호출됨.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status > 0)
    {
        NSString *alertMsgStr = nil;
        
        if(![CLLocationManager isMonitoringAvailableForClass:[CLRegion class]])
        {
            //Region monitoring is not available for this Class;
            NSLog(@"지역모니터링 사용 불가능!!");
            alertMsgStr = @"사용자의 기기에서 지역 모니터링 기능을 지원하지 않습니다.\n사용자 주변 관광 컨텐츠 알림 기능을 사용할 수 없습니다.";
        }
        //지역 모니터링 기능 사용가능
        else
        {
            //위치서비스 사용이 항상일때...
            if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)
            {
                NSLog(@"위치서비스 사용 항상일때....");
                alertMsgStr = nil;
            }
            //위치서비스 사용이 앱 실행중일때...
            else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
            {
                NSLog(@"위치서비스 사용이 앱 실행중일때...");
                alertMsgStr = @"위치 서비스 사용이 앱을 사용하는 동안으로 설정되어 있습니다.\n앱을 사용중인 경우가 아닐때에도 사용자 주변의 관광 컨텐츠 알림을 받기 원하시면 설정앱 -> 개인 정보 보호 -> 위치 서비스 항목에서 위치 서비스 사용을 항상으로 변경해 주세요.";
            }
            else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
                    [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
            {
                //You need to authorize Location Services for the APP
                NSLog(@"위치서비스 사용이 승인 거부된 상태임!!");
                alertMsgStr = @"위치서비스를 사용할 수 없습니다.\n사용자 주변의 관광 컨텐츠 알림을 받기 위해서는 위치서비스 사용 승인이 필요합니다.설정앱 -> 개인 정보 보호 -> 위치 서비스 항목에서 위치서비스 사용을 항상으로 변경해 주세요.";
            }
            //사용자가 아직 위치서비스 사용여부를 결정하지 않은 상태
            else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
            {
                NSLog(@"사용자가 위치서비스 사용 승인여부를 아직 결정하지 않은 상태!!");
            }
            //위치서비스 사용이 승인된 상태
            else
            {
                //위치서비스 사용이 꺼져있음.
                if([CLLocationManager locationServicesEnabled] == NO)
                {
                    //You need to enable Location Services
                    NSLog(@"위치 서비스 사용불가능!!");
                    alertMsgStr = @"사용자 기기의 위치 서비스 사용이 꺼져 있습니다.\n설정앱 -> 개인 정보 보호 -> 위치 서비스 사용 스위치를 켜짐으로 변경해 주세요.";
                }
            }
        }

//        if(alertMsgStr != nil)
//            [UTILITY makeAlertWithTitle:@"알림"
//                                message:alertMsgStr
//                         viewController:UTILITY.rootViewControllerPtr];
    }
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region
{
    [beaconManager locationManager:manager
                   didRangeBeacons:beacons
                          inRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [geofenceManager locationManager:manager didUpdateLocations:locations];
}

//경계에 진입할 경우에 호출됨
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if([region.identifier isEqualToString:kBeaconIdentifier])
    {
        [beaconManager locationManager:manager didEnterRegion:region];
    }
    else
    {
        [geofenceManager locationManager:manager didEnterRegion:region];
    }
}

//경계를 벗어날 경우에 호출됨
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if([region.identifier isEqualToString:kBeaconIdentifier])
    {
        [beaconManager locationManager:manager didExitRegion:region];
    }
    else
    {
        [geofenceManager locationManager:manager didExitRegion:region];
    }
}

//지역 모니터링 시작됨.
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if([region.identifier isEqualToString:kBeaconIdentifier])
    {
        [beaconManager locationManager:manager didStartMonitoringForRegion:region];
    }
    else
    {
        [geofenceManager locationManager:manager didStartMonitoringForRegion:region];
    }
}

//모니터링 실패함.
- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(nullable CLRegion *)region
              withError:(NSError *)error
{
    if([region.identifier isEqualToString:kBeaconIdentifier])
    {
        [beaconManager locationManager:manager
              monitoringDidFailForRegion:region
                               withError:error];
    }
    else
    {
        [geofenceManager locationManager:manager
              monitoringDidFailForRegion:region
                               withError:error];
    }
}

//requestStateForRegion 함수 호출 또는 모니터링 지역에 진입 또는 이탈 이벤트 발생시 호출됨.
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if([region.identifier isEqualToString:kBeaconIdentifier])
    {
        [beaconManager locationManager:manager
                       didDetermineState:state
                               forRegion:region];
    }
    else
    {
        [geofenceManager locationManager:manager
                       didDetermineState:state
                               forRegion:region];
    }
}

#pragma mark - BeaconManager Delegate

-(void)beaconManager:(nonnull BeaconManager*)beaconManager didDetectWithBeaconInfo:(nonnull NSDictionary*)info rangedBeacon:(nonnull CLBeacon *)beacon
{
    //물리비콘 발견시 발견된 비콘data만 있으면 지오펜스와 같은 코드 재사용 가능할듯
//    NSLog(@"발견된 비콘 info : %@",info);
    [self detectedBeaconWithInfo:info beacon:beacon];
}

#pragma mark - GeofenceManager Delegate

//가상 비콘 발견시 호출됨...
-(void)geofenceManager:(GeofenceManager*_Nonnull)gfManager didEnterRegionWithInfo:(NSDictionary*_Nullable)info
{
//    NSLog(@"발견된 지오펜스 info : %@",info);
    
    [self detectedBeaconWithInfo:info beacon:nil];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    nearbyTourContentsConnectionType connType = connection.tag;
    
    if(error == nil)
    {
        //쿠폰등록 결과...
        if(connType == nearbyTourContentsConnectionTypeCouponRegist)
        {
            NSLog(@"쿠폰등록 결과값 : %@",result);
            
            dispatch_async(UTILITY.beaconProcessQueue, ^{
                
                NSString *beaconFullPathLink = connection.identifier;
                NSString *groupSid = [connection.info objectForKey:@"groupSid"];
                NSArray *selectBeaconArr = [self detectedBeaconHistoryArrWithContentsUrl:beaconFullPathLink
                                                                                groupSid:groupSid];
                
                //검색된 비콘 히스토리 db에 데이터 저장하기...
                if(selectBeaconArr.count == 0)
                {
                    NSString *detectDate = [UTILITY currentDateWithDateFormat:nil];
                    
                    //인서트 수행하기!!
                    [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
                     insertToTableName:kTableNameDetectedBeaconHistory
                     query:[NSString stringWithFormat:@"INSERT INTO %@ (detectDate, beaconFullPathLink, beaconResearchTime, beaconNotiShowingYN, stampOrCouponYN, groupSid, couponUseYN, couponUseDate) VALUES (?,?,?,?,?,?,?,?)",kTableNameDetectedBeaconHistory]
                     insertData:@{@"detectDate" : detectDate, @"beaconFullPathLink" : beaconFullPathLink, @"beaconResearchTime" : @"1", @"beaconNotiShowingYN" : @"N", @"stampOrCouponYN" : @"Y", @"groupSid" : groupSid, @"couponUseYN" : @"N", @"couponUseDate" : @"0"} insertColumnSequenceArray:@[@"detectDate",@"beaconFullPathLink",@"beaconResearchTime",@"beaconNotiShowingYN",@"stampOrCouponYN", @"groupSid", @"couponUseYN", @"couponUseDate"]];
                }
            });
            
            //쿠폰등록 성공함...
            if([[result objectForKey:@"result"] isEqualToString:@"Y"])
            {
                NSString *titleStr = [connection.info objectForKey:@"beaconTitle"];
                NSString *msgStr = [NSString stringWithFormat:@"\"%@\" 쿠폰이 추가 되었습니다.",titleStr];
                
                [UTILITY.rootViewControllerPtr showBeaconNotiViewWithBeaconInfo:@{@"msg" : msgStr,
                                                                                  @"data" : connection.info}
                                                                 contentsBeacon:NO];
                
                UIViewController *visibleViewController = [UTILITY.rootViewControllerPtr.navigationController visibleViewController];
                
                //할인쿠폰 화면이 보여지고 있는지를 확인함....
                if([visibleViewController isKindOfClass:[SelectMenuViewController class]])
                {
                    SelectMenuViewController *selectMenuViewController = (SelectMenuViewController*)visibleViewController;
                    //할인쿠폰 화면이 보여지고 있으면...
                    if(selectMenuViewController.menuType == SelectMenuTypeCoupon)
                    {
                        //쿠폰 리스트를 새로고침
                        [[selectMenuViewController couponBookView] loadCouponList];
                    }
                }
            }
            //이미 등록한 쿠폰을 다시 등록했다면...
            else
            {
                NSLog(@"이미 등록된 쿠폰 입니다!!");
            }
        }
        //비콘조회 성공..
        else if(connType == nearbyTourContentsConnectionTypeGetBeaconData)
        {
            NSDictionary *beaconDataInfo = [[result objectForKey:@"RFCBeaconData"] firstObject];
            NSLog(@"발견된 비콘조회 결과값 : %@",beaconDataInfo);
            
            //비콘 조회결과 null이면 리턴
            if(beaconDataInfo == nil)       return;
            
            //비콘 컨텐츠 종류가 쿠폰, 스탬프, 관광인지를 판단해야함...
            beaconContentsType type = [self beaconTypeWithBeaconInfo:beaconDataInfo];
            
            NSLog(@"비콘 컨텐츠 타입 : %ld",type);

            //컨텐츠 비콘일때..
            if(type == beaconContentsTypeTourContents)
            {
                NSLog(@"발견된 비콘 타이틀 --- : %@",[beaconDataInfo objectForKey:@"beaconTitle"]);
                NSString *beaconFullPathLink = [beaconDataInfo objectForKey:@"beaconFullPathLink"];
                NSString *groupSid = [beaconDataInfo objectForKey:@"groupSid"];
                NSLog(@"발견된 비콘 beaconFullPathLink --- :  %@",[beaconDataInfo objectForKey:@"beaconFullPathLink"]);
                
//                NSArray *selectBeaconArr = [self detectedBeaconHistoryArrWithContentsUrl:beaconFullPathLink];
//
//                NSString *beaconResearchTime = [beaconDataInfo objectForKey:@"beaconResearchTime"];
//
//                if(beaconResearchTime == nil || [beaconResearchTime length] == 0)
//                    beaconResearchTime = @"1";
                
                dispatch_async(UTILITY.beaconProcessQueue, ^{
                    
                    NSArray *selectBeaconArr = [self detectedBeaconHistoryArrWithContentsUrl:beaconFullPathLink
                                                                                    groupSid:groupSid];
                    
                    NSString *beaconResearchTime = [beaconDataInfo objectForKey:@"beaconResearchTime"];
                    
                    if(beaconResearchTime == nil || [beaconResearchTime length] == 0)
                        beaconResearchTime = @"1";
                    
                    //검색된 비콘 히스토리 db에 데이터 저장하기...
                    if(selectBeaconArr.count == 0)
                    {
                        NSString *detectDate = [UTILITY currentDateWithDateFormat:nil];
                        NSLog(@"detectDate : %@",detectDate);
                        
                        //인서트 수행하기!!
                        [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
                         insertToTableName:kTableNameDetectedBeaconHistory
                         query:[NSString stringWithFormat:@"INSERT INTO %@ (detectDate, beaconFullPathLink, beaconResearchTime, beaconNotiShowingYN, stampOrCouponYN, groupSid) VALUES (?,?,?,?,?,?)",kTableNameDetectedBeaconHistory]
                         insertData:@{@"detectDate" : detectDate, @"beaconFullPathLink" : beaconFullPathLink, @"beaconResearchTime" : beaconResearchTime, @"beaconNotiShowingYN" : @"Y", @"stampOrCouponYN" : @"N", @"groupSid" : groupSid} insertColumnSequenceArray:@[@"detectDate",@"beaconFullPathLink",@"beaconResearchTime",@"beaconNotiShowingYN",@"stampOrCouponYN", @"groupSid"]];
                    }
                    //이미 저장된 정보가 있으면 검색된 시간값을 업데이트 해준다.
                    else
                    {
                        [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface] updateWithTableName:kTableNameDetectedBeaconHistory
                                                                                                      values:@{@"detectDate" : [UTILITY currentDateWithDateFormat:nil], @"beaconResearchTime" : beaconResearchTime, @"beaconNotiShowingYN" : @"Y"}
                                                                                                       where:[NSString stringWithFormat:@"where beaconFullPathLink = '%@' and groupSid = '%@'",beaconFullPathLink, groupSid]];
                    }
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        //사용자에게 알림화면 보여줌
                        [UTILITY.rootViewControllerPtr showBeaconNotiViewWithBeaconInfo:beaconDataInfo
                                                                         contentsBeacon:YES];
                    });
                    
                });
            }
            //스탬프 또는 쿠폰일때..
            else
            {
                NSString *url = nil;
                nearbyTourContentsConnectionType connType = nearbyTourContentsConnectionTypeUnknown;
                NSString *beaconFullPathLink = [beaconDataInfo objectForKey:@"beaconFullPathLink"];
                
                //쿠폰이면 서버에 등록함...
                if(type == beaconContentsTypeCoupon)
                {
                    connType = nearbyTourContentsConnectionTypeCouponRegist;
                    
                    NSString *couponCdKeyStr = @"basicSid=";
                    NSRange range = [beaconFullPathLink rangeOfString:couponCdKeyStr];
                    
                    if(range.location == NSNotFound)
                    {
                        couponCdKeyStr = @"eventSid=";
                        range = [beaconFullPathLink rangeOfString:couponCdKeyStr];
                    }
                    
                    NSString *eventSid = [beaconFullPathLink stringByReplacingCharactersInRange:NSMakeRange(0, range.location + couponCdKeyStr.length) withString:@""];
                    
                    url = [NSString stringWithFormat:@"%@uuid=%@&couponCd=%@",kUrlCouponRegist,[UTILITY UUID], eventSid];
                    
                    NSLog(@"쿠폰 비콘 발견됨!!");
                    //쿠폰을 등록하기전 쿠폰 사용가능 날짜를 확인해서 쿠폰 등록여부를 결정한다.
                    NSString *currentDateStr = [UTILITY currentDateWithDateFormat:@"yyyy-MM-dd"];
                    NSString *basicCouponday1Str = [beaconDataInfo objectForKey:@"basicCouponday1"];
                    NSString *basicCouponday2Str = [beaconDataInfo objectForKey:@"basicCouponday2"];
                    NSString *basicCoupondayType = [beaconDataInfo objectForKey:@"basicCoupondayType"];
                    
                    //쿠폰 사용날짜가 상시일때...
                    //basicCoupondayType 1:상시, 2:연중, 3:날짜

                    //이용가능 날짜가 지정되어 있을때
                    if([basicCoupondayType isEqualToString:@"3"])
                    {
                        NSInteger currentDateNum = [[currentDateStr stringByReplacingOccurrencesOfString:@"-" withString:@""] integerValue];
                        NSInteger basicCouponday1Num = [[basicCouponday1Str stringByReplacingOccurrencesOfString:@"-" withString:@""] integerValue];
                        NSInteger basicCouponday2Num = [[basicCouponday2Str stringByReplacingOccurrencesOfString:@"-" withString:@""] integerValue];
                        
                        NSLog(@"**** 날짜지정쿠폰 등록가능 확인");
                        NSLog(@"currentDateNum : %ld",currentDateNum);
                        NSLog(@"basicCouponday1Num : %ld",basicCouponday1Num);
                        NSLog(@"basicCouponday2Num : %ld",basicCouponday2Num);
                        
                        //오늘 날짜가 쿠폰 사용가능 날짜를 벗어났으면
                        if(currentDateNum < basicCouponday1Num ||
                           currentDateNum > basicCouponday2Num)
                        {
                            url = nil;
                        }
                    }
                    //연중
                    else if([basicCoupondayType isEqualToString:@"2"])
                    {
                        NSString *currentYearStr = [UTILITY currentDateWithDateFormat:@"yyyy"];
                        NSString *basicCouponday1StrYear = [basicCouponday1Str substringToIndex:4];
                        
                        NSInteger currentYearNum = [currentYearStr integerValue];
                        NSInteger basicCouponday1StrYearNum = [basicCouponday1StrYear integerValue];
                        
                        NSLog(@"**** 연중쿠폰 등록가능 확인");
                        NSLog(@"currentYearNum : %ld",currentYearNum);
                        NSLog(@"basicCouponday1StrYearNum : %ld",basicCouponday1StrYearNum);
                        
                        //년도가 다르면
                        if(currentYearNum != basicCouponday1StrYearNum)
                        {
                            url = nil;
                        }
                    }
                }
                //스탬프일때..
                else if(type == beaconContentsTypeStamp)
                {
                    NSLog(@"스탬프 비콘 발견됨!!");
                    connType = nearbyTourContentsConnectionTypeStampRegist;
                    NSString *cateCd1 = [beaconDataInfo objectForKey:@"cateCd1"];
                    NSString *cateCd2 = [beaconDataInfo objectForKey:@"cateCd2"];
                    url = [NSString stringWithFormat:@"%@uuid=%@&cateCd1=%@&cateCd2=%@",kUrlStampRegist,[UTILITY UUID],cateCd1,cateCd2];
                }
                
                NSLog(@"쿠폰 또는 스탬프등록 url : %@",url);
                
                if(url != nil)
                {
                    [self startConnectionWithURL:url
                                             tag:connType
                                      identifier:beaconFullPathLink
                                            info:beaconDataInfo];
                }
                else
                {
                    NSLog(@"**** 쿠폰 사용가능 기간이 지나서 쿠폰등록 및 알림 무시합니다.");
                }
            }
        }
        //스탬프 등록 성공일때..
        else if(connType == nearbyTourContentsConnectionTypeStampRegist)
        {
            NSLog(@"스탬프 등록 결과 result : %@",result);
            NSLog(@"스탬프 등록 결과 msg : %@",[result objectForKey:@"msg"]);
            if([[result objectForKey:@"result"] isEqualToString:@"Y"])
            {
                NSString *beaconFullPathLink = connection.identifier;
                NSString *groupSid = [connection.info objectForKey:@"groupSid"];
                NSArray *selectBeaconArr = [self detectedBeaconHistoryArrWithContentsUrl:beaconFullPathLink
                                                                                groupSid:groupSid];
                
                //검색된 비콘 히스토리 db에 데이터 저장하기...
                if(selectBeaconArr.count == 0)
                {
                    NSString *detectDate = [UTILITY currentDateWithDateFormat:nil];
                    
                    dispatch_async(UTILITY.beaconProcessQueue, ^{
                        
                        //인서트 수행하기!!
                        [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
                         insertToTableName:kTableNameDetectedBeaconHistory
                         query:[NSString stringWithFormat:@"INSERT INTO %@ (detectDate, beaconFullPathLink, beaconResearchTime, beaconNotiShowingYN, stampOrCouponYN, groupSid) VALUES (?,?,?,?,?,?)",kTableNameDetectedBeaconHistory]
                         insertData:@{@"detectDate" : detectDate, @"beaconFullPathLink" : beaconFullPathLink, @"beaconResearchTime" : @"1", @"beaconNotiShowingYN" : @"N", @"stampOrCouponYN" : @"Y", @"groupSid" : groupSid} insertColumnSequenceArray:@[@"detectDate",@"beaconFullPathLink",@"beaconResearchTime",@"beaconNotiShowingYN",@"stampOrCouponYN",@"groupSid"]];
                    });
                }
                
                if([[result objectForKey:@"msg"] isEqualToString:@"이미찍은 스템프입니다."] == NO)
                {
                    NSString *titleStr = [connection.info objectForKey:@"beaconTitle"];
                    NSString *msgStr = [NSString stringWithFormat:@"\"%@\" 스탬프가 추가 되었습니다.",titleStr];
                    
                    [UTILITY.rootViewControllerPtr showBeaconNotiViewWithBeaconInfo:@{@"msg" : msgStr,
                                                                                      @"data" : connection.info}
                                                                     contentsBeacon:NO];
                    
                    //스탬프 리스트 새로고침..
                    NSArray *viewControllerStackArr = [[[UTILITY.rootViewControllerPtr topMenuView] stampTourNavigationController] viewControllers];
                    
                    NSLog(@"00000 viewControllerStackArr : %@",viewControllerStackArr);
                    
                    StampTourViewController *stamp = [viewControllerStackArr firstObject];
                    [stamp loadstampList];
                    
                    if(viewControllerStackArr.count > 1)
                    {
                        //스탬프 데이터 리로드...
                        StampTourDetailViewController *pView = [viewControllerStackArr lastObject];
                        [pView loadStampData];
                    }
                }
            }
        }
    }
}

@end
