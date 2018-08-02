//
//  VRPlayerView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 26..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "VRPlayerView.h"
#import "Video360ViewController.h"

@interface VRPlayerView () <HTY360PlayerVCDelegate>
{
    Video360ViewController  *videoController;
    BOOL                    bFullScreen;
    UITextView              *subTitleTextView;
}

@property (nonatomic, strong) NSURL *videoUrl;
@property (strong, nonatomic) IBOutlet UIView *controlUIView;
@property (weak, nonatomic) IBOutlet UIButton *playToggleBtn;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *volumeBtn;

@end

@implementation VRPlayerView

-(id)initWithFrame:(CGRect)frame url:(NSURL *)url
{
    if(self = [super initWithFrame:frame])
    {
//        NSLog(@"동영상 url : %@",url);
        
        self.videoUrl = url;
        bFullScreen = NO;
        self.backgroundColor = [UIColor whiteColor];

        videoController = [[Video360ViewController alloc] initWithNibName:@"HTY360PlayerVC"
                                                                   bundle:nil
                                                                      url:url];

        videoController.delegate = self;

        videoController.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height/3);
        [self addSubview:videoController.view];

        //비디오 재생 컨트롤 ui 추가
        [[NSBundle mainBundle] loadNibNamed:@"VRPlayerView_Control_UI" owner:self options:nil];
        _controlUIView.frame = CGRectMake(0, videoController.view.frame.origin.y + videoController.view.frame.size.height, videoController.view.frame.size.width, 40);
        [self addSubview:_controlUIView];

        [videoController setPlayToggleBtn:_playToggleBtn];
        [videoController setProgressSlider:_progressSlider];

        subTitleTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, _controlUIView.frame.origin.y + _controlUIView.frame.size.height + 5, frame.size.width - 20, frame.size.height - (videoController.view.frame.origin.y + videoController.view.frame.size.height + _controlUIView.bounds.size.height))];

        subTitleTextView.font = [UIFont systemFontOfSize:17];
        [subTitleTextView setEditable:NO];
        [self addSubview:subTitleTextView];


        [self bringSubviewToFront:videoController.view];
    }
    
    return self;
}

-(void)setSubTitleWithText:(NSString*)text
{
    subTitleTextView.text = text;
}

#pragma mark - button Event

//볼륨버튼 이벤트....
- (IBAction)pressedVolumeBtn:(id)sender
{
    BOOL isMuted = _volumeBtn.isSelected;
    BOOL setMuted = !isMuted;
    _volumeBtn.selected = setMuted;
    [videoController setMute:setMuted];
}

#pragma mark - HTY360PlayerVC Delegate

//풀스크린 선택했을때...
-(void)didSelectFullScreenBtnWithHty360PlayerVC:(HTY360PlayerVC*)htyVc
{
    double lastPlayedTimeSec = [htyVc currentPlayTime];
//    NSLog(@"lastPlayedTimeSec : %lf",lastPlayedTimeSec);

    if(bFullScreen)
    {
        Video360ViewController *newVideoController = [[Video360ViewController alloc] initWithNibName:@"HTY360PlayerVC"
                                                                                              bundle:nil
                                                                                                 url:self.videoUrl];

        newVideoController.view.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/3);
        [self addSubview:newVideoController.view];
        [newVideoController setPlayToggleBtn:_playToggleBtn];
        [newVideoController setProgressSlider:_progressSlider];

        [htyVc dismissViewControllerAnimated:YES completion:^()
         {
             newVideoController.delegate = self;
             [newVideoController setScrubWithTime:lastPlayedTimeSec];
             videoController = newVideoController;
         }];
    }
    else
    {
        UIViewController *currentViewController = [[UTILITY.rootViewControllerPtr.navigationController viewControllers] lastObject];

        if (![[currentViewController presentedViewController] isBeingDismissed])
        {
            [currentViewController presentViewController:htyVc animated:YES completion:^()
             {
                 [htyVc setScrubWithTime:lastPlayedTimeSec];
             }];
        }
    }

    videoController = (Video360ViewController*)htyVc;
    bFullScreen = !bFullScreen;
}

//카드보드 버튼 선택했을때...
-(void)didSelectCardBoardBtnWithSelected:(BOOL)selected hty360PlayerVc:(HTY360PlayerVC *)htyVc
{
    Video360ViewController *video360Player = (Video360ViewController*)htyVc;
//    [video360Player transformCardBoardView:!selected];
    
    double lastPlayedTimeSec = [htyVc currentPlayTime];
    
    if(selected == NO)
    {
        //전체화면이 아니면 전체화면 전환 후 카드보드 뷰로 변환한다...
        if(bFullScreen == NO)
        {
            UIViewController *currentViewController = [[UTILITY.rootViewControllerPtr.navigationController viewControllers] lastObject];
            
            if (![[currentViewController presentedViewController] isBeingDismissed])
            {
                [currentViewController presentViewController:htyVc animated:YES completion:^()
                 {
                     [video360Player setScrubWithTime:lastPlayedTimeSec];
                     [video360Player transformCardBoardView:YES];
                 }];
            }
            
            bFullScreen = !bFullScreen;
        }
        else
            [video360Player transformCardBoardView:YES];
    }
    else
    {
        [video360Player transformCardBoardView:NO];
    }

}

@end
