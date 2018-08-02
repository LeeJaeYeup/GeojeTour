//
//  SmartTourismView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 14..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "SmartTourismView.h"
@import GoogleMaps;
#import "TheConnection.h"
#import "ViewController.h"
#import "MarqueeLabel.h"


typedef NS_ENUM(NSInteger, SmartTourismConnectionType)
{
    SmartTourismConnectionTypeGetBeaconGroupAll,
    SmartTourismConnectionTypeGetFood,
    SmartTourismConnectionTypeGetMotel,
    SmartTourismConnectionTypeGetParking,
    SmartTourismConnectionTypeGetPublicWifi
};

#define kEnableCategoryBackgroundColor              [UIColor colorWithRed:0.216f green:0.306f blue:0.376f alpha:1.f]
#define kDisableCategoryTextColor                   [UIColor grayColor]
#define kUrlGetALLBeaconGroup                       [NSString stringWithFormat:@"%@/cms/beacon/group/openapi_groupAll.sko",BASE_URL]
#define kUrlSearchGroupFromGroupSid                 [NSString stringWithFormat:@"%@/cms/beacon/openapi_beaconAll.sko?searchGroup=",BASE_URL]
#define kUrlGetPublicWIFIData                       [NSString stringWithFormat:@"%@/user/openwifi/list.geoje",BASE_URL]

#define kFoodGroupSid                               75
#define kMotelGroupSid                              76
#define kParkingGroupSid                            170

#define kCategoryNameArray                          @[@"전체",@"관광명소",@"추천명소8경",@"체험관광",@"맛집",@"숙박",@"관광안내소",@"교통시설",@"전통시장",@"주차장"]

@interface SmartTourismView () <TheConnectionDelegate, GMSMapViewDelegate, NSXMLParserDelegate>
{
    NSInteger           selectCategoryTagNum;
    NSMutableArray      *selectCategoryBeaconGroupArray;
    ContentsListView    *contentsListView;
    
    GMSMarker           *currentSelectedMarker;
    UIImage             *prevMarkerImage;
    
    //xml 파싱 관련...
    NSMutableDictionary *xmlItemDict;
    
}

@property (strong, nonatomic) IBOutlet UIView *xibMainView;
@property (weak, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UIView *selectCategoryMenuView;
@property (weak, nonatomic) IBOutlet UILabel *currentSelectCategoryLabel;

//카테고리 라벨
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel01;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel02;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel03;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel04;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel05;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel06;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel07;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel08;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel09;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel10;


//모텔,숙박,주차장, 공공wifi 데이터
@property (strong, nonatomic) NSArray *foodCategoryArray;
@property (strong, nonatomic) NSArray *motelCategoryArray;
@property (strong, nonatomic) NSArray *parkingCategoryArray;
@property (strong, nonatomic) NSMutableArray *publicWifiArray;

//로딩뷰...
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

//바닥 팝업뷰...
@property (weak, nonatomic) IBOutlet UIView *bottomPopupView;
@property (weak, nonatomic) IBOutlet UIImageView *contentsImgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contsImgViewTopConstraints;
@property (weak, nonatomic) IBOutlet MarqueeLabel *groupTitleLabel;
@property (weak, nonatomic) IBOutlet MarqueeLabel *groupAddrLabel;
@property (strong, nonatomic) NSMutableDictionary *currentPopupDataInfo;
@property (weak, nonatomic) IBOutlet UIView *leftCallView;
@property (weak, nonatomic) IBOutlet UIView *rightNavigationView;
@property (weak, nonatomic) IBOutlet UIButton *callBtn;

//데이터관련...
@property (nonatomic, strong) NSArray *allBeaconGroupArray;

//xml파싱 관련...
@property (nonatomic, strong) NSString *currentElementName;


@end

@implementation SmartTourismView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        //xib뷰 불러와서 뷰에 올리기
        [[NSBundle mainBundle] loadNibNamed:@"SmartTourismView" owner:self options:nil];
        [_xibMainView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_xibMainView];

        [self setAllUIText];
        
        [self layoutIfNeeded];
        
        //초기화 코드....
        self.publicWifiArray = [[NSMutableArray alloc] init];
        _currentPopupDataInfo = [[NSMutableDictionary alloc] init];
        selectCategoryBeaconGroupArray = [[NSMutableArray alloc] init];
        selectCategoryTagNum = 1;           //처음에 선택되어 있는 카테고리 버튼tag값
        _selectCategoryMenuView.hidden = YES;
        
        //카테고리 메뉴뷰 UI상태 초기화...
        for(UIView *pView in [_selectCategoryMenuView subviews])
        {
            NSArray *subViewArr = [pView subviews];
            
            if(pView.tag > 0)
                pView.backgroundColor = [UIColor whiteColor];
            
            for(id pObject in subViewArr)
            {
                //아이콘이미지 일때
                if([pObject isKindOfClass:[UIImageView class]])
                {
                    if(pView.tag != 0)
                    {
                        UIImageView *chkImgView = pObject;
                        chkImgView.hidden = YES;
                    }
                }
                //텍스트 라벨일때
                else if([pObject isKindOfClass:[UILabel class]])
                {
                    UILabel *label = pObject;
                    
                    //디폴트 선택 버튼
                    if(pView.tag == 1)
                    {
                        label.textColor = [UIColor whiteColor];
                        pView.backgroundColor = kEnableCategoryBackgroundColor;
                    }
                    else
                        label.textColor = kDisableCategoryTextColor;
                }
            
            } //end of for
        
        } //end of for
        
        //구글맵관련...
        [_googleMapView setMyLocationEnabled:YES];
        _googleMapView.delegate = self;
        [self setMapCameraToGeoJe];
        
        //하단 팝업뷰...
        CGFloat popUpViewHeight = frame.size.height / 3.f;     //높이계산...
        if(popUpViewHeight < 155)
            popUpViewHeight = 155.f;
        
        _bottomPopupView.frame = CGRectMake(0, 0, frame.size.width, popUpViewHeight);
//        NSLog(@"popUpViewHeight : %lf",popUpViewHeight);
        
        //어토 레이아웃으로 바뀐 프레임 바로 반영하기
        [_bottomPopupView layoutIfNeeded];
        
        //이미지뷰 위치잡고 원 모양으로....
        [_contsImgViewTopConstraints setConstant:-(_contentsImgView.bounds.size.height / 2)];
        _contentsImgView.layer.cornerRadius = _contentsImgView.bounds.size.width/2.f;
        
        CGFloat iphoneXBottomPadding = 0;
        
        if (@available(iOS 11.0, *))
        {
            UIWindow *window = UIApplication.sharedApplication.keyWindow;
            iphoneXBottomPadding = window.safeAreaInsets.bottom;
        }

        _bottomPopupView.frame = CGRectMake(0, _xibMainView.bounds.size.height + (_contentsImgView.bounds.size.height / 2) + iphoneXBottomPadding, frame.size.width, popUpViewHeight);
        [_xibMainView addSubview:_bottomPopupView];
        
        //컨텐츠 리스트 뷰
        contentsListView = [[ContentsListView alloc] initWithFrame:_xibMainView.bounds];
        [_xibMainView addSubview:contentsListView];
        contentsListView.alpha = 0.f;

        NSLog(@"비콘 그룹데이터 url : %@",kUrlGetALLBeaconGroup);

        //비콘 그룹데이터 내려받기...
        [self startConnectionWithURL:kUrlGetALLBeaconGroup
                                 tag:SmartTourismConnectionTypeGetBeaconGroupAll
                          identifier:nil
                 convertDataToString:YES];
    }
    
    return self;
}

-(ContentsListView*)contentsListView
{
    return contentsListView;
}

#pragma mark - private

//지도에 마커 그리기
-(void)createMarkerWithCoordinate:(CLLocationCoordinate2D)coord userData:(NSDictionary*)info icon:(UIImage*)iconImg title:(NSString*)title
{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            GMSMarker *marker = [[GMSMarker alloc] init];
            marker.position = coord;
            marker.appearAnimation = kGMSMarkerAnimationPop;
            marker.userData = info;
            marker.icon = iconImg;
            marker.title = title;
            marker.map = _googleMapView;
        
        });
//    });
}

//공공WIFI 마커를 추가한다.
-(void)addMarkerForPublicWifi
{
    for(int i = 0; i < _publicWifiArray.count; i ++)
    {
        NSDictionary *dataInfo = [_publicWifiArray objectAtIndex:i];
        
        CLLocationDegrees lat = [[dataInfo objectForKey:@"x"] doubleValue];
        CLLocationDegrees lon = [[dataInfo objectForKey:@"y"] doubleValue];
        
        NSString *title = [dataInfo objectForKey:@"title"];
        //KT, LGU+, SKT
        NSString *company = [dataInfo objectForKey:@"company"];
        NSString *markerIcoName = nil;
        
        if([company containsString:@"SKT"])
            markerIcoName = @"ico_map_marker_7";
        else if([company containsString:@"KT"])
            markerIcoName = @"ico_map_marker_1";
        else
            markerIcoName = @"ico_map_marker_6";
        
        [self createMarkerWithCoordinate:CLLocationCoordinate2DMake(lat, lon)
                                userData:dataInfo
                                    icon:[UIImage imageNamed:markerIcoName]
                                   title:title];
    }
}

//공공와이파이 데이터 다운받기.
-(void)getPublicWifiData
{
    [self startConnectionWithURL:kUrlGetPublicWIFIData
                             tag:SmartTourismConnectionTypeGetPublicWifi
                      identifier:nil
             convertDataToString:NO];
}

-(NSArray*)categoryNameLabelsArray
{
    return @[_categoryLabel01, _categoryLabel02, _categoryLabel03,
             _categoryLabel04, _categoryLabel05, _categoryLabel06,
             _categoryLabel07, _categoryLabel08, _categoryLabel09,
             _categoryLabel10];
}

-(void)setAllUIText
{
    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];
    NSArray *textLablesArr = [self categoryNameLabelsArray];
    NSArray *categoryTitleArr = [languageInfoDic objectForKey:@"lk_smart_tourism_category"];
    
    for(int i = 0; i < textLablesArr.count; i ++)
    {
        UILabel *mainMenuTextLabel = [textLablesArr objectAtIndex:i];
        mainMenuTextLabel.text = [categoryTitleArr objectAtIndex:i];
    }
}

-(void)addMarkerWithCategoryArray:(NSArray*)cateArray
{
    //지도에 마커 올리기..
    for(int i = 0; i < cateArray.count; i ++)
    {
        NSDictionary *groupInfo = [cateArray objectAtIndex:i];
//        NSLog(@"groupInfo : %@",groupInfo);
        [self addMarkerWithInfo:groupInfo];
    }
}

//카테고리 선택하기
-(void)selectCategoryWithIndex:(NSInteger)index
{
    if(index < 1 || index > 10)      return;
    
    NSInteger selectBtnTag = index;
    
    //하단 팝업뷰 숨기기
    [self setHiddenBottomPopupView:YES];
    
    NSArray *textLablesArr = [self categoryNameLabelsArray];
    UILabel *selectCategoryLabel = [textLablesArr objectAtIndex:selectBtnTag - 1];
    
    //현재 선택한 카테고리 이름설정
    _currentSelectCategoryLabel.text = selectCategoryLabel.text;
    
    [self setEnableSelectedCategoryViewWithTag:selectCategoryTagNum enable:NO];
    [self setEnableSelectedCategoryViewWithTag:selectBtnTag enable:YES];
    
    selectCategoryTagNum = selectBtnTag;
    
    NSString *categoryCdStr = @"A00";
    
    if(selectBtnTag == 1)
        categoryCdStr = @"A02";
    else if(selectBtnTag == 2)
        categoryCdStr = @"A01";
    else if(selectBtnTag == 3)
        categoryCdStr = @"A18";
    else if(selectBtnTag == 4)
        categoryCdStr = @"A09";
    else if(selectBtnTag == 5)
        categoryCdStr = @"A10";
    else if(selectBtnTag == 6)
        categoryCdStr = @"A12";
    else if(selectBtnTag == 7)
        categoryCdStr = @"A19";
    else if(selectBtnTag == 8)
        categoryCdStr = @"A08";
    
//    주차장은 A20, groupSid 170
    
    //지도상태 클리어
    [_googleMapView clear];
    
//    NSLog(@"categoryCdStr : %@",categoryCdStr);
    
    //음식
    if(selectBtnTag == 4)
    {
        [self addMarkerWithCategoryArray:self.foodCategoryArray];
    }
    //숙박
    else if(selectBtnTag == 5)
    {
        [self addMarkerWithCategoryArray:self.motelCategoryArray];
    }
    //주차장
    else if(selectBtnTag == 9)
    {
        [self addMarkerWithCategoryArray:self.parkingCategoryArray];
    }
    //공공wifi
    else if(selectBtnTag == 10)
    {
        //지도에 마커 추가하기..
        [self addMarkerForPublicWifi];
    }
    else
        [self addMarkerWithCategoryCd:categoryCdStr];
    
    //지도 카메라 이동하기
    [self setMapCameraToGeoJe];
    
    currentSelectedMarker = nil;
}

//groupSid로 그룹데이터 조회하기(음식,숙박,주차장)
-(void)loadOtherGroupDataWithSid:(NSInteger)groupSid
{
    SmartTourismConnectionType connType = SmartTourismConnectionTypeGetFood;
    if(groupSid == kMotelGroupSid)          connType = SmartTourismConnectionTypeGetMotel;
    else if(groupSid == kParkingGroupSid)   connType = SmartTourismConnectionTypeGetParking;
    
    NSString *url = [NSString stringWithFormat:@"%@%ld",kUrlSearchGroupFromGroupSid,groupSid];
    
    NSLog(@"음식 또는 숙박 또는 주차장 데이터 다운로드 url : %@",url);
    
    [self startConnectionWithURL:url
                             tag:connType
                      identifier:nil
             convertDataToString:YES];
}

//지도 카메라를 거제 중앙으로 이동..
-(void)setMapCameraToGeoJe
{
    CGFloat zoomLevel = 10.8f;
    if(self.frame.size.width <= 320)
        zoomLevel = 10.4f;
    
    [self moveMapViewCameraWithCoordinate:CLLocationCoordinate2DMake(34.875124, 128.616589)
                                zoomLevel:zoomLevel];
}

//하단 팝업뷰 컨텐츠 이미지 다운로드 완료시...
-(void)handleDelayedImage:(UIImage*)image
{
    _contentsImgView.image = image;
    
    if(image == nil)
        _contentsImgView.hidden = YES;
    else
        _contentsImgView.hidden = NO;
}

//카테고리별로 나눠서 지도에 마커를 표시한다.
-(void)addMarkerWithCategoryCd:(NSString*)cateCd
{
    [selectCategoryBeaconGroupArray removeAllObjects];
    
    for(int i = 0; i < _allBeaconGroupArray.count; i ++)
    {
        NSDictionary *groupInfo = [_allBeaconGroupArray objectAtIndex:i];
        NSString *groupCateCd = [groupInfo objectForKey:@"groupCateCd"];
        
        if([groupCateCd isEqualToString:cateCd])
        {
            [selectCategoryBeaconGroupArray addObject:groupInfo];
        }
    }
    
    //지도에 마커 올리기..
    for(int i = 0; i < selectCategoryBeaconGroupArray.count; i ++)
    {
        [self addMarkerWithInfo:[selectCategoryBeaconGroupArray objectAtIndex:i]];
    }
    
}

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier convertDataToString:(BOOL)convert
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.convertDataToString = convert;
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

//지도에 마커 추가하기
-(void)addMarkerWithInfo:(NSDictionary*)info
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        
        NSArray *selectArr = nil;
        NSString *beaconFullPathLink = nil;
        
        //음식 또는 숙박이 아닐때...
        if((selectCategoryTagNum == 4 || selectCategoryTagNum == 5 || selectCategoryTagNum == 9) == NO)
        {
            NSString *groupSid = [info objectForKey:@"groupSid"];
            
            selectArr =
            [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface] selectWithColumns:@[@"beaconFullPathLink"]
                                                                                 WithTableName:kTableNameAllBeacon
                                                                                         where:[NSString stringWithFormat:@"where groupSid = '%@'",groupSid]
                                                                                      distinct:YES];
            beaconFullPathLink = [[selectArr lastObject] objectForKey:@"beaconFullPathLink"];
        }
        else
        {
            beaconFullPathLink = [info objectForKey:@"beaconFullPathLink"];
        }
        
        if([beaconFullPathLink length] <= 1 || beaconFullPathLink == nil)
            return;
        
        NSString *mapXPos = [info objectForKey:@"groupXmap"];
        NSString *mapYPos = [info objectForKey:@"groupYmap"];
        
        if(mapXPos == nil && mapYPos == nil)
        {
            mapXPos = [info objectForKey:@"beaconXmap"];
            mapYPos = [info objectForKey:@"beaconYmap"];
        }
        
        CLLocationDegrees lat = [mapXPos doubleValue];
        CLLocationDegrees lon = [mapYPos doubleValue];
        
        //카테고리별로 마커 아이콘 다르게 설정....
        NSString *markerTitle = [info objectForKey:@"groupTitle"];
        if(markerTitle == nil)
            markerTitle = [info objectForKey:@"beaconTitle"];
        //    NSLog(@"markerTitle : %@",markerTitle);
        
        NSInteger markerIconNumber = selectCategoryTagNum;
        while (markerIconNumber > 7)
        {
            markerIconNumber -= 7;
        }
        
        //주차장일때...
        if(selectCategoryTagNum == 9)
        {
            //유료,무료 마커컬러 다르게 설정
            if([markerTitle containsString:@"유료"])
            {
                markerIconNumber += 1;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{

            NSString *markerImgName = [NSString stringWithFormat:@"ico_map_marker_%ld",markerIconNumber];
            
            [self createMarkerWithCoordinate:CLLocationCoordinate2DMake(lat, lon)
                                    userData:info
                                        icon:[UIImage imageNamed:markerImgName]
                                       title:markerTitle];
        });
    });
}

//현재 사용자 위치로 지도시점을 이동시킨다
-(void)lookCurrentUserLocationInMap
{
    CLAuthorizationStatus currentLocationAuthorizationStatus = [CLLocationManager authorizationStatus];
    
    CLLocationCoordinate2D userCoord = _googleMapView.myLocation.coordinate;
    
    //정상적인 위도경도값이고, 위치서비스 사용이 중지되어 있지 않을때...
    if(CLLocationCoordinate2DIsValid(userCoord) && (currentLocationAuthorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||currentLocationAuthorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse))
    {
        [self moveMapViewCameraWithCoordinate:userCoord zoomLevel:17];
    }
    else
    {
        [UTILITY showToastWithText:@"사용자의 위치를 확인할 수 없습니다.\n설정앱에서 위치서비스 사용이 꺼져있거나, 거제여행 앱에 대한 위치서비스 사용이 중지되어 있습니다."
                          duration:10.f];
    }
}

//하단 팝업뷰 숨김설정
-(void)setHiddenBottomPopupView:(BOOL)hidden
{
    CGRect newFrame = CGRectZero;
    
    CGFloat iphoneXBottomPadding = 0.f;
    
    if (@available(iOS 11.0, *))
    {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        iphoneXBottomPadding = window.safeAreaInsets.bottom;
    }

    if(hidden)
    {
        newFrame = CGRectMake(0, _xibMainView.bounds.size.height + (_contentsImgView.bounds.size.height / 2) + iphoneXBottomPadding, _bottomPopupView.frame.size.width, _bottomPopupView.frame.size.height);
    }
    else
    {
        newFrame = CGRectMake(0, _xibMainView.bounds.size.height - _bottomPopupView.bounds.size.height, _bottomPopupView.frame.size.width, _bottomPopupView.frame.size.height);
    }
    
    [UTILITY setMoveAnimationWithView:_bottomPopupView
                             newFrame:newFrame
                           completion:^(BOOL finished)
     {
     }];

}

//맵뷰 시점을 이동시킨다....
-(void)moveMapViewCameraWithCoordinate:(CLLocationCoordinate2D)coord zoomLevel:(CGFloat)zoom
{
    GMSCameraUpdate *locationUpdate = [GMSCameraUpdate setTarget:coord zoom:zoom];
    [_googleMapView animateWithCameraUpdate:locationUpdate];
}

//카테고리 선택뷰 하위버튼 뷰들 리턴
-(UIView*)categoryMenuSubViewWithTag:(NSInteger)tag
{
    //tag 범위 0 ~ 8
    UIView *subView = nil;

    for(UIView *view in [_selectCategoryMenuView subviews])
    {
        if(tag == view.tag)
        {
            subView = view;
            break;
        }
    }
    
    return subView;
}

//선택한 카테고리 버튼 상태변경
-(void)setEnableSelectedCategoryViewWithTag:(NSInteger)tag enable:(BOOL)enable
{
    UIColor *enableTextColor = [UIColor whiteColor];
    UIColor *disableTextColor = kDisableCategoryTextColor;
    UIColor *enableBackgroundColor = kEnableCategoryBackgroundColor;
    UIColor *disableBackgroundColor = [UIColor whiteColor];
    UIColor *textColor = enable ? enableTextColor : disableTextColor;
    
    UIView *categoryBtnView = [self categoryMenuSubViewWithTag:tag];
    categoryBtnView.backgroundColor = enable ? enableBackgroundColor : disableBackgroundColor;
    
    for(id pObject in [categoryBtnView subviews])
    {
        //이미지뷰
        if([pObject isKindOfClass:[UIImageView class]])
        {
            UIImageView *chkImgView = pObject;
            chkImgView.hidden = !enable;
        }
        //라벨
        else if([pObject isKindOfClass:[UILabel class]])
        {
            UILabel *label = pObject;
            label.textColor = textColor;
        }
    }
}

#pragma mark - Button Event

//카테고리 보여주기 버튼
- (IBAction)pressedSelectShowCategoryViewBtn:(id)sender
{
    _selectCategoryMenuView.hidden = !_selectCategoryMenuView.hidden;
}

//내위치 버튼
- (IBAction)pressedMyLocateBtn:(id)sender
{
    [self lookCurrentUserLocationInMap];
}

//카테고리선택 버튼
- (IBAction)pressedSelectCategoryBtn:(id)sender
{
    NSLog(@"스마트관광 카테고리 버튼 선택됨...");
    UIButton *btn = sender;
    NSInteger selectBtnTag = btn.tag;
    
    if(selectCategoryTagNum == selectBtnTag)    return;
    
    [self selectCategoryWithIndex:selectBtnTag];
    
    _selectCategoryMenuView.hidden = YES;
}

//하단 팝업뷰 백그라운드 선택시 이벤트
- (IBAction)pressedBottomPopViewBackgroundBtn:(id)sender
{
    //공공WIFI 카테고리 선택시 리턴!!
    if(selectCategoryTagNum == 10)      return;
    
    NSLog(@"하단 팝업뷰 선택 이벤트!!");
    int groupSid = [[_currentPopupDataInfo objectForKey:@"groupSid"] intValue];
    NSString *title = [_currentPopupDataInfo objectForKey:@"groupTitle"];
    if(title == nil)
        title = [_currentPopupDataInfo objectForKey:@"beaconTitle"];
//    NSLog(@"선택된 그룹 정보 : %@",_currentPopupDataInfo);
    
    //거제 포로수용소 또는 해양문화관이면 컨텐츠 리스트를 보여준다.
    if(groupSid == 5 || groupSid == 162)
    {
        //컨텐츠 리스트 뷰에 groupSid를 넘겨준다.
        [contentsListView setContentsWithGroupSid:groupSid
                                      contentsImg:_contentsImgView.image
                                          imgPath:[_currentPopupDataInfo objectForKey:@"smartcontentimg"]
                                            title:title];
        
        [UTILITY setAlphaAnimationWithView:contentsListView
                                     alpha:1.f
                                completion:nil];
    }
    else
    {
        ViewController *rootViewController = UTILITY.rootViewControllerPtr;
        NSArray *selectArr = nil;
        
        //음식 또는 숙박이 아닐때...
        if((selectCategoryTagNum == 4 || selectCategoryTagNum == 5) == NO)
        {
            selectArr = [[[rootViewController beaconDataManager] dbInterface] selectAllWithTableName:kTableNameAllBeacon
                                                                                               where:[NSString stringWithFormat:@"where groupSid = '%d'",groupSid]];
        }
        
        //웹뷰에 테울 url 구성하기...
        NSString *url = nil;
        NSString *beaconFullPathLink = [_currentPopupDataInfo objectForKey:@"beaconFullPathLink"];
        
        if(selectArr != nil)
            beaconFullPathLink = [[selectArr firstObject] objectForKey:@"beaconFullPathLink"];

        url = [UTILITY.rootViewControllerPtr beaconContentsUrlWithFullPathLink:beaconFullPathLink];
        
        [rootViewController showWebViewWithUrl:url];
//        NSLog(@"selectArr : %@",selectArr);
    }
}

//전화걸기 버튼
- (IBAction)pressedCallBtn:(id)sender
{
    //전화번호가 없으면 리턴....
    if(_callBtn.selected == YES)
        return;
    
//    NSString *telNumStr = [_currentPopupDataInfo objectForKey:@"groupTel"];
//    if([telNumStr length] == 0)
//        telNumStr = [_currentPopupDataInfo objectForKey:@"basicTel"];
    
    NSString *telNumStr = [_currentPopupDataInfo objectForKey:@"basicTel"];
    if(telNumStr == nil)
        telNumStr = [_currentPopupDataInfo objectForKey:@"tel"];
    
    if([telNumStr length] == 0)
    {
        [UTILITY makeAlertWithTitle:@"알림"
                            message:@"등록된 번호가 없습니다."
                     viewController:UTILITY.rootViewControllerPtr];
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"telprompt://%@",telNumStr];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
                                       options:@{}
                             completionHandler:^(BOOL successed)
     {
         NSLog(@"전화걸기 successed : %d",successed);
     }];
}

//길찾기 버튼
- (IBAction)pressedFindRoadBtn:(id)sender
{
    CLAuthorizationStatus locationAuthStatus = [CLLocationManager authorizationStatus];
    if(locationAuthStatus == kCLAuthorizationStatusDenied)
    {
        [UTILITY showToastWithText:@"사용자의 위치값을 확인할 수 없습니다.\n설정 앱에서 위치서비스 사용설정여부를 확인해주세요."
                          duration:5.f];
        return;
    }
    
    NSString *url = nil;

    NSString *userxPos = [NSString stringWithFormat:@"%lf",[_googleMapView myLocation].coordinate.latitude];
    NSString *useryPos = [NSString stringWithFormat:@"%lf",[_googleMapView myLocation].coordinate.longitude];
    
    NSString *xPos = nil;
    NSString *yPos = nil;
    
    //선택된 카테고리가 공공WIFI 일때...
    if(selectCategoryTagNum == 10)
    {
        xPos = [_currentPopupDataInfo objectForKey:@"x"];
        yPos = [_currentPopupDataInfo objectForKey:@"y"];
    }
    //그외
    else
    {
        xPos = [_currentPopupDataInfo objectForKey:@"groupXmap"];
        yPos = [_currentPopupDataInfo objectForKey:@"groupYmap"];
        
        if(xPos == nil || yPos == nil)
        {
            xPos = [_currentPopupDataInfo objectForKey:@"beaconXmap"];
            yPos = [_currentPopupDataInfo objectForKey:@"beaconYmap"];
        }
    }
    
    url = [NSString stringWithFormat:@"daummaps://route?sp=%@,%@&ep=%@,%@&by=CAR",userxPos, useryPos, xPos, yPos];
    
    NSLog(@"길찾기 url : %@",url);
    
    NSURL *routeUrl = [NSURL URLWithString:url];
    
    if([[UIApplication sharedApplication] canOpenURL: routeUrl] == NO)
    {
        routeUrl = [NSURL URLWithString:@"https://itunes.apple.com/kr/app/da-eum-jido-gilchajgi-jihacheol/id304608425?mt=8"];
    }
    
    [[UIApplication sharedApplication] openURL:routeUrl
                                       options:@{}
                             completionHandler:nil];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    SmartTourismConnectionType connType = connection.tag;

    if(error == nil)
    {
        //모든 비콘그룹 받아왔을때...
        if(connType == SmartTourismConnectionTypeGetBeaconGroupAll)
        {
//            NSLog(@"비콘 그룹데이터 result : %@",result);
            self.allBeaconGroupArray = [result objectForKey:@"RFCBeaconGroupData"];

            //추천명소 8경 마커 추가하기..
            [self selectCategoryWithIndex:1];

            //음식 카테고리 데이터 받아오기..
            [self loadOtherGroupDataWithSid:kFoodGroupSid];
        }
        //음식
        else if(connType == SmartTourismConnectionTypeGetFood)
        {
            self.foodCategoryArray = [result objectForKey:@"RFCBeaconData"];

            //숙박 카테고리 데이터 받아오기..
            [self loadOtherGroupDataWithSid:kMotelGroupSid];
        }
        //숙박
        else if(connType == SmartTourismConnectionTypeGetMotel)
        {
            self.motelCategoryArray = [result objectForKey:@"RFCBeaconData"];
            
            //주차장 카테고리 데이터 받아오기..
            [self loadOtherGroupDataWithSid:kParkingGroupSid];
        }
        //주차장 데이터 다운로드 결과
        else if(connType == SmartTourismConnectionTypeGetParking)
        {
            self.parkingCategoryArray = [result objectForKey:@"RFCBeaconData"];
            
            //공공와이파이 데이터 다운로드
            [self getPublicWifiData];
        }
        //공공와이파이 데이터 다운로드 결과
        else if(connType == SmartTourismConnectionTypeGetPublicWifi)
        {
//            NSLog(@"공공wifi data 결과값 : %@",result);
            //xml 파싱 시작...
            NSString *responseString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
            NSData *xmlData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
            xmlParser.delegate = self;
            [xmlParser parse];
        }
    }
    else
    {
        NSLog(@"error connType : %ld",connType);
    }
}

#pragma mark - GMSMapViewDelegate

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    CLLocationCoordinate2D markerCoord = marker.position;
    GMSCameraPosition *markerCameraPosition = [GMSCameraPosition cameraWithLatitude:markerCoord.latitude
                                                                          longitude:markerCoord.longitude
                                                                               zoom:mapView.camera.zoom];
    [mapView setCamera:markerCameraPosition];
    NSDictionary *selectMarkerInfo = [marker userData];
    
    [self setHiddenBottomPopupView:NO];
    [_currentPopupDataInfo setDictionary:selectMarkerInfo];
    
    //썸네일 이미지 불러오기...
    _contentsImgView.image = nil;
    
    //공공WIFI 마커 선택시...
    if(selectCategoryTagNum == 10)
    {
        _contentsImgView.hidden = YES;
        _groupTitleLabel.text = [selectMarkerInfo objectForKey:@"title"];
        _groupAddrLabel.text = [selectMarkerInfo objectForKey:@"addr"];
        
        NSString *telNum = [selectMarkerInfo objectForKey:@"tel"];
        
        //전화번호가 없으면...
        if(telNum == nil || [telNum length] <= 1)
        {
            _callBtn.selected = YES;
        }
        //전화번호가 있으면
        else
        {
            _callBtn.selected = NO;
        }
    }
    //그외...
    else
    {
        //하단 팝업뷰 올리기..
        NSString *title = [selectMarkerInfo objectForKey:@"groupTitle"];
        if([title length] == 0)
            title = [selectMarkerInfo objectForKey:@"beaconTitle"];
        
        NSString *addr = [selectMarkerInfo objectForKey:@"groupAddr"];
        if([addr length] == 0)
            addr = [selectMarkerInfo objectForKey:@"beaconAddr"];
        
        NSString *selectWhereStr = [NSString stringWithFormat:@"where groupSid = '%@'",[selectMarkerInfo objectForKey:@"groupSid"]];
        
        //음식 또는 숙박일때 where 조건 변경
        if(selectCategoryTagNum == 4 || selectCategoryTagNum == 5)
        {
            selectWhereStr = [NSString stringWithFormat:@"where beaconTitle = '%@'",[selectMarkerInfo objectForKey:@"beaconTitle"]];
            NSLog(@"selectWhereStr : %@",selectWhereStr);
        }
        
        NSArray * selectArr =
        [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface] selectWithColumns:@[@"basicTel",@"smartcontentimg"]
                                                                             WithTableName:kTableNameAllBeacon
                                                                                     where:selectWhereStr
                                                                                  distinct:YES];
        //아무것도 들고오지 못했을 경우...
        if(selectArr == nil)
        {
            selectArr = @[@{@"basicTel" : @"", @"smartcontentimg" : @""}];
        }
        
        //    NSLog(@"selectArr : %@",selectArr);
        
        NSString *telNum = @"";
        if(selectArr.count > 0)
            telNum = [[selectArr firstObject] objectForKey:@"basicTel"];
        
        _groupTitleLabel.text = title;
        _groupAddrLabel.text = addr;
        
        //전화번호가 없으면...
        if(telNum == nil || [telNum length] <= 1)
        {
            _callBtn.selected = YES;
        }
        //전화번호가 있으면
        else
        {
            _callBtn.selected = NO;
        }
        
        //전화번호 비콘데이터꺼 저장하기
        [_currentPopupDataInfo setObject:telNum forKey:@"basicTel"];
        
        NSString *smartcontentimg = [[selectArr firstObject] objectForKey:@"smartcontentimg"];
        
        //선택된 그룹에 대한 이미지 path 저장해 놓기
        [_currentPopupDataInfo setObject:smartcontentimg forKey:@"smartcontentimg"];
        
        //    NSString *smartcontentimg = [_currentPopupDataInfo objectForKey:@"smartcontentimg"];
        
        if([smartcontentimg length] > 1)
        {
            _contentsImgView.hidden = NO;
            
            smartcontentimg = [smartcontentimg stringByReplacingOccurrencesOfString:@"/data/web/RFC3" withString:@""];
            NSString *imgPath = [NSString stringWithFormat:@"%@%@",BASE_URL,smartcontentimg];
            
            NSLog(@"선택한 그룹 imgPath : %@",imgPath);
            
            SmartTourismView* __weak weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:
                                                          [NSURL  URLWithString:imgPath]]];
                dispatch_sync(dispatch_get_main_queue(),^ {
                    //run in main thread
                    [weakSelf handleDelayedImage:image];
                });
            });
        }
        else
            _contentsImgView.hidden = YES;
    }
    
    //마커 이미지 변경하기.
    if(currentSelectedMarker != nil)
    {
        currentSelectedMarker.icon = prevMarkerImage;
    }
    
    currentSelectedMarker = marker;
    prevMarkerImage = marker.icon;
    marker.icon = [UIImage imageNamed:@"ico_map_curr_selectMarker"];

    return YES;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    //이전에 선택된 마커가 있으면 이미지를 원래대로 바꾼다.
    if(currentSelectedMarker != nil)
    {
        currentSelectedMarker.icon = prevMarkerImage;
        currentSelectedMarker = nil;
    }
    
    _selectCategoryMenuView.hidden = YES;
    [self setHiddenBottomPopupView:YES];
}

#pragma mark - NSXMLParser Delegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
//    NSLog(@"************************************");
//    NSLog(@"start elementName : %@",elementName);
    self.currentElementName = elementName;
    if([elementName isEqualToString:@"item"])
    {
        xmlItemDict = [[NSMutableDictionary alloc] init];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
//    NSLog(@"end elementName : %@",elementName);
//    NSLog(@"************************************");
    self.currentElementName = nil;
    
    //아이템 하나 끝
    if([elementName isEqualToString:@"item"])
    {
        [self.publicWifiArray addObject:xmlItemDict];
    }
    //파싱 끝
    else if([elementName isEqualToString:@"list"])
    {
//        NSLog(@"publicWifiArray : %@",_publicWifiArray);
        
        [UTILITY setAlphaAnimationWithView:_loadingView
                                     alpha:0.f
                                completion:^(BOOL finished)
         {
             [_loadingIndicator stopAnimating];
         }];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
//    NSLog(@"xml found String : %@",string);
    if([_currentElementName isEqualToString:@"list"] == NO &&
       _currentElementName != nil)
    {
        [xmlItemDict setValue:string forKey:_currentElementName];
    }
}

@end
