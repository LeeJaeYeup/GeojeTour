////
////  HTY360PlayerVC.h
////  HTY360Player
////
////  Created by  on 11/8/15.
////  Copyright © 2015 Hanton. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//#import <AVFoundation/AVFoundation.h>
//
//@interface HTY360PlayerVC : UIViewController <AVPlayerItemOutputPullDelegate>
//
//@property (strong, nonatomic) IBOutlet UIView *playerControlBackgroundView;
//
//- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url;
//- (CVPixelBufferRef)retrievePixelBufferToDraw;
//- (void)toggleControls;
//
//- (void)configureGLKView;
//- (void)removeGLKView;
//
//@end

//
//  HTY360PlayerVC.h
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol HTY360PlayerVCDelegate;
@interface HTY360PlayerVC : UIViewController

@property (strong, nonatomic) NSURL *videoURL;
@property (nonatomic, weak) id <HTY360PlayerVCDelegate> delegate;
@property (nonatomic, strong) UIButton *playToggleBtn;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, readonly) double currentPlayTime;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url;
- (AVPlayer*)player;
- (CVPixelBufferRef)retrievePixelBufferToDraw;
-(UIView*)getIconsBackView;
-(void)setMute:(BOOL)bMute;
-(void)setScrubWithTime:(double)time;
-(void)playOrResume;

-(void)setVideoConfigration;

- (void)configureGLKView;
- (void)removeGLKView;

@end

@protocol HTY360PlayerVCDelegate <NSObject>

@optional
-(void)didSelectFullScreenBtnWithHty360PlayerVC:(HTY360PlayerVC*)htyVc;
-(void)didSelectCloseBtnWithHty360PlayerVC:(HTY360PlayerVC*)htyVc;
-(void)didSelectCardBoardBtnWithSelected:(BOOL)selected hty360PlayerVc:(HTY360PlayerVC*)htyVc;

@end
