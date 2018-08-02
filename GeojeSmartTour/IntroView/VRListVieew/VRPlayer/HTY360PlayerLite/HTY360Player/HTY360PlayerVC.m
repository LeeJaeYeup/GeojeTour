//
//  HTY360PlayerVC.m
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import "HTY360PlayerVC.h"
#import "HTYGLKVC.h"

#define ONE_FRAME_DURATION 0.03f
#define HIDE_CONTROL_DELAY 5.f
#define DEFAULT_VIEW_ALPHA 0.6f

NSString * const kTracksKey = @"tracks";
NSString * const kPlayableKey = @"playable";
NSString * const kRateKey = @"rate";
NSString * const kCurrentItemKey = @"currentItem";
NSString * const kStatusKey = @"status";

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface HTY360PlayerVC ()
{
    HTYGLKVC *_glkViewController;
    AVPlayerItemVideoOutput* _videoOutput;
    AVPlayer* _player;
    AVPlayerItem* _playerItem;
    dispatch_queue_t _myVideoOutputQueue;
    id _notificationToken;
    id _timeObserver;
    
    float mRestoreAfterScrubbingRate;
    BOOL seekToZeroBeforePlay;
    
    int _bufferNilCount;
}

@property (weak, nonatomic) IBOutlet UIView *iconsBackView;
@property (weak, nonatomic) IBOutlet UIButton *cardboardBtn;
@end

@implementation HTY360PlayerVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.videoURL = url;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [self setVideoConfigration];
    
    
#if SHOW_DEBUG_LABEL
    self.debugView.hidden = NO;
#endif
    
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self pause];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updatePlayButton];
    [_player seekToTime:[_player currentTime]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [self setPlayToggleBtn:nil];
    [self setProgressSlider:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    @try {
        [self removePlayerTimeObserver];
        [_playerItem removeObserver:self forKeyPath:kStatusKey];
        [_playerItem removeOutput:_videoOutput];
        [_player removeObserver:self forKeyPath:kCurrentItemKey];
        [_player removeObserver:self forKeyPath:kRateKey];
    } @catch(id anException) {
        //do nothing
    }
    
    _videoOutput = nil;
    _playerItem = nil;
    _player = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updatePlayButton];
}

#pragma mark - public

-(void)playOrResume
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if ([self isPlaying])
    {
        [self pause];
    }
    else
    {
        [self play];
    }
}

-(void)setScrubWithTime:(double)time
{
    _currentPlayTime = time;
    [_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSLog(@"setScrubWithTime : %lf",time);
    NSLog(@"isplaying : %d",[self isPlaying]);
    [self play];
}

-(UIView*)getIconsBackView
{
    return _iconsBackView;
}

-(void)setVideoConfigration
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self setupVideoPlaybackForURL:_videoURL];
    [self configureGLKView];
}

-(AVPlayer*)player
{
    return _player;
}

-(void)setPlayToggleBtn:(UIButton *)playToggleBtn
{
    _playToggleBtn = playToggleBtn;
    [_playToggleBtn addTarget:self action:@selector(playButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    
    [self configurePlayButton];
}

-(void)setProgressSlider:(UISlider *)progressSlider
{
    _progressSlider = progressSlider;
    [self configureProgressSlider];
    
    [_progressSlider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [_progressSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [_progressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
}

-(void)setMute:(BOOL)bMute
{
    CGFloat volume = 1.f;
    
    if(bMute)
        volume = 0.f;
    
    [_player setVolume:volume];
    
}

#pragma mark - video communication

//- (CVPixelBufferRef)retrievePixelBufferToDraw
//{
//    CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:[_playerItem currentTime] itemTimeForDisplay:nil];
//    return pixelBuffer;
//}

- (CVPixelBufferRef)retrievePixelBufferToDraw {
    CMTime cmtime = [_playerItem currentTime];
    CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:cmtime itemTimeForDisplay:nil];

    if (cmtime.value > 0 && pixelBuffer == NULL)
    {
        _bufferNilCount++;
        if (_bufferNilCount > 100) {
            __weak typeof(self) weakSelf = self;
            dispatch_async( dispatch_get_main_queue(),
                           ^{
                               if (!weakSelf) {
                                   return;
                               }

                               NSLog(@"reset player");

                               HTY360PlayerVC *strongSelf = weakSelf;

                               [strongSelf->_playerItem removeOutput:strongSelf->_videoOutput];
                               strongSelf->_videoOutput = nil;

                               NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
                               strongSelf->_videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
                               //                               [strongSelf->_videoOutput setDelegate:self queue:strongSelf->_myVideoOutputQueue];

                               [strongSelf->_playerItem addOutput:strongSelf->_videoOutput];
                               [strongSelf->_player replaceCurrentItemWithPlayerItem:strongSelf->_playerItem];
                               [strongSelf->_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];

                               strongSelf->_bufferNilCount = 0;
                           });
        }
    }
    return pixelBuffer;
}

#pragma mark - video setting

- (void)setupVideoPlaybackForURL:(NSURL*)url
{
    NSDictionary *pixelBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffAttributes];
    _myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    //    [_videoOutput setDelegate:self queue:_myVideoOutputQueue];
    
    _player = [[AVPlayer alloc] init];
    
    // Do not take mute button into account
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                          error:&error];
    if (!success) {
        NSLog(@"Could not use AVAudioSessionCategoryPlayback", nil);
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[[asset URL] path]]) {
        NSLog(@"file does not exist");
    }
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        
        dispatch_async( dispatch_get_main_queue(),
                       ^{
                           /* Make sure that the value of each key has loaded successfully. */
                           for (NSString *thisKey in requestedKeys) {
                               NSError *error = nil;
                               AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
                               if (keyStatus == AVKeyValueStatusFailed) {
                                   [self assetFailedToPrepareForPlayback:error];
                                   return;
                               }
                           }
                           
                           NSError* error = nil;
                           AVKeyValueStatus status = [asset statusOfValueForKey:kTracksKey error:&error];
                           if (status == AVKeyValueStatusLoaded) {
                               _playerItem = [AVPlayerItem playerItemWithAsset:asset];
                               
                               if(_videoOutput != nil)
                                   [_playerItem addOutput:_videoOutput];
                               
                               [_player replaceCurrentItemWithPlayerItem:_playerItem];
                               [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
                               
                               /* When the player item has played to its end time we'll toggle
                                the movie controller Pause button to be the Play button */
                               [[NSNotificationCenter defaultCenter] addObserver:self
                                                                        selector:@selector(playerItemDidReachEnd:)
                                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                                          object:_playerItem];
                               seekToZeroBeforePlay = NO;
                               
                               [_playerItem addObserver:self
                                             forKeyPath:kStatusKey
                                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
                               
                               [_player addObserver:self
                                         forKeyPath:kCurrentItemKey
                                            options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                            context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
                               
                               [_player addObserver:self
                                         forKeyPath:kRateKey
                                            options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                            context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
                               
                               
                               [self initScrubberTimer];
                               [self syncScrubber];
                           }
                           else {
                               NSLog(@"%@ Failed to load the tracks.", self);
                           }
                       });
    }];
}

#pragma mark - rendering glk view management

- (void)configureGLKView
{
    _glkViewController = [[HTYGLKVC alloc] init];
    _glkViewController.videoPlayerController = self;
    
    [self.view insertSubview:_glkViewController.view belowSubview:_iconsBackView];
    
    [self addChildViewController:_glkViewController];
    [_glkViewController didMoveToParentViewController:self];
    
    _glkViewController.view.frame = self.view.bounds;
}

- (void)removeGLKView
{
    _glkViewController.videoPlayerController = nil;
    [_glkViewController.view removeFromSuperview];
    [_glkViewController removeFromParentViewController];
    _glkViewController = nil;
}

#pragma mark - play button management

- (void)configurePlayButton
{
    _playToggleBtn.backgroundColor = [UIColor clearColor];
    _playToggleBtn.showsTouchWhenHighlighted = YES;
    
    [self disablePlayerButtons];
    [self updatePlayButton];
}

- (IBAction)playButtonTouched:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ([self isPlaying]) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)updatePlayButton
{
    [_playToggleBtn setImage:[UIImage imageNamed:[self isPlaying] ? @"btn_pauseVideo" : @"btn_playVideo"]
                    forState:UIControlStateNormal];
}

- (void)play
{
    if ([self isPlaying])
        return;
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
    if (YES == seekToZeroBeforePlay) {
        seekToZeroBeforePlay = NO;
        [_player seekToTime:kCMTimeZero];
    }
    
    [self updatePlayButton];
    [_player play];
}

- (void)pause
{
    if (![self isPlaying])
        return;
    
    [self updatePlayButton];
    [_player pause];
}

#pragma mark - progress slider management

- (void)configureProgressSlider
{
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
    
    [_progressSlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateNormal];
    [_progressSlider setThumbImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateHighlighted];
}


#pragma mark - controls management

- (void)enablePlayerButtons
{
    _playToggleBtn.enabled = YES;
}

- (void)disablePlayerButtons
{
    _playToggleBtn.enabled = NO;
}

- (void)removeTimeObserverForPlayer {
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

#pragma mark - slider progress management

- (void)initScrubberTimer
{
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([_progressSlider bounds]);
        interval = 0.5f * duration / width;
    }
    
    __weak HTY360PlayerVC* weakSelf = self;
    __weak AVPlayer* weakPlayer = _player;
    
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                     /* If you pass NULL, the main queue is used. */
                                                          queue:NULL
                                                     usingBlock:^(CMTime time) {
                                                         [weakSelf syncScrubber];
                                                         CMTime currTime = [weakPlayer currentTime];
                                                         _currentPlayTime = CMTimeGetSeconds(currTime);
                                                         //                                                         NSLog(@"현재 재생시간1 : %lf",timeSec);
                                                         
                                                     }];
    
}

- (CMTime)playerItemDuration
{
    if (_playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
        return ([_playerItem duration]);
    }
    
    return (kCMTimeInvalid);
}

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        _progressSlider.minimumValue = 0.f;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [_progressSlider minimumValue];
        float maxValue = [_progressSlider maximumValue];
        double time = CMTimeGetSeconds([_player currentTime]);
        
        [_progressSlider setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)beginScrubbing:(id)sender
{
    mRestoreAfterScrubbingRate = [_player rate];
    [_player setRate:0.f];
    
    /* Remove previous timer. */
    [self removeTimeObserverForPlayer];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender {
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            _currentPlayTime = time;
            [_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
            NSLog(@"시크바 time : %lf",time);
        }
    }
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing:(id)sender
{
    if (!_timeObserver)
    {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            CGFloat width = CGRectGetWidth([_progressSlider bounds]);
            double tolerance = 0.5f * duration / width;
            
            __weak HTY360PlayerVC* weakSelf = self;
            __weak AVPlayer* weakPlayer = _player;
            
            _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                                                                  queue:NULL
                                                             usingBlock:^(CMTime time) {
                                                                 [weakSelf syncScrubber];
                                                                 CMTime currTime = [weakPlayer currentTime];
                                                                 _currentPlayTime =  CMTimeGetSeconds(currTime);
                                                                 //                                                                 NSLog(@"endScrubbing : %lf",_currentPlayTime);
                                                                 
                                                             }];
        }
    }
    
    if (mRestoreAfterScrubbingRate)
    {
        [_player setRate:mRestoreAfterScrubbingRate];
        mRestoreAfterScrubbingRate = 0.f;
    }
}

- (BOOL)isScrubbing {
    return mRestoreAfterScrubbingRate != 0.f;
}

- (void)enableScrubber {
    _progressSlider.enabled = YES;
}

- (void)disableScrubber {
    _progressSlider.enabled = NO;
}

- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    /* AVPlayerItem "status" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext) {
        [self updatePlayButton];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown: {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                [self disableScrubber];
                [self disablePlayerButtons];
                break;
            }
            case AVPlayerStatusReadyToPlay: {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                [self initScrubberTimer];
                [self enableScrubber];
                [self enablePlayerButtons];
                break;
            }
            case AVPlayerStatusFailed: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
                NSLog(@"Error fail : %@", playerItem.error);
                break;
            }
        }
    } else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext) {
        [self updatePlayButton];
        // NSLog(@"AVPlayerDemoPlaybackViewControllerRateObservationContext");
    } else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext) {
        /* AVPlayer "currentItem" property observer.
         Called when the AVPlayer replaceCurrentItemWithPlayerItem:
         replacement will/did occur. */
        
        //NSLog(@"AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext");
    } else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:[error localizedDescription]
                                          message:[error localizedFailureReason]
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK action");
                               }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)isPlaying {
    return mRestoreAfterScrubbingRate != 0.f || [_player rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    /* After the movie has played to its end time, seek back to time zero
     to play it again. */
    seekToZeroBeforePlay = YES;
}

#pragma mark - full Size Button

- (IBAction)fullSize:(id)sender
{
    if([self.delegate respondsToSelector:@selector(didSelectFullScreenBtnWithHty360PlayerVC:)])
        [self.delegate didSelectFullScreenBtnWithHty360PlayerVC:self];
}

#pragma mark - cardboard Button

- (IBAction)pressedCardboardBtn:(id)sender
{
    NSLog(@"카드보드 버튼 눌려짐");
    if([self.delegate respondsToSelector:@selector(didSelectCardBoardBtnWithSelected:hty360PlayerVc:)])
        [self.delegate didSelectCardBoardBtnWithSelected:_cardboardBtn.isSelected hty360PlayerVc:self];
    
    _cardboardBtn.selected = !_cardboardBtn.isSelected;
}

#pragma mark -

-(void)transformCardBoardView:(BOOL)bTransform{};

/* Cancels the previously registered time observer. */
- (void)removePlayerTimeObserver
{
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}


@end
