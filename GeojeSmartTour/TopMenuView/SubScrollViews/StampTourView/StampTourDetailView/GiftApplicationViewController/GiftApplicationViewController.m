//
//  GiftApplicationViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 19..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "GiftApplicationViewController.h"
#import "TheConnection.h"
#import "TopLogoView.h"
#import <WebKit/WebKit.h>
#import "GetPostNumView.h"


#define kUrlRequestGift          [NSString stringWithFormat:@"%@/user/smartbeacon/push/stampApplyInit.geoje?",BASE_URL]


@interface GiftApplicationViewController ()
<UITextFieldDelegate, TheConnectionDelegate, GetPostNumViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *cosNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *postNumberTextField;
@property (weak, nonatomic) IBOutlet UIButton *postNumberSearchBtn;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNum01TextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNum02TextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNum03TextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation GiftApplicationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.cosNameLabel.text = self.cosName;
    
    TopLogoView *topLogoView = [[UTILITY objectSaveDictionary] objectForKey:@"TopLogoView"];
    [topLogoView showBackBtnView:YES action:@selector(pressedTopBackBtn) target:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    TopLogoView *topLogoView = [[UTILITY objectSaveDictionary] objectForKey:@"TopLogoView"];
    [topLogoView showBackBtnView:NO action:@selector(pressedTopBackBtn) target:self];
}

#pragma mark -

- (IBAction)pressedBackBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - private

//서버통신 시작하기.
-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

#pragma mark - Button Event

//우편번호 검색버튼
- (IBAction)pressedPostNumBtn:(id)sender
{
    GetPostNumView *getPostNumView = [[GetPostNumView alloc] initWithFrame:self.view.bounds];
    getPostNumView.delegate = self;
    [self.view addSubview:getPostNumView];
    getPostNumView.alpha = 0.f;
    
    [UTILITY setAlphaAnimationWithView:getPostNumView
                                 alpha:1.f
                            completion:nil];
}

//화면상단 뒤로가기 버튼
-(void)pressedTopBackBtn
{
    [self.navigationController popViewControllerAnimated:YES];
}

//선물 신청하기 버튼
- (IBAction)pressedApplyGiftBtn:(id)sender
{
    NSLog(@"선물 신청하기 버튼눌림!!!!");
    
    NSString *uuid = [UTILITY UUID];
    NSString *name = _nameTextField.text;
    NSString *addr = [NSString stringWithFormat:@"주소 : %@, 우편번호 : %@", _addressTextField.text, _postNumberTextField.text];
    
    if([name length] == 0 || [addr length] == 0 || [_phoneNum01TextField.text length] == 0 || [_phoneNum02TextField.text length] == 0 || [_phoneNum03TextField.text length] == 0)
    {
        [UTILITY makeAlertWithTitle:@"알림"
                            message:@"입력되지 않은 항목이 있습니다.확인 후 다시 시도해 주세요."
                     viewController:UTILITY.rootViewControllerPtr];
        
        return;
    }
    
    NSString *tel = [NSString stringWithFormat:@"%@-%@-%@",_phoneNum01TextField.text,_phoneNum02TextField.text,_phoneNum03TextField.text];
    NSLog(@"cateCd : %@",_cateCd);
    
    NSString *url =
        [NSString stringWithFormat:@"%@uuid=%@&cateCd1=%@&name=%@&addr=%@&tel=%@",kUrlRequestGift,uuid,_cateCd,name,addr,tel];

//    NSLog(@"선물 신청하기 url : %@",url);

    [self startConnectionWithURL:url
                             tag:0
                      identifier:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    //4인치 이하 기기에서만....
    if(screenHeight <= 568)
    {
        CGFloat scrollyOffset = 100;
        
        if(textField == _phoneNum01TextField ||
           textField == _phoneNum02TextField ||
           textField == _phoneNum03TextField)
        {
            scrollyOffset = 150;
        }
        else if(textField == _addressTextField)
        {
            
        }
        
        [_scrollView setContentOffset:CGPointMake(0, scrollyOffset) animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"완료버튼 눌림!!");
    [textField resignFirstResponder];
    
    if(_scrollView.contentOffset.y != 0)
       [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    return YES;
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
        NSDictionary *resultDict = result;
        NSString *resultMessage = [resultDict objectForKey:@"msg"];
        
        [UTILITY makeAlertWithTitle:@"알림"
                            message:resultMessage
                     viewController:UTILITY.rootViewControllerPtr];
        
        if([[resultDict objectForKey:@"result"] isEqualToString:@"Y"])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
        
}

#pragma mark - GetPostNumView Delegate

-(void)getPostNumView:(GetPostNumView*)gpnView didFinishGetPostNum:(NSDictionary*)postInfo
{
    NSString *addr = [postInfo objectForKey:@"addr"];           //주소
    NSString *postcode = [postInfo objectForKey:@"postcode"];   //구 우편번호
    NSString *zonecode = [postInfo objectForKey:@"zonecode"];   //새 우편번호
    
    _postNumberTextField.text = [NSString stringWithFormat:@"%@ (구 : %@)",zonecode, postcode];
    _addressTextField.text = addr;
    
    [gpnView removeFromSuperview];
    gpnView = nil;
}

-(void)didSelectCloseBtnWithPostNumView:(GetPostNumView*)gpnView
{
    [gpnView removeFromSuperview];
    gpnView = nil;
}

@end
