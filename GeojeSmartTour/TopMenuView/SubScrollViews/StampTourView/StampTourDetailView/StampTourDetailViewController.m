//
//  StampTourDetailViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "StampTourDetailViewController.h"
#import "StampCollectionViewCell.h"
#import "GiftApplicationViewController.h"
#import "TheConnection.h"
#import "TopLogoView.h"

#define kCollectionViewCellKey          @"collectionViewCellKey"
#define kUrlGetStampDetailList          [NSString stringWithFormat:@"%@/user/smartbeacon/push/stampchklist.geoje?",BASE_URL]


@interface StampTourDetailViewController ()
<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TheConnectionDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *plzGiftBtn;
@property (weak, nonatomic) IBOutlet UIView *giftRegDateView;
@property (weak, nonatomic) IBOutlet UILabel *giftRegDateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *stampDetailListArray;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewTopSpaceConstraint;

@end

@implementation StampTourDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setContensInfo:_contentsInfoDic];
    [self.collectionView registerNib:[UINib nibWithNibName:@"StampCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:kCollectionViewCellKey];
    [self loadStampData];
    
    TopLogoView *topLogoView = [[UTILITY objectSaveDictionary] objectForKey:@"TopLogoView"];
    [topLogoView showBackBtnView:YES action:@selector(pressedTopBackBtn) target:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    TopLogoView *topLogoView = [[UTILITY objectSaveDictionary] objectForKey:@"TopLogoView"];
    [topLogoView showBackBtnView:NO action:@selector(pressedTopBackBtn) target:self];
}

-(void)setContensInfo:(NSDictionary*)info
{
    NSString *title = [info objectForKey:@"title"];
    NSString *imageName = [info objectForKey:@"image"];
    NSString *maxCount = [info objectForKey:@"maxCount"];
    NSString *remainCount = [info objectForKey:@"remainCount"];
    
    NSString *subTitle = [NSString stringWithFormat:@"거제사랑상품권 투어완료까지 %@개중 %@개 남았습니다.",maxCount, remainCount];
    
    self.titleLabel.text = title;
    self.topImageView.image = [UIImage imageNamed:imageName];
    
//    NSLog(@"info12345 : %@",info);
    
    UIColor *progressCountTextColor = [UIColor yellowColor];
    UIColor *normalTextColor = [UIColor whiteColor];
    NSDictionary *attrs = @{NSForegroundColorAttributeName : progressCountTextColor};
    NSDictionary *attrs2 = @{NSForegroundColorAttributeName : normalTextColor};
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:subTitle];
    [attString addAttributes:attrs2 range:NSMakeRange(0, [subTitle length])];
    [attString addAttributes:attrs range:NSMakeRange(15, maxCount.length + remainCount.length + 4)];
    
    self.subTitleLabel.attributedText = attString;
    
    //선물하기가 신청된 스탬프투어 일때
    if([[info objectForKey:@"regDate"] isEqualToString:@"N"] == NO)
    {
        [_collectionViewTopSpaceConstraint setConstant:50.f];
        _giftRegDateView.hidden = NO;
        _giftRegDateLabel.text = [NSString stringWithFormat:@"%@ 선물 신청하기가 완료 되었습니다.", [info objectForKey:@"regDate"]];
    }
}

-(void)loadStampData
{
    [self getStampDetailListWithInfo:_contentsInfoDic];
}

#pragma mark -

- (IBAction)pressedBackBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - private

-(NSInteger)sectionCount
{
    NSInteger stampListCount = _stampDetailListArray.count;
    
    if(stampListCount == 0)         return 0;
    else if(stampListCount <= 2)    return 1;
    
    NSInteger halfCount = stampListCount / 2;
    NSInteger remainder = stampListCount % 2;
    return halfCount + remainder;
}

-(void)getStampDetailListWithInfo:(NSDictionary*)info
{
    NSString *cateCd = [info objectForKey:@"cateCd"];
    NSString *uuid = [UTILITY UUID];
    
    NSString *url = [NSString stringWithFormat:@"%@cateCd1=%@&uuid=%@",kUrlGetStampDetailList,cateCd,uuid];
    
//    NSLog(@"스템프 디테일 리스트 url : %@",url);
    
    [self startConnectionWithURL:url
                             tag:0
                      identifier:nil];
}

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

#pragma mark - Button Event

- (IBAction)pressedGiftBtn:(id)sender
{
    [UTILITY makeAlertWithTitle:@"알림"
                        message:@"서비스 준비중 입니다."
                 viewController:[[UTILITY.rootViewControllerPtr.navigationController viewControllers] lastObject]];

#warning 선물 신청하기 api 호출시 개인정보 암호화 해서 보내줘야함.....

//    if(_plzGiftBtn.selected == YES)
//    {
//        if(_giftRegDateView.hidden == NO)
//        {
//            [UTILITY showToastWithText:@"이미 선물신청을 완료한 스탬프투어 입니다."
//                              duration:5.f];
//            return;
//        }
//
//        GiftApplicationViewController *pView = [[GiftApplicationViewController alloc] initWithNibName:@"GiftApplicationViewController" bundle:nil];
//        pView.cateCd = [_contentsInfoDic objectForKey:@"cateCd"];
//        NSLog(@"_contentsInfoDic : %@",_contentsInfoDic);
//        pView.cosName = self.titleLabel.text;
//        [self.navigationController pushViewController:pView animated:YES];
//    }
}

//화면상단 뒤로가기 버튼
-(void)pressedTopBackBtn
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self sectionCount];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger itemNumber = 2;
    
    //마지막 섹션일때
    if(section == [self sectionCount] - 1)
    {
        NSInteger remainder = _stampDetailListArray.count % 2;
        
        if(remainder != 0)
        {
            itemNumber = 1;
        }
    }
    
    return itemNumber;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 재사용 큐에 셀을 가져온다
    StampCollectionViewCell* cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellKey
                                                  forIndexPath:indexPath];
    
    NSInteger dataIndex = (indexPath.section * 2) + indexPath.row;
    [cell setStampWithInfo:[_stampDetailListArray objectAtIndex:dataIndex]
                    cateCd:[_contentsInfoDic objectForKey:@"cateCd"]
                 dataIndex:dataIndex];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

//콜렉션 cell 사이즈 결정
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = self.collectionView.bounds.size.width/2 - 5;
    CGFloat height = width * 0.8f;
    
    return CGSizeMake(width, height);
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
        self.stampDetailListArray = [result objectForKey:@"StampListData"];
        [_collectionView reloadData];
        
        NSLog(@"self.stampDetailListArray : %@",self.stampDetailListArray);
        
        //선물 신청하기 버튼 on/off 처리
        int stampCompleteCount = 0;
        for(int i = 0; i < self.stampDetailListArray.count; i ++)
        {
            NSString *cateCd2Ok = [[self.stampDetailListArray objectAtIndex:i] objectForKey:@"cateCd2Ok"];
            
            if([cateCd2Ok isEqualToString:@"0"] == NO)
                stampCompleteCount ++;
            else
                break;
        }
        
//        NSLog(@"stampCompleteCount : %d",stampCompleteCount);
        
        if(stampCompleteCount == _stampDetailListArray.count)
        {
//            [_plzGiftBtn setImage:[UIImage imageNamed:@"stamp_request_gift_on"]
//                         forState:UIControlStateNormal];
            
            //선물하기가 완료된 스탬프가 아니면...
            if(_giftRegDateView.hidden != NO)
                _plzGiftBtn.selected = YES;
        }
        else
        {
            _plzGiftBtn.selected = NO;
        }
    }
}

@end
