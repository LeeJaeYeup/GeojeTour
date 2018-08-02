//
//  TopLogoView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 15..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "TopLogoView.h"

@interface TopLogoView ()
{
    UIButton    *selectedMenuBtn;
}
@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (weak, nonatomic) IBOutlet UIButton *firstMenuBtn;
@property (weak, nonatomic) IBOutlet UIButton *secondMenuBtn;
@property (weak, nonatomic) IBOutlet UIButton *thirdMenuBtn;
@property (weak, nonatomic) IBOutlet UIButton *fourthMenuBtn;

@property (weak, nonatomic) IBOutlet UIView *backBtnView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@end

@implementation TopLogoView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        //xib뷰 불러와서 뷰에 올리기
        [[NSBundle mainBundle] loadNibNamed:@"TopLogoView" owner:self options:nil];
        [_mainXibView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_mainXibView];
        
        selectedMenuBtn = _firstMenuBtn;
        
        //객체 포인터 저장하기...
        [[UTILITY objectSaveDictionary] setObject:self forKey:@"TopLogoView"];
    }
    
    return self;
}

-(void)showBackBtnView:(BOOL)bShow action:(SEL)backBtnAction target:(id)target
{
    if(bShow)
    {
        if(target)
            [_backBtn addTarget:target action:backBtnAction forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        if(target)
            [_backBtn removeTarget:target action:backBtnAction forControlEvents:UIControlEventTouchUpInside];
    }

    _backBtnView.hidden = !bShow;
}

//상단탭바 선택하기
-(void)setSelectTabbarBtnWithIndex:(NSInteger)index
{
    if(index < 0 || index > 3)      return;
    
    NSInteger prevSelectedBtnTag = selectedMenuBtn.tag;
    
    [self setTabMenuBtnEnableWithIndex:prevSelectedBtnTag enable:NO];
    [self setTabMenuBtnEnableWithIndex:index enable:YES];
    
    NSArray *btns = @[_firstMenuBtn, _secondMenuBtn, _thirdMenuBtn, _fourthMenuBtn];
    
    selectedMenuBtn = [btns objectAtIndex:index];
}

#pragma mark - private

//상단탭바 버튼 눌림설정
-(void)setTabMenuBtnEnableWithIndex:(NSInteger)index enable:(BOOL)enable
{
    if(index < 0 || index > 3)      return;
    
    NSArray *btns = @[_firstMenuBtn, _secondMenuBtn, _thirdMenuBtn, _fourthMenuBtn];
    UIButton *btn = [btns objectAtIndex:index];
    [btn setSelected:enable];
}

#pragma mark - Button Event

- (IBAction)pressedLeftMenuBtn:(id)sender
{
    NSLog(@"상단로고 뒤로가기 버튼 눌림1");
    
//    [UTILITY setAlphaAnimationWithView:[UTILITY settingView]
//                                 alpha:1.f
//                            completion:nil];
    
    if([self.delegate respondsToSelector:@selector(didSelectTopLogoWithLogoView:)])
        [self.delegate didSelectTopLogoWithLogoView:self];
}

//상단 로고 버튼눌림
- (IBAction)pressedTopLogoBtn:(id)sender
{
    if([self.delegate respondsToSelector:@selector(didSelectTopLogoWithLogoView:)])
        [self.delegate didSelectTopLogoWithLogoView:self];
}

//상단탭바 버튼 눌림.
- (IBAction)pressedTopMenuBtns:(id)sender
{
    UIButton *btn = sender;
    
    [selectedMenuBtn setSelected:NO];
    [btn setSelected:YES];
    
    selectedMenuBtn = btn;
    
    if([self.delegate respondsToSelector:@selector(topLogoView:didSelectMenuWithIndex:)])
        [self.delegate topLogoView:self didSelectMenuWithIndex:btn.tag];
}

@end
