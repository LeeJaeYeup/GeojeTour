//
//  StampTourViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "StampTourViewController.h"
#import "StampListTableViewCell.h"
#import "StampTourDetailViewController.h"
#import "TheConnection.h"

#define kUrlGetStampListCount   [NSString stringWithFormat:@"%@/user/smartbeacon/push/stamplistcount.geoje?",BASE_URL]
#define kArrayOfStampMaximumCount   @[@"9",@"9",@"9",@"9",@"8",@"11",@"10",@"6"]


@interface StampTourViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIGestureRecognizerDelegate, TheConnectionDelegate>
{
    NSArray     *stampTourListTitleArray;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDictionary *stampListCountInfo;

//텍스트 라벨
@property (weak, nonatomic) IBOutlet UILabel *topTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *topLogoTitleLabel1;
@property (weak, nonatomic) IBOutlet UILabel *topLogoTitleLabel2;
@property (weak, nonatomic) IBOutlet UILabel *topLogoSubtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *upperStampGetGuideTextLabel;

@property (weak, nonatomic) IBOutlet UILabel *bottomStampTourHowToUseTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomStampTourHowToUseLabel1;
@property (weak, nonatomic) IBOutlet UILabel *bottomStampTourHowToUseLabel2;
@property (weak, nonatomic) IBOutlet UILabel *bottomStampTourHowToUseLabel3;
@property (weak, nonatomic) IBOutlet UILabel *bottomStampTourHowToUseLabel4;

@end

@implementation StampTourViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];
    stampTourListTitleArray = [languageInfoDic objectForKey:@"lk_stamptour_course_list_title_array"];

    //스탬프 리스트 로드
    [self loadstampList];
    
    //UI 텍스트 적용
    [self setAllUIText];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _scrollView.contentSize = CGSizeMake(0, 1180);
    
    if(_detailPageCateCd != nil)
    {
        NSString *cateCdNumberStr = [_detailPageCateCd substringFromIndex:1];
        [self pushViewControllerToDetailViewControllerWithIndex:[cateCdNumberStr integerValue] - 1];
        
        self.detailPageCateCd = nil;
    }
}

//스탬프리스트 불러오기
-(void)loadstampList
{
    NSString *url = [NSString stringWithFormat:@"%@uuid=%@",kUrlGetStampListCount,UTILITY.UUID];
//    NSLog(@"loadstampList url : %@",url);
    [self startConnectionWithURL:url
                             tag:0
                      identifier:nil];
}

#pragma mark - 뒤로가기 버튼

- (IBAction)pressedBackBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - private

//설정화면에 선택된 언어에 맞춰서 UI의 텍스트를 설정한다.
-(void)setAllUIText
{
    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];
    
    _topTitleLabel.text = [[languageInfoDic objectForKey:@"lk_intro_main_menu_text"] objectAtIndex:2];
    _topLogoTitleLabel1.text = [languageInfoDic objectForKey:@"lk_stamptour_top_logo_title1"];
    _topLogoTitleLabel2.text = [languageInfoDic objectForKey:@"lk_stamptour_top_logo_title2"];
    _topLogoSubtitleLabel.text = [languageInfoDic objectForKey:@"lk_stamptour_top_logo_subtitle"];

    _upperStampGetGuideTextLabel.text = [languageInfoDic objectForKey:@"lk_stamptour_upper_stamp_guide_text"];
    _bottomStampTourHowToUseTitleLabel.text = [languageInfoDic objectForKey:@"lk_stamptour_bottom_how_to_use_title"];
    
    
    NSArray *textLablesArr = @[_bottomStampTourHowToUseLabel1, _bottomStampTourHowToUseLabel2,
                               _bottomStampTourHowToUseLabel3, _bottomStampTourHowToUseLabel4];

    NSArray *howToUseBodyArr = [languageInfoDic objectForKey:@"lk_stamptour_bottom_how_to_use_body_array"];
    
    for(int i = 0; i < textLablesArr.count; i ++)
    {
        UILabel *mainMenuTextLabel = [textLablesArr objectAtIndex:i];
        mainMenuTextLabel.text = [howToUseBodyArr objectAtIndex:i];
    }
}

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

//선택한 스탬프투어 상세화면 보여주기
-(void)pushViewControllerToDetailViewControllerWithIndex:(NSInteger)index
{
    NSString *topBgImageName = [NSString stringWithFormat:@"stamp_sub_top_bg_0%ld",index + 1];
    NSString *title = [stampTourListTitleArray objectAtIndex:index];
    NSString *myStampCountDataKeyStr = [NSString stringWithFormat:@"cateA0%ldMY",index + 1];
    
    NSInteger currentCount = 0;
    NSString *regDate = @"N";
    
    if(_stampListCountInfo != nil)
    {
        currentCount = [[_stampListCountInfo objectForKey:myStampCountDataKeyStr] integerValue];
        regDate = [_stampListCountInfo objectForKey:[NSString stringWithFormat:@"cateA0%ld_REGDATE", index + 1]];
    }
    
    NSInteger maxCount = [[kArrayOfStampMaximumCount objectAtIndex:index] integerValue];
    NSInteger remainCount = maxCount - currentCount;
    NSString *cateCd = [NSString stringWithFormat:@"A0%ld",index + 1];
    
//    NSLog(@"스탬프투어 선물신청 regDate : %@",regDate);
    
    NSDictionary *contentsInfo = @{@"title" : title, @"image" : topBgImageName, @"remainCount" : [NSString stringWithFormat:@"%ld",remainCount], @"maxCount" :  [NSString stringWithFormat:@"%ld",maxCount], @"cateCd" : cateCd, @"regDate" : regDate};
    
    StampTourDetailViewController *pView = [[StampTourDetailViewController alloc] initWithNibName:@"StampTourDetailViewController" bundle:nil];
    [pView setContentsInfoDic:contentsInfo];
    [self.navigationController pushViewController:pView animated:YES];
}

#pragma mark - UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [stampTourListTitleArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellReuseKey = @"stampListCell";
    
    StampListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseKey];
    
    if(cell == nil)
    {
        [tableView registerNib:[UINib nibWithNibName:@"StampListTableViewCell" bundle:nil]
        forCellReuseIdentifier:cellReuseKey];
        cell = [tableView dequeueReusableCellWithIdentifier:cellReuseKey];
    }
    
    //셀 컨텐츠 내용 채우기....
    NSString *title = [stampTourListTitleArray objectAtIndex:indexPath.row];
    
    NSString *myStampCountDataKeyStr = [NSString stringWithFormat:@"cateA0%ldMY",indexPath.row + 1];
    
    NSInteger stampMaxCount = [[kArrayOfStampMaximumCount objectAtIndex:indexPath.row] integerValue];
    
    NSInteger currentStampCount = [[_stampListCountInfo objectForKey:myStampCountDataKeyStr] integerValue];
    
    BOOL stampCountMaxed = currentStampCount == stampMaxCount;
    
    NSString *count = [NSString stringWithFormat:@"%ld / %ld",currentStampCount, stampMaxCount];

    NSString *imageName = [NSString stringWithFormat:@"stamp_list_thumb_0%ld",indexPath.row + 1];
    
//    NSLog(@"imageName : %@",imageName);
    
    [cell setCellContentsWithImageName:imageName
                                 title:title
                         progressCount:count
                              maxCount:stampCountMaxed];
    
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

//스탬프투어 리스트 선택시...
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //상세화면으로 넘어감...
    [self pushViewControllerToDetailViewControllerWithIndex:indexPath.row];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
        //스탬프리스트 가져오기 결과값......
        self.stampListCountInfo = result;
        NSLog(@"stampListCountInfo : %@",self.stampListCountInfo);
        [_tableView reloadData];        
    }
}
@end
