//
//  NearbyTourContentsDetect.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 6..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeofenceManager.h"
#import "BeaconManager.h"
#import "TheConnection.h"

@protocol NearbyTourcontentsDetectDelegate;
@interface NearbyTourContentsDetect : NSObject
<CLLocationManagerDelegate, BeaconManagerDelegate, GeofenceManagerDelegate, TheConnectionDelegate>
{
    CLLocationManager *locationManager;
    GeofenceManager *geofenceManager;
    BeaconManager *beaconManager;
}

@property (nonatomic, weak) id <NearbyTourcontentsDetectDelegate> delegate;

@end

@protocol NearbyTourcontentsDetectDelegate <NSObject>

@optional

@end
