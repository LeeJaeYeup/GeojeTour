//
//  CouponBookView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 15..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "CouponBookView.h"
#import "CouponCollectionCell.h"
#import "TheConnection.h"

#define kCouponCollectionViewCellKey        @"couponCollectionCell"
#define kUrlGetCouponList                   [NSString stringWithFormat:@"%@/user/smartbeacon/push/couponlist.geoje?",BASE_URL]


@interface CouponBookView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TheConnectionDelegate, CouponCollectionCellDelegate>
@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (weak, nonatomic) IBOutlet UICollectionView *couponCollectionView;
@property (strong, nonatomic) NSMutableArray *couponListArray;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentsViewHeight;

//텍스트라벨들...
@property (weak, nonatomic) IBOutlet UILabel *topLogoTitle01Label;
@property (weak, nonatomic) IBOutlet UILabel *topLogoTitle02Label;
@property (weak, nonatomic) IBOutlet UILabel *topLogoSubTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *howToGetCouponTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *howToGetCouponMainTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *howToUseTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *howToUseMainTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *howToUseCautionLabel;
@property (weak, nonatomic) IBOutlet UILabel *myCouponListTitleLabel;

@end

@implementation CouponBookView

-(instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"CouponBookView" owner:self options:nil];
        [_mainXibView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_mainXibView];
        
        _couponListArray = [[NSMutableArray alloc] init];

        [self.couponCollectionView registerNib:[UINib nibWithNibName:@"CouponCollectionCell" bundle:nil]
                    forCellWithReuseIdentifier:kCouponCollectionViewCellKey];
        
        [self setAllUIText];
        [self loadCouponList];

    }
    
    return self;
}

-(void)loadCouponList
{
    //쿠폰리스트 얻어오기..
    NSString *url = [NSString stringWithFormat:@"%@uuid=%@",kUrlGetCouponList,[UTILITY UUID]];
    
//    NSLog(@"쿠폰리스트 url : %@",url);
    
    [self startConnectionWithURL:url
                             tag:0
                      identifier:nil];
}

#pragma mark - private

//설정화면에 선택된 언어에 맞춰서 UI의 텍스트를 설정한다.
-(void)setAllUIText
{
    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];

    _topLogoTitle01Label.text = [languageInfoDic objectForKey:@"lk_coupon_top_logo_title01"];
    _topLogoTitle02Label.text = [languageInfoDic objectForKey:@"lk_coupon_top_logo_title02"];
    _topLogoSubTitleLabel.text = [languageInfoDic objectForKey:@"lk_coupon_top_logo_subtitle"];
    
    _howToGetCouponTitleLabel.text = [languageInfoDic objectForKey:@"lk_coupon_how_to_get_title"];
    _howToGetCouponMainTextLabel.text = [languageInfoDic objectForKey:@"lk_coupon_how_to_get_main_text"];
    
    _howToUseTitleLabel.text = [languageInfoDic objectForKey:@"lk_coupon_how_to_use_title"];
    _howToUseMainTextLabel.text = [languageInfoDic objectForKey:@"lk_coupon_how_to_use_main_text"];
    _howToUseCautionLabel.text = [languageInfoDic objectForKey:@"lk_coupon_how_to_use_caution_text"];
    
    _myCouponListTitleLabel.text = [languageInfoDic objectForKey:@"lk_coupon_my_coupon_list_title"];
}

-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

#pragma mark - UICollectionView Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.couponListArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 재사용 큐에 셀을 가져온다
    CouponCollectionCell* cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:kCouponCollectionViewCellKey
                                              forIndexPath:indexPath];
    cell.delegate = self;

    [cell setCouponInfo:[_couponListArray objectAtIndex:indexPath.section]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"indexPath : %ld, %ld",indexPath.section, indexPath.row);

    NSString *linkPageUrl = [NSString stringWithFormat:@"http://www.geoje.go.kr%@",[[_couponListArray objectAtIndex:indexPath.section] objectForKey:@"page_link"]];

    [UTILITY.rootViewControllerPtr showWebViewWithUrl:linkPageUrl];
}

#pragma mark - UICollectionViewDelegateFlowLayout

//콜렉션 cell 사이즈 결정
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = self.couponCollectionView.bounds.size.width - 10;
    CGFloat height = self.couponCollectionView.bounds.size.width/2 * 0.9f;

    return CGSizeMake(width, height);
}

//spacing
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
        [_couponListArray setArray:[result objectForKey:@"CouponListData"]];
        NSLog(@"self.couponListArray : %@",self.couponListArray);
        
        if(self.couponListArray.count > 0)
        {
            //스크롤 가능영역 설정하기..
            CGFloat height = self.couponCollectionView.bounds.size.width/2 * 0.9f;
            CGFloat couponListHeight = height * self.couponListArray.count;
            CGFloat lineSpaceHeight = self.couponListArray.count * 10.f;
            
//            NSLog(@"couponListHeight : %lf",couponListHeight);
            
            CGFloat contentsHeight = 120 + 270 + 45 + couponListHeight + lineSpaceHeight;
            if(contentsHeight + 80 < [[UIScreen mainScreen] bounds].size.height)
                contentsHeight = [[UIScreen mainScreen] bounds].size.height - 80;
            
            [_scrollContentsViewHeight setConstant:contentsHeight];
            [_scrollView setContentSize:CGSizeMake(0, _scrollContentsViewHeight.constant)];

            [self.couponCollectionView reloadData];
        }
    }
}

#pragma mark - 할인쿠폰 리스트 보기

- (IBAction)pressedCouponListBtn:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"%@/user/coupon/list.geoje?menuCd=DOM_000008511001000000",BASE_URL];
    [UTILITY.rootViewControllerPtr showWebViewWithUrl:url];
}

#pragma mark - CouponCollectionCell Delegate

-(void)couponCollectionCell:(CouponCollectionCell*)cell didFinishCouponUseWithResult:(id)result couponDataInfo:(NSDictionary*)couponDataInfo
{
    NSLog(@"_couponListArray : %@",_couponListArray);
//    NSLog(@"사용하기된 쿠폰 정보 : %@",couponDataInfo);
    
    NSString *basicSidOfUsed = [[couponDataInfo objectForKey:@"basicSid"] stringValue];
    
//    여기서 사용한 쿠폰을 couponListArray에서 삭제해야함!!
    for(int i = 0; i < _couponListArray.count; i ++)
    {
        NSString *basicSidOfList = [[[_couponListArray objectAtIndex:i] objectForKey:@"basicSid"] stringValue];
        
        if([basicSidOfList isEqualToString:basicSidOfUsed])
        {
            [_couponListArray removeObjectAtIndex:i];
            break;
        }
    }
    
    //쿠폰 리스트 새로고침.
    [self.couponCollectionView reloadData];

    //사용된 쿠폰임을 db에 저장하기
    NSString *targetBeaconFullPathLink = [NSString stringWithFormat:@"http://www.geoje.go.kr/beaconsmart/view.geoje?basicSid=%@",basicSidOfUsed];
    
    NSString *couponUseDate = [UTILITY currentDateWithDateFormat:nil];
    
    [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface] updateWithTableName:kTableNameDetectedBeaconHistory values:@{@"couponUseYN" : @"Y", @"couponUseDate" : couponUseDate} where:[NSString stringWithFormat:@"where beaconFullPathLink = '%@' and groupSid = '%@'",targetBeaconFullPathLink, kCouponGroupSid]];
}

@end
