//
//  BeaconFindNotiView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 2. 13..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "BeaconFindNotiView.h"
#import "MarqueeLabel.h"

@interface BeaconFindNotiView ()

@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (weak, nonatomic) IBOutlet MarqueeLabel *beaconNotiTitleLabel;
@property (strong, nonatomic) NSDictionary *currentShowingNotiInfo;

@end

@implementation BeaconFindNotiView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"BeaconFindNotiView" owner:self options:nil];
        self.mainXibView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self addSubview:_mainXibView];
        self.layer.cornerRadius = 15.0f;
        self.alpha = 0.f;
        self.clipsToBounds = YES;
    }
    
    return self;
}

//팝업창 보여주기
-(void)setVisibleWithInfo:(NSDictionary*)info onView:(UIView*)view
{
    BOOL isContentsBeacon = [[info objectForKey:@"isContentsBeaconYN"] isEqualToString:@"Y"];
    NSDictionary *beaconContentsInfo = [info objectForKey:@"beaconInfo"];
    
    self.currentShowingNotiInfo = beaconContentsInfo;
    
    if(isContentsBeacon)
    {
        _beaconNotiTitleLabel.text = [NSString stringWithFormat:@"%@\n새로운 컨텐츠가 발견 되었습니다.",[beaconContentsInfo objectForKey:@"beaconTitle"]];
    }
    else
    {
        _beaconNotiTitleLabel.text = [beaconContentsInfo objectForKey:@"msg"];
    }
    
    [self removeFromSuperview];
    [view addSubview:self];
    
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:1.f
                            completion:nil];
}

//팝업창 숨기기
-(void)setInvisible
{
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:0.f
                            completion:^(BOOL finished)
     {
        if([self.delegate respondsToSelector:@selector(beaconFindNotiView:didFinishInvisibleWithInfo:)])
            [self.delegate beaconFindNotiView:self didFinishInvisibleWithInfo:self.currentShowingNotiInfo];
     }];
}

-(NSDictionary*)currentShowingNotiInfo
{
    return _currentShowingNotiInfo;
}

-(NSString*)currentShowTitle
{
    return _beaconNotiTitleLabel.text;
}

#pragma mark - 버튼이벤트

//닫기버튼 
- (IBAction)pressedBeaconNotiCloseBtn:(id)sender
{
    if([self.delegate respondsToSelector:@selector(didSelectCloseBtnWithBeaconFindNotiView:)])
        [self.delegate didSelectCloseBtnWithBeaconFindNotiView:self];
}

//뷰 바디버튼
- (IBAction)pressedSelectNotiView:(id)sender
{
    if([self.delegate respondsToSelector:@selector(didSelectNotiViewBodyWithBeaconFindNotiView:)])
        [self.delegate didSelectNotiViewBodyWithBeaconFindNotiView:self];
}

@end
