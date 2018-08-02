//
//  GeofenceManager.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@protocol GeofenceManagerDelegate;
@interface GeofenceManager : NSObject

-(instancetype _Nonnull)initWithLocationManager:(CLLocationManager* _Nonnull)_cllocationManager;

- (void)locationManager:(CLLocationManager * _Nonnull)manager
     didUpdateLocations:(NSArray<CLLocation *> * _Nonnull)locations;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didEnterRegion:(CLRegion * _Nonnull)region;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didExitRegion:(CLRegion * _Nonnull)region;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didStartMonitoringForRegion:(CLRegion * _Nonnull)region;
- (void)locationManager:(CLLocationManager * _Nonnull)manager
monitoringDidFailForRegion:(nullable CLRegion *)region
              withError:(NSError * _Nonnull)error;
- (void)locationManager:(CLLocationManager * _Nonnull)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion * _Nonnull)region;

@property (nonatomic, weak, nullable) id <GeofenceManagerDelegate> delegate;

@end

@protocol GeofenceManagerDelegate <NSObject>

-(void)geofenceManager:(GeofenceManager*_Nonnull)gfManager didEnterRegionWithInfo:(NSDictionary*_Nullable)info;

@end

