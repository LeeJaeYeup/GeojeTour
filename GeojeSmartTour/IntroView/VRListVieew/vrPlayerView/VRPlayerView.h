//
//  VRPlayerView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 26..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol VRPlayerViewDelegate;
@interface VRPlayerView : UIView

@property (weak, nonatomic) id <VRPlayerViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame url:(NSURL *)url;
-(void)setSubTitleWithText:(NSString*)text;

@end

@protocol VRPlayerViewDelegate <NSObject>

-(void)didSelectFullScreenBtnWithVRPlayerView:(VRPlayerView*)vrpView;

@end
