//
//  BeaconManager.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 11..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "BeaconManager.h"

@implementation BeaconManager

-(nonnull id)initWithLocationManager:(nonnull CLLocationManager*)_locationManager
{
    if(self = [super init])
    {
        NSUUID *targetBeaconUUid = [[NSUUID alloc] initWithUUIDString:@"FDA50693-A4E2-4FB1-AFCF-C6EB07647821"];
        
        targetBeaconRegion = [[CLBeaconRegion alloc]
                              initWithProximityUUID:targetBeaconUUid
                              identifier:kBeaconIdentifier];
        
        centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                              queue:dispatch_get_main_queue()];
        
        locationManager = _locationManager;
        
        [self startRanging];
        [self startMonitoring];
    }
    
    return self;
}

#pragma mark - cllocationManager delegate

- (void)locationManager:(nonnull CLLocationManager *)manager
didFailWithError:(nonnull NSError *)error
{
//    NSLog(@"******** locationManager error : %@",error);
}

//사용자의 장치가 등록된 region에 대해서 inside인지 outside인지를 알려줌.
- (void)locationManager:(nonnull CLLocationManager *)manager
didDetermineState:(CLRegionState)state forRegion:(nonnull CLRegion *)region
{
//    NSLog(@"region : %@, didDetermineState : %ld",region,state);
}

- (void)locationManager:(nonnull CLLocationManager *)manager didEnterRegion:(nonnull CLRegion *)region
{
    NSLog(@"------ Enter Region.");
}

- (void)locationManager:(nonnull CLLocationManager *)manager didExitRegion:(nonnull CLRegion *)region
{
    NSLog(@"------ didExitRegion");
}

- (void)locationManager:(nonnull CLLocationManager *)manager didStartMonitoringForRegion:(nonnull CLRegion *)region
{
//    NSLog(@"--- didStartMonitoring : %@",region);
}

- (void)locationManager:(nonnull CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region withError:(nonnull NSError *)error
{
//    NSLog(@"******** monitoringDidFailForRegion : %@",[error description]);
}

-(void)locationManager:(nonnull CLLocationManager*)manager didRangeBeacons:(nonnull NSArray*)beacons inRegion:(nonnull CLBeaconRegion*)beaconRegion
{
    //발견된 비콘이 db에 등록된 비콘인지 확인한다...
    for(CLBeacon *detectedBeacon in beacons)
    {
//        NSLog(@"주변 비콘들 : %@",beacons);
        
        NSString *major = [[detectedBeacon major] stringValue];
        NSString *minor = [[detectedBeacon minor] stringValue];
        NSString *selectWhereQuery = [NSString stringWithFormat:@"where beaconMajor = '%@' and beaconMinor = '%@'",major,minor];
        
        NSArray *selectBeaconInfoArr =
        [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
         selectAllWithTableName:kTableNameAllBeacon
         where:selectWhereQuery];
        
        //db에 존재한다면...
        if([selectBeaconInfoArr count] > 0)
        {
            //알려준다.
            if([self.delegate respondsToSelector:@selector(beaconManager:didDetectWithBeaconInfo:rangedBeacon:)])
                [self.delegate beaconManager:self didDetectWithBeaconInfo:[selectBeaconInfoArr firstObject] rangedBeacon:detectedBeacon];
        }
    }
}

#pragma mark - CBCentralManager delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"state = %d",(int)central.state);
    
    if(central.state == CBManagerStatePoweredOn)
    {
        NSLog(@"블루투스 켜짐상태");
    }
    else if(central.state == CBManagerStatePoweredOff)
    {
        NSLog(@"블루투스 꺼짐상태");
    }
}

#pragma mark - private

-(void)startRanging
{
    [locationManager startRangingBeaconsInRegion:targetBeaconRegion];
}

-(void)stopRanging
{
    [locationManager stopRangingBeaconsInRegion:targetBeaconRegion];
}

-(void)startMonitoring
{
    [locationManager startMonitoringForRegion:targetBeaconRegion];
}

-(void)stopMonitoring
{
    [locationManager stopMonitoringForRegion:targetBeaconRegion];
}

@end

