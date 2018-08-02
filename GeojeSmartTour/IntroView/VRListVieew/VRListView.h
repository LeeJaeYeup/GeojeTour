//
//  VRListView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 20..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VRPlayerView.h"

@protocol VRListViewDelegate;
@interface VRListView : UIView

@property (nonatomic, strong) VRPlayerView *vrPlayerView;
@property (nonatomic, weak) id <VRListViewDelegate> delegate;

@end

@protocol VRListViewDelegate <NSObject>

-(void)didSelectListWithTitle:(NSString*)title;

@end
