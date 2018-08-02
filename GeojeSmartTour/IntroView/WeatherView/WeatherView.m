//
//  WeatherView.m
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 10. 11..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import "WeatherView.h"
#import "TheConnection.h"
#import "WeatherCell.h"
#import "ComBoBoxView.h"

#define weatherCellReuseKey     @"weatherCell"
#define cellRowHeight           30.f

@interface WeatherView () <TheConnectionDelegate, UITableViewDelegate, UITableViewDataSource, ComBoBoxViewDelegate>
{
    UIButton        *prevSelectedLocationBtn;
    TheConnection   *weatherConnection;
    NSMutableArray  *weatherArray;
    ComBoBoxView    *selectComboBox;
    
    int             currentWeatherInfoLocationIndex;
}

@property (nonatomic, strong) NSArray *locationArray;
@property (nonatomic, strong) NSString *currentDate;
@end

@implementation WeatherView

-(void)dealloc
{
    self.locationArray = nil;
    (void)([weatherArray removeAllObjects]), weatherArray = nil;
    (void)([weatherConnection stopRequest]), weatherConnection = nil;
    (void)([selectComboBox removeFromSuperview]), selectComboBox = nil;
}

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor whiteColor];
        weatherArray = [[NSMutableArray alloc] init];
        weatherConnection = [[TheConnection alloc] init];
        
        [[NSBundle mainBundle] loadNibNamed:@"WeatherView" owner:self options:nil];
        _mainView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self addSubview:_mainView];
        
        _T3hParentView.layer.borderColor = [UIColor whiteColor].CGColor;
        _T3hParentView.layer.cornerRadius = 10.f;
        
        [_weatherTableView registerNib:[UINib nibWithNibName:@"WeatherCell" bundle:nil] forCellReuseIdentifier:weatherCellReuseKey];
        _loadingViewsBackgroundView.layer.cornerRadius = 5.f;
        
        _selectLocationView.layer.cornerRadius = 5.f;
        _selectLocationView.layer.borderWidth = 1.f;
        _selectLocationView.layer.borderColor = [UIColor colorWithRed:0.663f green:0.749f blue:0.761f alpha:1.f].CGColor;
        
        self.locationArray =
        @[@"일운면",@"동부면",@"남부면",@"거제면",@"둔덕면",@"사등면",
          @"연초면",@"하청면",@"장목면",@"장승포동",@"능포동",@"아주동",@"옥포1동",@"옥포2동",@"장평동",@"고현동",@"상문동",@"수양동"];
        
        [self layoutIfNeeded];
        
        selectComboBox = [[ComBoBoxView alloc] initWithFrame:CGRectMake(_selectLocationView.frame.origin.x, _selectLocationView.frame.origin.y + _selectLocationView.frame.size.height, _selectLocationView.frame.size.width, 300.f)];
        selectComboBox.delegate = self;
        [selectComboBox setRowHeight:_selectLocationView.frame.size.height];
        [self addSubview:selectComboBox];
        [selectComboBox setListItemArray:self.locationArray];
        
        self.currentDate = [self currentDateWithForMat:@"YYYYMMdd"];
        [self bringSubviewToFront:_loadingView];
        
        //현재시간 표시
        [self updateCurrentTime];
        
        //날씨를 조회할 지역의 코드
        currentWeatherInfoLocationIndex = 0;
    }
    
    return self;
}

//날씨정보 새로고침
-(void)reloadCurrentWeatherInfo
{
    //마지막으로 선택한 지역의 날시정보를 얻어온다
    [self downloadWeatherInfoWithLocationCode:currentWeatherInfoLocationIndex];
}

#pragma mark - private

-(NSString*)safeGetStringWithRange:(NSRange)range fromString:(NSString*)str
{
    NSString *result = nil;
    
    NSInteger length = range.location + range.length;
    
    if(length <= [str length])
        result = [str substringWithRange:range];
    
    return result;
}

-(id)safeGetArrayObjectWithIndex:(NSInteger)index array:(NSArray*)arr
{
    if([arr count] <= index)    return nil;
    
    return [arr objectAtIndex:index];
}

-(void)setHiddenLoadingView:(BOOL)hidden
{
    _loadingView.hidden = hidden;
    
    if(hidden)
        [_indicator stopAnimating];
    else
        [_indicator startAnimating];
}

//현재시간 업데이트
-(void)updateCurrentTime
{
    NSString *hh = [[self currentDateWithForMat:@"HH:mm"] substringWithRange:NSMakeRange(0, 2)];
    NSString *mm = [[self currentDateWithForMat:@"HH:mm"] substringWithRange:NSMakeRange(3, 2)];
    _currentTimeLabel.text = [NSString stringWithFormat:@"%@시 %@분 현재",hh,mm];
}

-(NSString*)currentDateWithForMat:(NSString*)format
{
    NSDate * currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:currentDate];
}

//풍향정보 한글로 변환.
-(NSString*)convertVEC:(NSString*)vec
{
    if(vec == nil)  return  @"null";
    
    NSMutableString *newVec = [[NSMutableString alloc] init];
    NSInteger count = [vec length];
    
    for(int i = 0; i < count; i++)
    {
        NSString *targetStr = [vec substringWithRange:NSMakeRange(i, 1)];
        NSString *hangulStr = nil;
        
        if([targetStr isEqualToString:@"E"])
            hangulStr = @"동";
        else if([targetStr isEqualToString:@"W"])
            hangulStr = @"서";
        else if([targetStr isEqualToString:@"S"])
            hangulStr = @"남";
        else if([targetStr isEqualToString:@"N"])
            hangulStr = @"북";

        [newVec appendString:hangulStr];
    }
    
    return newVec;
}

//날씨정보 받아오기 0~17
-(void)downloadWeatherInfoWithLocationCode:(int)code
{
    if(code < 0 || code > 17)
    {
        NSLog(@"잘못된 지역코드 입니다.(0~17사이만 가능)");
        return;
    }
    
    currentWeatherInfoLocationIndex = code;
    
    [self setHiddenLoadingView:NO];
    [weatherConnection stopRequest];
    NSString *url = [NSString stringWithFormat:@"%@/user/weather/list.geoje?searchType=%d",BASE_URL,code];
    
    [weatherConnection startConnectionWithUrl:url
                                     delegate:self
                                    queueName:nil];
}

#pragma mark - Button Event

//뒤로가기 버튼
- (IBAction)pressedBackBtn:(id)sender
{
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:0.f
                            completion:^(BOOL finished){
                                
                            }];
}

//지역선택 버튼
- (IBAction)pressedLocationBtn:(id)sender
{
    [selectComboBox show];
}

#pragma mark - ComBoBoxView delegate

-(void)didSelectListView:(ComBoBoxView*)listView index:(NSInteger)index cellTitle:(NSString*)title
{
    [self downloadWeatherInfoWithLocationCode:(int)index];
    _currentLocationLabel.text = title;
}

#pragma mark - TheConnection delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    BOOL isHiddenLoadingView = YES;
    
    if(result != nil)
    {
        NSLog(@"날씨 result : %@",result);
        
        //1시간예보 데이터 입력.
        NSArray *infoArray = [result objectForKey:@"info"];
        
        if([infoArray count] == 0)      return;
        
        NSString *date = [[self safeGetArrayObjectWithIndex:0 array:infoArray] objectForKey:@"value"];
        NSString *mm = [self safeGetStringWithRange:NSMakeRange(4, 2) fromString:date];
        NSString *dd = [self safeGetStringWithRange:NSMakeRange(6, 2) fromString:date];;
        
        NSString *time = [[self safeGetArrayObjectWithIndex:1 array:infoArray] objectForKey:@"value"];
        NSString *HH = [self safeGetStringWithRange:NSMakeRange(0, 2) fromString:time];
        NSString *MM = [self safeGetStringWithRange:NSMakeRange(2, 2) fromString:time];
        
        //시간정보
        _weather1HDateLabel.text = [NSString stringWithFormat:@"현재, 1시간 예보(%@.%@ %@:%@발표)",mm,dd,HH,MM];
        
        //온도, 흐림여부
        NSString *t1h = [[self safeGetArrayObjectWithIndex:7 array:infoArray] objectForKey:@"value"];
        NSRange range = [t1h rangeOfString:@"℃"];
        double dValue = 0.f;
        
        //℃를 기준으로 문자열 잘라서 소수점첫째자리 까지 나오도록 수정.
        if(range.location != NSNotFound)
            dValue = [[t1h substringWithRange:NSMakeRange(0, range.location)] doubleValue];
        
        NSString *sky = [[self safeGetArrayObjectWithIndex:6 array:infoArray] objectForKey:@"value"];
        NSString *ondoString = [NSString stringWithFormat:@"%.1lf℃",dValue];
        
        NSDictionary *attrs = @{ NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName : [UIFont systemFontOfSize:30.0f]};

        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@",ondoString, sky]];
        
        [attString addAttributes:attrs range:NSMakeRange(0, [ondoString length])];

        //속성스트링 적용
        _T1H_SKYLabel.attributedText = attString;
        
        //맑음,구름조금,구름많음,흐림
        if([sky isEqualToString:@"맑음"])
            _currentSkyImgView.image = [UIImage imageNamed:@"sun_large_01"];
        else if([sky isEqualToString:@"구름조금"])
            _currentSkyImgView.image = [UIImage imageNamed:@"sun_large_02"];
        else if([sky isEqualToString:@"구름많음"])
            _currentSkyImgView.image = [UIImage imageNamed:@"sun_large_03"];
        else
            _currentSkyImgView.image = [UIImage imageNamed:@"sun_large_04"];
        
        //강수량,습도,바람
        NSString *rn1 = [[self safeGetArrayObjectWithIndex:5 array:infoArray] objectForKey:@"value"];
        NSString *reh = [[self safeGetArrayObjectWithIndex:4 array:infoArray] objectForKey:@"value"];
        NSString *vec = [[self safeGetArrayObjectWithIndex:9 array:infoArray] objectForKey:@"value"];
        NSString *wsd = [[self safeGetArrayObjectWithIndex:11 array:infoArray] objectForKey:@"value"];
        
        vec = [self convertVEC:vec];

        _rn1Label.text = [NSString stringWithFormat:@"강수량 %@",rn1];
        _rehLabel.text = [NSString stringWithFormat:@"습도 %@",reh];
        _vec_wsdLabel.text = [NSString stringWithFormat:@"바람 %@ %@",vec,wsd];
        
        NSString *t3h = [result objectForKey:@"base3HTime"];
//        NSLog(@"t3h : %@",t3h);

        mm = [self safeGetStringWithRange:NSMakeRange(4, 2) fromString:t3h];
        dd = [self safeGetStringWithRange:NSMakeRange(6, 2) fromString:t3h];
        HH = [self safeGetStringWithRange:NSMakeRange(8, 2) fromString:t3h];
        MM = [self safeGetStringWithRange:NSMakeRange(10, 2) fromString:t3h];
        
        _t3h_titleLabel.text = [NSString stringWithFormat:@"3시간 예보(%@.%@ %@:%@발표)",mm,dd,HH,MM];
        
        //오늘부터 3일동안 날씨 정보
        NSArray *rows = [result objectForKey:@"rows"];
        NSString *lastDate = nil;
        
        if([weatherArray count] > 0)
            [weatherArray removeAllObjects];
        
        //같은 날짜별로 날씨정보 분리하기.
        for(int i = 0; i < [rows count]; i ++)
        {
            NSDictionary *weatherInfo = [rows objectAtIndex:i];
            NSMutableArray *array = [weatherArray lastObject];
            
            if(array == nil)
            {
                array = [[NSMutableArray alloc] init];
                [weatherArray addObject:array];
            }
            
            if(lastDate == nil)
            {
                [array addObject:weatherInfo];
            }
            else
            {
                if([lastDate isEqualToString:[weatherInfo objectForKey:@"FCST_DATE"]])
                {
                    [array addObject:weatherInfo];
                }
                else
                {
                    array = [[NSMutableArray alloc] init];
                    [array addObject:weatherInfo];
                    [weatherArray addObject:array];
                }
            }
            
            lastDate = [weatherInfo objectForKey:@"FCST_DATE"];
        }
        
        NSLog(@"weatherArray count : %ld",[weatherArray count]);
        
        [_weatherTableView reloadData];
    }
    //서버통신 실패시.....
    else
    {
        NSInteger errorCode = [error code];
        
        //취소한게 아니라면...
        if(errorCode != -999)
        {
//            NSString *errorMsg = [error localizedDescription];
//            NSString *alertMsg = [NSString stringWithFormat:@"날씨 정보를 가져오는데 실패 하였습니다.\n%@",errorMsg];
//
//            [UTILITY showToastWithText:alertMsg
//                              duration:5.f];
//
//            _currentLocationLabel.text = @"지정안됨";
        }
        else
            isHiddenLoadingView = NO;
    }
    
    [self setHiddenLoadingView:isHiddenLoadingView];
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
        return 0.1f;
    
    return 10.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex = indexPath.section;
    NSInteger count = [[weatherArray objectAtIndex:rowIndex] count];
    return count * cellRowHeight;
}

#pragma mark - UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = [weatherArray count];
    if(sectionCount > 3)    sectionCount = 3;
    return sectionCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeatherCell *cell = [tableView dequeueReusableCellWithIdentifier:weatherCellReuseKey
                                                        forIndexPath:indexPath];
    cell.layer.cornerRadius = 10.f;
    cell.rowHeight = cellRowHeight;
    
    NSArray *subWeatherArr = [weatherArray objectAtIndex:indexPath.section];
    NSString *headDateLabelString = @"오늘";
    
    if(indexPath.section == 1)
        headDateLabelString = @"내일";
    else if(indexPath.section == 2)
        headDateLabelString = @"모레";
    
    cell.headDateLabel.text = headDateLabelString;
    
    cell.weatherArray = subWeatherArr;
    [[cell tableView] reloadData];
    return cell;
}


@end
