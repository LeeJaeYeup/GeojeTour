//
//  IntroView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 19..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "IntroView.h"
#import "TheConnection.h"
#import "WeatherView.h"

@interface IntroView () <TheConnectionDelegate>
{
    UILabel         *weatherTextLabel;
    UIImageView     *weatherImageView;
    WeatherView     *showMoreWeatherView;
}

@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (weak, nonatomic) IBOutlet UILabel *bottomVersionInfoLabel;

//날씨관련...
@property (weak, nonatomic) IBOutlet UIView *weatherAreaView;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *wfKor;
@property (nonatomic, strong) NSString *temperature;

//텍스트라벨
@property (weak, nonatomic) IBOutlet UILabel *menuLabel1;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel2;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel3;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel4;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel5;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel6;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel7;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel8;

@end

@implementation IntroView

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if(_mainXibView == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"IntroView" owner:self options:nil];
        [_mainXibView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        [self addSubview:_mainXibView];

        NSString *bgImgName = [NSString stringWithFormat:@"main_bg_%ld",[UTILITY screenType]];
        self.bgImageView.image = [UIImage imageNamed:bgImgName];
        
        weatherImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_weatherAreaView addSubview:weatherImageView];
        
        weatherTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        weatherTextLabel.font = [UIFont systemFontOfSize:18.f];
        weatherTextLabel.textColor = [UIColor whiteColor];
        weatherTextLabel.shadowColor = [UIColor blackColor];
        weatherTextLabel.shadowOffset = CGSizeMake(1.f, 1.f);
        [_weatherAreaView addSubview:weatherTextLabel];
        
        //설정화면에 선택된 언어에 맞춰서 UI의 텍스트를 설정한다.
        [self setAllUIText];
        
        //날씨 더보기 뷰 생성
        showMoreWeatherView = [[WeatherView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        showMoreWeatherView.alpha = 0.f;
        [_mainXibView addSubview:showMoreWeatherView];
        
        //거제 날씨정보...
        [self startConnectionForGetWheatherInfo];
    }
}

//설정화면에 선택된 언어에 맞춰서 UI의 텍스트를 설정한다.
-(void)setAllUIText
{
    NSDictionary *languageInfoDic = [[UTILITY settingView] currenetLanguageDict];
    
    NSArray *textLablesArr = @[_menuLabel1, _menuLabel2, _menuLabel3,
                               _menuLabel4, _menuLabel5, _menuLabel6,
                               _menuLabel7, _menuLabel8];
    NSArray *mainMenuTitleArr = [languageInfoDic objectForKey:@"lk_intro_main_menu_text"];
    
    for(int i = 0; i < textLablesArr.count; i ++)
    {
        UILabel *mainMenuTextLabel = [textLablesArr objectAtIndex:i];
        mainMenuTextLabel.text = [mainMenuTitleArr objectAtIndex:i];
    }
}

#pragma mark - private

//서버통신 시작하기.
-(void)startConnectionForGetWheatherInfo
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = nil;
    connection.tag = 0;
    [connection startConnectionWithUrl:[NSString stringWithFormat:@"%@/index.geoje?contentsSid=8484",BASE_URL]
                              delegate:self
                             queueName:nil];
}

#pragma mark - Button Event

//날씨 더보기 버튼
- (IBAction)pressedShowMoreWeatherBtn:(id)sender
{
    [UTILITY setAlphaAnimationWithView:showMoreWeatherView
                                 alpha:1.f
                            completion:nil];
    
    [showMoreWeatherView reloadCurrentWeatherInfo];
}

//메인화면 버튼 선택시...
- (IBAction)pressedMainMenuBtns:(id)sender
{
    UIButton *btn = sender;

    if([self.delegate respondsToSelector:@selector(introView:didSelectMainMenuIndex:)])
        [self.delegate introView:self didSelectMainMenuIndex:btn.tag];
}

//상단 좌측 사람모양 버튼...
- (IBAction)pressedtopLeftBtn:(id)sender
{
    NSLog(@"마이페이지 버튼 눌려짐!!!");
    
    [UTILITY setAlphaAnimationWithView:[UTILITY settingView]
                                 alpha:1.f
                            completion:nil];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
//    NSLog(@"날씨 result : %@",result);
    
    if(error == nil && result != nil)
    {
        NSDictionary *weatherInfo = [[result objectForKey:@"Weather"] firstObject];
        NSString *cloudiness = [weatherInfo objectForKey:@"SKY"];
        NSString *temperature = [weatherInfo objectForKey:@"PTY"];

        weatherTextLabel.text = [NSString stringWithFormat:@"%@ %@", cloudiness, temperature];

        NSArray *weatherIcoNameArray = @[@"ico_weather_sun",@"ico_weather_cloud_small",@"ico_weather_cloud_many",@"ico_weather_rain",@"ico_weather_snow"];

        int iconNameIndex = 0;

        if([cloudiness isEqualToString:@"흐림"])
            iconNameIndex = 1;

        else if([cloudiness isEqualToString:@"많이흐림"])
            iconNameIndex = 2;

        else if([cloudiness isEqualToString:@"비"])
            iconNameIndex = 3;

        else if([cloudiness isEqualToString:@"눈"])
            iconNameIndex = 4;

        //날씨 아이콘 설정
        weatherImageView.image = [UIImage imageNamed:[weatherIcoNameArray objectAtIndex:iconNameIndex]];
        
        CGSize textSize = [weatherTextLabel.text sizeWithAttributes:@{NSFontAttributeName:[weatherTextLabel font]}];
        CGFloat totalWidth = textSize.width + 40.f;
        
        weatherTextLabel.frame = CGRectMake(_weatherAreaView.bounds.size.width / 2 - (textSize.width - (totalWidth/2)), 0, textSize.width, _weatherAreaView.bounds.size.height);
        weatherImageView.frame = CGRectMake(weatherTextLabel.frame.origin.x - 40, 0, 40, _weatherAreaView.bounds.size.height);
    }
}

@end
