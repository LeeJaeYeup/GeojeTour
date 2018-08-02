//
//  VRListView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 20..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "VRListView.h"
#import "HTY360PlayerVC.h"
#import "TheConnection.h"
#import "SelectMenuViewController.h"
#import "CommunityViewController.h"

@interface NSLayoutConstraint (Multiplier)
-(instancetype)updateMultiplier:(CGFloat)multiplier;
@end

@implementation NSLayoutConstraint (Multiplier)
-(instancetype)updateMultiplier:(CGFloat)multiplier
{
    [NSLayoutConstraint deactivateConstraints:[NSArray arrayWithObjects:self, nil]];
    
    NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:self.firstItem attribute:self.firstAttribute relatedBy:self.relation toItem:self.secondItem attribute:self.secondAttribute multiplier:multiplier constant:self.constant];
    [newConstraint setPriority:self.priority];
    newConstraint.shouldBeArchived = self.shouldBeArchived;
    newConstraint.identifier = self.identifier;
    newConstraint.active = true;
    
    [NSLayoutConstraint activateConstraints:@[newConstraint]];
    return newConstraint;
}
@end

@interface VRListView () <TheConnectionDelegate>

@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (nonatomic, strong) NSDictionary *vrLinkInfoDic;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *listMenuWidthConstraints;
@property (nonatomic, strong) NSArray *vrTitleArray;

//텍스트 라벨
@property (weak, nonatomic) IBOutlet UILabel *logoTitleLabel1;
@property (weak, nonatomic) IBOutlet UILabel *logoTitleLabel2;
@property (weak, nonatomic) IBOutlet UILabel *logoSubtitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel01;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel02;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel03;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel04;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel05;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel06;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel07;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel08;
@property (weak, nonatomic) IBOutlet UILabel *vrTitleLabel09;

@end

@implementation VRListView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"VRListView" owner:self options:nil];
        [_mainXibView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_mainXibView];
        
        //3.5인치 화면이면 리스트 박스 크기를 조금 줄인다..
        if([UTILITY screenType] == ScreenType_3_5)
        {
            self.listMenuWidthConstraints = [self.listMenuWidthConstraints updateMultiplier:0.7f];
        }
        
        [self setAllUIText];
        
        [self loadVRLinkDataFromServer];
    }
    
    return self;
}

#pragma mark - private

//설정화면에 선택된 언어에 맞춰서 UI의 텍스트를 설정한다.
-(void)setAllUIText
{
    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];
    
    _logoTitleLabel1.text = [languageInfoDic objectForKey:@"lk_360vr_logo_title1"];
    _logoTitleLabel2.text = [languageInfoDic objectForKey:@"lk_360vr_logo_title2"];
    _logoSubtitleLabel.text = [languageInfoDic objectForKey:@"lk_360vr_logo_subtitle"];
    
    NSArray *textLablesArr = @[_vrTitleLabel01, _vrTitleLabel02, _vrTitleLabel03,
                               _vrTitleLabel04, _vrTitleLabel05, _vrTitleLabel06,
                               _vrTitleLabel07, _vrTitleLabel08, _vrTitleLabel09];
    
    self.vrTitleArray = [languageInfoDic objectForKey:@"lk_360vr_video_menu"];

    for(int i = 0; i < textLablesArr.count; i ++)
    {
        UILabel *mainMenuTextLabel = [textLablesArr objectAtIndex:i];
        mainMenuTextLabel.text = [_vrTitleArray objectAtIndex:i];
    }
}

//영상 경로데이터를 받아온다..
-(void)loadVRLinkDataFromServer
{
    NSString *getVrLinkUrl = @"http://www.geoje.go.kr/html/vr.jsp";
    
    TheConnection *connection = [[TheConnection alloc] init];
    connection.delegate = self;
    [connection startConnectionWithUrl:getVrLinkUrl
                              delegate:self
                             queueName:nil];
}

#pragma mark - Button Event

//vr영상 재생리스트 선택시....
- (IBAction)pressedVrListBtns:(id)sender
{
    if(self.vrLinkInfoDic == nil)
    {
        [UTILITY showToastWithText:@"영상 목록을 가져오는 중입니다. 잠시 후 다시 시도해 주세요."
                          duration:5.f];
        return;
    }
    
    UIButton *btn = sender;
    NSInteger btnTag = btn.tag;
    
    if([self.delegate respondsToSelector:@selector(didSelectListWithTitle:)])
    {
//        NSArray *videoTitleArr = @[@"자전거 체험",@"페러글라이딩 체험",@"오토바이 체험",@"드론 체험",@"낙하산 체험",@"자동차 체험",@"도보 체험",@"승마 체험",@"등산 체험"];
//        NSString *selectVideoTitle = videoTitleArr[btnTag];
        
        NSString *selectVideoTitle = _vrTitleArray[btnTag];
        [self.delegate didSelectListWithTitle:selectVideoTitle];
    }
    
    NSString *vrDataLinkKey = [NSString stringWithFormat:@"vr%ld",btnTag + 1];
    NSString *vrUrl = [self.vrLinkInfoDic objectForKey:vrDataLinkKey];
    
//    NSLog(@"vr 동영상 url : %@",vrUrl);
    
//    NSString *path = @"http://2bagu-www.skoinfo.co.kr/a.mp4";
//    NSString *path = @"http://geoje.go.kr/html/vr_file/05_Bike 6_12_full.mp4";
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[vrUrl stringByRemovingPercentEncoding]];
    
    _vrPlayerView = [[VRPlayerView alloc] initWithFrame:CGRectMake(0, 0, _mainXibView.frame.size.width, (_mainXibView.frame.origin.y + _mainXibView.frame.size.height) - 0)
                                                   url:url];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"vrVideoSubTitleInfo" ofType:@"plist"];
    NSArray *vrVideoSubTitleList = [[NSDictionary dictionaryWithContentsOfFile:filePath] objectForKey:@"InfoArr"];
    
    [_vrPlayerView setSubTitleWithText:[vrVideoSubTitleList objectAtIndex:btnTag]];
    [self addSubview:_vrPlayerView];
}

//이용후기 버튼
- (IBAction)pressedReviewBtn:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"%@/board/list.geoje?boardId=BBS_0000541&menuCd=DOM_000008513002000000&contentsSid=8446&cpath=",BASE_URL];
    
    CommunityViewController *commViewController = [[CommunityViewController alloc]
                                                   initWithNibName:@"CommunityViewController"
                                                   bundle:nil];
    commViewController.webViewUrl = url;
    [UTILITY.rootViewControllerPtr.navigationController pushViewController:commViewController animated:YES];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
//        NSLog(@"vr list result : %@",result);
        self.vrLinkInfoDic = result;
    }
    else
    {
        //통신 실패시 5초마다 재시도 하기...
        [self performSelector:@selector(loadVRLinkDataFromServer) withObject:nil afterDelay:10.f];
    }
}

@end
