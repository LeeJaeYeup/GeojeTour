//
//  BeaconManager.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 11..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define kBeaconIdentifier   @"geojeBeacon"

@protocol BeaconManagerDelegate;
@interface BeaconManager : NSObject <CLLocationManagerDelegate, CBCentralManagerDelegate>
{
    CLLocationManager *locationManager;
    CLBeaconRegion *targetBeaconRegion;
    CBCentralManager *centralManager;
}

@property (nonatomic, weak, nullable) id <BeaconManagerDelegate> delegate;

-(nonnull id)initWithLocationManager:(nonnull CLLocationManager*)_locationManager;

- (void)locationManager:(nonnull CLLocationManager *)manager
       didFailWithError:(nonnull NSError *)error;
- (void)locationManager:(nonnull CLLocationManager *)manager
      didDetermineState:( CLRegionState)state forRegion:(nonnull CLRegion *)region;
- (void)locationManager:(nonnull CLLocationManager *)manager didEnterRegion:(nonnull CLRegion *)region;
- (void)locationManager:(nonnull CLLocationManager *)manager didExitRegion:(nonnull CLRegion *)region;
- (void)locationManager:(nonnull CLLocationManager *)manager didStartMonitoringForRegion:(nonnull CLRegion *)region;
- (void)locationManager:(nonnull CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region withError:(nonnull NSError *)error;
-(void)locationManager:(nonnull CLLocationManager*)manager didRangeBeacons:(nonnull NSArray*)beacons inRegion:(nonnull CLBeaconRegion*)beaconRegion;

@end

@protocol BeaconManagerDelegate <NSObject>

-(void)beaconManager:(nonnull BeaconManager*)beaconManager didDetectWithBeaconInfo:(nonnull NSDictionary*)info rangedBeacon:(nonnull CLBeacon *)beacon;


@end
