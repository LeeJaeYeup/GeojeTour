//
//  GeofenceManager.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "GeofenceManager.h"
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ViewController.h"

#define kUserRegionIdentifier                  @"userRegion"  //사용자 위치 region id
#define kUserNearContentsUpdateCycleMeter      10             //사용자가 이 값 만큼 이동할 경우 주변 컨텐츠를 업데이트 함.


@interface GeofenceManager ()
{
    CLLocationManager   *locationManager;
    CLRegion            *currentUserLocationRegion;     //사용자 위치를 중심으로 한 지오펜스 지역
    CLLocation          *lastUserLocation;              //사용자 최근 위치
    
    NSMutableDictionary *monitoringRegionDataIndexes;    //추가된 지오펜스 지역에 대한 db데이터 index값 저장
}

@end

@implementation GeofenceManager

-(instancetype _Nonnull)initWithLocationManager:(CLLocationManager* _Nonnull)_cllocationManager
{
    if(self = [super init])
    {
        monitoringRegionDataIndexes = [[NSMutableDictionary alloc] initWithCapacity:20];
        
        locationManager = _cllocationManager;
        
        //원하는 정확도 설정 - 정확도가 높아질수록 배터리 소모율도 상승함.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        //사용자 위치 업데이트 이벤트를 받기위한 최소 거리
        locationManager.distanceFilter = 5;
        //백그라운드 위치정보 업데이트 사용함.
        locationManager.allowsBackgroundLocationUpdates = YES;
        //중요위치 변경 모니터링 사용(500미터 이상 이동시 앱이 꺼져있는 상태에서 위치정보 업데이트 이벤트를 받을 수 있다)
        [locationManager startMonitoringSignificantLocationChanges];
        //위치정보 갱신을 자동으로 중지시킬지 여부(default YES)
        locationManager.pausesLocationUpdatesAutomatically = NO;
        
#ifdef DEBUG
        //앱이 백그라운드 상태에서 위치정보를 사용할때 핸드폰 상단에 위치정보 사용중임을 알리는 바가 나타남.
        if (@available(iOS 11.0, *))
            [locationManager setShowsBackgroundLocationIndicator:YES];
#endif
        
        //사용자 위치정보 업데이트 시작...
        [locationManager startUpdatingLocation];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    return self;
}

#pragma mark - NSNotification

//홈버튼 더블탭시 호출됨...
-(void)appWillResignActive
{
    CLLocation *userLocation = locationManager.location;
    [self addGeofenceToUserRegionLocation:userLocation];
}

#pragma mark - private

//현재 모니터링 중인 지역에 대한 db내의 data 반환하기...
-(NSDictionary*)beaconDataFromMonitoredRegion:(CLRegion*)region
{
    NSDictionary *beaconInfoDict = nil;
    NSString *regionIdentifier = region.identifier;
    
    if([regionIdentifier isEqualToString:@"userRegion"] == NO)
    {
        NSString *beaconIndex = [monitoringRegionDataIndexes objectForKey:regionIdentifier];
        
        //비콘 데이터 index를 가지고 db에서 비콘정보 조회하기
        beaconInfoDict = [[[[[UTILITY rootViewControllerPtr] beaconDataManager] dbInterface]
                           selectAllWithTableName:kTableNameAllBeacon
                           where:[NSString stringWithFormat:@"where id ='%@'",beaconIndex]] lastObject];
    }
    
    return beaconInfoDict;
}

//사용자 위치에 로케이션 추가하기...
-(void)addGeofenceToUserRegionLocation:(CLLocation*)userLocation
{
    //사용자의 현재 위치에 지오펜스 하나 추가함.(앱이 꺼졌을때 깨우기 위한 용도)
    currentUserLocationRegion = [self addGeofenceWithId:kUserRegionIdentifier
                                               latitude:[NSString stringWithFormat:
                                                         @"%lf",userLocation.coordinate.latitude]
                                              longitude:[NSString stringWithFormat:
                                                         @"%lf",userLocation.coordinate.longitude]
                                                 radius:@"10"];
}

//sql db에서 비콘 데이터 가져오기...
-(NSArray*)selectSqlBeaconDataWithIndex:(NSInteger)index selectColumns:(NSArray*)columns
{
    if(index < 0)       return nil;
    return [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
            selectWithColumns:columns
            WithTableName:kTableNameAllBeacon
            where:[NSString stringWithFormat:@"where id = '%ld'",index]
            distinct:NO];
}

//지오펜스 추가하기
-(CLRegion*)addGeofenceWithId:(NSString*)identifier latitude:(NSString*)latitude longitude:(NSString*)longitude radius:(NSString*)radiusMeter
{
    if(latitude == nil)         latitude = @"0";
    if(longitude == nil)        longitude = @"0";
    
    NSDictionary *regionDict = @{@"identifier" : identifier,
                                 @"latitude" : latitude,
                                 @"longitude" : longitude,
                                 @"radius" : radiusMeter};
    //모니터링 시작!!
    CLRegion *newRegion = [self dictToRegion:regionDict];
    
    if(newRegion == nil)
    {
        NSLog(@"모니터링 시작하는 region이 null!!");
    }
    
    [locationManager startMonitoringForRegion:newRegion];
    return newRegion;
}

//CLRegion 객체 생성
- (CLRegion*)dictToRegion:(NSDictionary*)dictionary
{
    NSString *identifier = [dictionary valueForKey:@"identifier"];
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude = [[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];     //미터단위
    
//    NSLog(@"최대 모니터링 가능 거리(반지름, 미터) : %lf",locationManager.maximumRegionMonitoringDistance);
    
    //모니터링 가능한 최대 거리(미터) 하드웨어 마다 다를 수 있다고 함...
    if(regionRadius > locationManager.maximumRegionMonitoringDistance)
    {
        regionRadius = locationManager.maximumRegionMonitoringDistance;
        NSLog(@"***** 설정가능한 지오펜스 최대 거리를 벗어났습니다!!!!!");
    }
    
    CLRegion * region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate
                                                          radius:regionRadius
                                                      identifier:identifier];
    return  region;
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager * _Nonnull)manager
     didUpdateLocations:(NSArray<CLLocation *> * _Nonnull)locations
{
    NSLog(@"didUpdateLocations : %@",locations);
    CLLocation *userLocation = [locations lastObject];      //가장 최근에 업데이트 된 위치값을 가져온다.
    //    CLLocationAccuracy verticalAccuracy = userLocation.verticalAccuracy;
    CLLocationAccuracy horizontalAccuracy = userLocation.horizontalAccuracy;
    
    /*
     위치 정확도 값이 0보다 크고(-값은 쓰레기 값),
     정확도가 +- 65미터 일때...
     */
    if(horizontalAccuracy > 0 && horizontalAccuracy <= 65)
    {
#ifndef DEBUG       //디버그 모드에서는 사용안함.
        //위도 경도가 한국을 벗어나는 값인지 확인한다.
        if((userLocation.coordinate.latitude >= 33 && userLocation.coordinate.latitude < 39) &&
           (userLocation.coordinate.longitude >= 125 && userLocation.coordinate.longitude <= 131))
#endif
        {
            
            dispatch_async(UTILITY.beaconProcessQueue, ^{
                
                //사용자 위치 지오펜스가 nil이면...
                if(currentUserLocationRegion == nil)
                {
                    NSLog(@"-+-+ userLocation : %@",userLocation);
                    
                    //사용자의 현재 위치에 지오펜스 하나 추가함.(앱이 꺼졌을때 깨우기 위한 용도)
                    [self addGeofenceToUserRegionLocation:userLocation];
                    
                    NSLog(@"사용자 위치에 지오펜스 추가됨!!");
                    //                NSLog(@"monitoredRegions : %@",[locationManager monitoredRegions]);
                }
                
                //사용자 위치에서 가장 가까운곳 18지역을 지오펜스로 등록하기.
                /*
                 1. 사용자가 이전 사용자 위치에서 n미터 이상 이동했을 경우에 등록작업 시작함.
                 2. 데이터셋과 사용자의 위치를 비교해서 거리값의 차이와, 데이터셋의 위치(index)를 저장한 배열을 하나 만듬.
                 3. 오름차순으로 2번에서 구한 배열을 정렬함.
                 4. 3번에서 생성된 데이터를 근거로 지오펜스를 생성함.(가장 가까운 순서로 18개)
                 */
                
                MKMapPoint userPoint = MKMapPointForCoordinate(userLocation.coordinate);
                MKMapPoint lastUserPoint = MKMapPointForCoordinate(lastUserLocation.coordinate);
                
                CLLocationDistance userDistance = MKMetersBetweenMapPoints(userPoint, lastUserPoint);
                
                //저장된 위치값이 없거나 사용자의 위치가 이전 위치보다 10미터 이상 차이가 나면...
                if(lastUserLocation == nil || userDistance >= kUserNearContentsUpdateCycleMeter)
                {
                    //사용자 위치값 업데이트
                    lastUserLocation = userLocation;
                    currentUserLocationRegion = nil;
                    
                    NSMutableArray *distanceArray = [[NSMutableArray alloc] init];
                    
                    //DB에 저장된 모든 비콘 데이터를 조회해서 사용자와 거리값을 저장한 배열을 하나 만든다...
                    int dbIndex = 1;
                    while (YES)
                    {
                        NSArray *selectedBeaconArray = [self selectSqlBeaconDataWithIndex:dbIndex
                                                                            selectColumns:@[@"beaconGubun",@"beaconXmap",@"beaconYmap"]];
                        
                        //배열이 비어있으면 모든 db의 마지막 데이터까지 조회가 완료된거임.
                        if(selectedBeaconArray.count == 0)      break;
                        
                        NSDictionary *beaconDataInfo = [selectedBeaconArray firstObject];
                        NSString *beaconGubun = [beaconDataInfo objectForKey:@"beaconGubun"];
                        
                        //가상비콘만 수행함...
                        if([beaconGubun integerValue] == 2)
                        {
                            double dataLatitude = [[beaconDataInfo objectForKey:@"beaconXmap"] doubleValue];
                            double dataLongitude = [[beaconDataInfo objectForKey:@"beaconYmap"] doubleValue];
                            CLLocationCoordinate2D dataCoord = CLLocationCoordinate2DMake(dataLatitude, dataLongitude);
                            MKMapPoint dataPoint = MKMapPointForCoordinate(dataCoord);
                            CLLocationDistance distanceMeter = MKMetersBetweenMapPoints(userPoint, dataPoint);
                            
                            //사용자 위치와 데이터셋의 위치값 거리 간격 확인.
                            NSDictionary *distanceInfoDict = @{@"distance" : [NSNumber numberWithDouble:distanceMeter],
                                                               @"index" : [NSString stringWithFormat:@"%d",dbIndex]
                                                               };
                            //거리값과 원본 데이터 배열 index값 저장해놓기
                            [distanceArray addObject:distanceInfoDict];
                        }
                        
                        dbIndex ++;
                    }
                    
                    //                    NSLog(@"distanceArray : %@",distanceArray);
                    
                    //오름차순으로 정렬하기
                    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance"
                                                                                    ascending:YES];
                    [distanceArray sortUsingDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
                    //                    NSLog(@"distanceArray : %@",distanceArray);
                    
                    //지오펜스 추가하기
                    NSInteger maximumCount = 18;
                    if(distanceArray.count < maximumCount)
                        maximumCount = distanceArray.count;
                    
                    for(int i = 0; i < maximumCount; i ++)
                    {
                        //db테이블 내의 id값
                        NSInteger dataIndex = [[[distanceArray objectAtIndex:i] objectForKey:@"index"] integerValue];
                        NSDictionary *geofenceDataInfo = [[self selectSqlBeaconDataWithIndex:dataIndex
                                                                               selectColumns:@[@"beaconDistanceIOS",@"beaconXmap",@"beaconYmap"]] firstObject];
                        
                        
//                        NSLog(@"지오펜스 등록할 비콘 정보 : %@",geofenceDataInfo);
                        NSString *geofenceRegionRadiusMeterStr = [geofenceDataInfo objectForKey:@"beaconDistanceIOS"];
                        
                        if(geofenceRegionRadiusMeterStr == nil)     geofenceRegionRadiusMeterStr = @"20";
                        
                        NSLog(@"추가되는 지오펜스 지역의 sql 내의 id 번호 : %ld",dataIndex);
                        
                        //추가되는 지역에 대한 db테이블 index값 저장
                        NSString *geofenceIdentifierStr = [NSString stringWithFormat:@"region_%d",i + 1];
                        [monitoringRegionDataIndexes setValue:[NSString stringWithFormat:@"%ld",dataIndex] forKey:geofenceIdentifierStr];
                        
                        //지오펜스 모니터링 지역 추가.
                        [self addGeofenceWithId:geofenceIdentifierStr
                                       latitude:[geofenceDataInfo objectForKey:@"beaconXmap"]
                                      longitude:[geofenceDataInfo objectForKey:@"beaconYmap"]
                                         radius:geofenceRegionRadiusMeterStr];
                    }
                    
                    //필요없는 데이터 삭제...
                    [distanceArray removeAllObjects];
                    distanceArray = nil;
                    
                    //사용자가 모니터링중인 지역에 위치해 있는지 확인한다..
                    NSSet *monitoredRegions = [locationManager monitoredRegions];
                    NSLog(@"112233 monitoredRegions : %@",monitoredRegions);
                    
                    //등록된 모니터링 지역이 1개 초과라면..
                    if(monitoredRegions.count > 1)
                    {
                        NSArray *monitoredRegionArr = [monitoredRegions allObjects];
                        CLLocationCoordinate2D userCoord = userLocation.coordinate;
                        
                        for(int i = 0; i < monitoredRegionArr.count; i ++)
                        {
                            CLCircularRegion *monitoredRegion = [monitoredRegionArr objectAtIndex:i];
                            NSString *regionIdentifier = monitoredRegion.identifier;
                            
                            //사용자의 현재 위치가 지오펜스 안에 위치해 있다면...
                            if([regionIdentifier isEqualToString:kUserRegionIdentifier] == NO
                               && [monitoredRegion containsCoordinate:userCoord])
                            {
                                NSLog(@"****** 등록된 지점에 사용자가 접근함!! ******");
                                NSLog(@"regionIdentifier : %@\n",regionIdentifier);
                                
                                NSDictionary *beaconDataInfo = [self beaconDataFromMonitoredRegion:monitoredRegion];
                                
                                if(beaconDataInfo != nil)
                                {
                                    //db내에 해당 지오펜스 지역에 대한 비콘 정보가 있으면 알려준다.
                                    if([self.delegate respondsToSelector:@selector(geofenceManager:didEnterRegionWithInfo:)])
                                        [self.delegate geofenceManager:self
                                                didEnterRegionWithInfo:beaconDataInfo];
                                }
                            }
                        }
                    }
                }
                
            });
            
        } //end of 2nd if
        
    } //end of 1st if
}

//경계에 진입할 경우에 호출됨
- (void)locationManager:(CLLocationManager * _Nonnull)manager didEnterRegion:(CLRegion * _Nonnull)region
{
    NSLog(@"*** didEnterRegion : %@ ***",region);
}

//경계를 벗어날 경우에 호출됨
- (void)locationManager:(CLLocationManager * _Nonnull)manager didExitRegion:(CLRegion * _Nonnull)region
{
    NSLog(@"*** didExitRegion : %@ ***",region);
    
    //유저위치 리전을 벗어났을 경우...
    if([region.identifier isEqualToString:kUserRegionIdentifier])
    {
        //사용자 위치에 지오펜스 다시 추가...
        [self addGeofenceToUserRegionLocation:manager.location];
    }
}

//지역 모니터링 시작됨.
- (void)locationManager:(CLLocationManager * _Nonnull)manager didStartMonitoringForRegion:(CLRegion * _Nonnull)region
{
//    NSLog(@"*** 모니터링 시작됨, 추가된 지역 : %@",region);
    
    //모니터링이 시작된 region에 대해서 바운더리 내에 있는지 밖에 있는지 확인하기
    //locationManager:diddetermineState 델리게이트 함수가 호출됨
    [manager requestStateForRegion:region];
}

//모니터링 실패함.
- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(nullable CLRegion *)region
              withError:(NSError * _Nonnull)error
{
    NSLog(@"monitoringDidFailForRegion : %@\nerror : %@\n",region,error);
    
    //지역등록에 실패할 경우 kCLErrorRegionMonitoringFailure 에러코드 발생함
    if([error code] == kCLErrorRegionMonitoringFailure)
    {
        NSLog(@"**** 등록된 지역 모니터링 불가능함!!, region : %@ ****",region);
    }
}

//requestStateForRegion 함수 호출 또는 모니터링 지역에 진입 또는 이탈 이벤트 발생시 호출됨.
- (void)locationManager:(CLLocationManager * _Nonnull)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion * _Nonnull)region
{
    //state로 inside, outside, unknown을 알 수 있으나 정확도가 안좋다.
    NSLog(@"바운더리 내에 있는지 밖에 있는지 여부(1=내부,2=외부) : %ld\nregion : %@\n",state, region);
    
    //추가된 region의 내부에 사용자가 있다면...
    if(state == CLRegionStateInside)
    {
        NSDictionary *beaconDataInfo = [self beaconDataFromMonitoredRegion:region];

        if(beaconDataInfo != nil)
        {
            //db내에 해당 지오펜스 지역에 대한 비콘 정보가 있으면 알려준다.
            if([self.delegate respondsToSelector:@selector(geofenceManager:didEnterRegionWithInfo:)])
                [self.delegate geofenceManager:self
                        didEnterRegionWithInfo:beaconDataInfo];
        }
    }
    
    //    NSString *determineStateDescriptStr = @"알수없음";
    //
    //    if(state == CLRegionStateInside)
    //        determineStateDescriptStr = @"didDetermineState : CLRegionStateInside";
    //    else if(state == CLRegionStateOutside)
    //        determineStateDescriptStr = @"didDetermineState : CLRegionStateOutside";
    
}

@end
