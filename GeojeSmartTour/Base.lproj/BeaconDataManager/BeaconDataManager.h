//
//  BeaconDataManager.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 21..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBInterFace.h"

@protocol BeaconDataManagerDelegate;
@interface BeaconDataManager : NSObject

@property (nonatomic, readonly) DBInterFace         *dbInterface;
@property (nonatomic, weak) id <BeaconDataManagerDelegate> delegate;

-(void)getAllBeaconDataWithVersion:(NSString*)version;

@end

@protocol BeaconDataManagerDelegate <NSObject>

-(void)didFinishGetAllBeaconData:(BeaconDataManager*)bdm beaconVersion:(NSString*)version;
-(void)beaconDataManager:(BeaconDataManager*)bdm didProgressInsertInDbWithIndex:(int)index totalCount:(int)total;

@end
