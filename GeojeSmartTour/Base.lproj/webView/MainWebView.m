//
//  WebView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 20..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "MainWebView.h"
#import <WebKit/WebKit.h>

@interface MainWebView () <WKNavigationDelegate>
{
    WKWebView *wkWebView;
}

@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (weak, nonatomic) IBOutlet UIView *webViewSafeAreaView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation MainWebView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"MainWebView" owner:self options:nil];
        [_mainXibView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_mainXibView];
        [_mainXibView layoutIfNeeded];

        wkWebView = [[WKWebView alloc] initWithFrame:_webViewSafeAreaView.frame];
        wkWebView.configuration.dataDetectorTypes = WKDataDetectorTypeAll;
        wkWebView.navigationDelegate = self;
        wkWebView.allowsBackForwardNavigationGestures = YES;
        [_webViewSafeAreaView addSubview:wkWebView];
        
        [_loadingView.superview bringSubviewToFront:_loadingView];
    }
    
    return self;
}

#pragma mark - private

//로딩뷰 숨김설정하기
-(void)setHiddenLoadingView:(BOOL)bHidden
{
    self.loadingView.hidden = bHidden;
    
    if(bHidden)
        [self.loadingIndicator stopAnimating];
    else
    {
        [self.loadingIndicator startAnimating];
    }
}

#pragma mark - Button event

//하단탭바 버튼 이벤트
- (IBAction)pressedBottomTabBtns:(id)sender
{
    UIButton *btn = sender;
    NSInteger btnTag = btn.tag;
    
    if(btnTag == 0)
        [wkWebView goBack];
    else if(btnTag == 1)
        [wkWebView goForward];
    //홈으로..
    else if(btnTag == 2)
    {
        [self loadRequestWithUrl:_homeUrlStr];
    }
    else if(btnTag == 3)
        [wkWebView reload];
    //닫기
    if(btnTag == 4)
    {
        __weak typeof(self) weakSelf = self;
        
        [self setHidden:YES completion:^(BOOL finished)
        {
            [weakSelf loadRequestWithUrl:@"about:blank"];
        }];
    }
}

#pragma mark - override

-(void)setHidden:(BOOL)hidden completion:(void (^ __nullable)(BOOL finished))completion
{
    CGFloat             alpha = 0.f;
    if(hidden == NO)    alpha = 1.f;
    
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:alpha
                            completion:completion];
}

#pragma mark - public

//웹 페이지 로드
-(void)loadRequestWithUrl:(NSString* __nonnull)url
{
//    NSLog(@"메인웹뷰 url : %@",url);
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet]]];
    [wkWebView loadRequest:request];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
        NSLog(@"링크 선택함!!!!");
        NSString *linkUrl = [[navigationAction.request.URL absoluteString] stringByRemovingPercentEncoding];
        NSRange range = [linkUrl rangeOfString:@"map.daum.net/link"];
        
        //다음 길찾기 링크 선택시...
        if(range.location != NSNotFound)
        {
            NSLog(@"링크선택 Url : %@",linkUrl);
            
            range = [linkUrl rangeOfString:@","];
            
            if(range.location != NSNotFound)
            {
                linkUrl = [linkUrl substringFromIndex:range.location + 1];
                NSArray *xyPosArr = [linkUrl componentsSeparatedByString:@","];
                
                NSString *xPos = [xyPosArr firstObject];
                NSString *yPos = [xyPosArr lastObject];
                
                NSString *userxPos = [NSString stringWithFormat:@"%lf",UTILITY.locationManager.location.coordinate.latitude];
                NSString *useryPos = [NSString stringWithFormat:@"%lf",UTILITY.locationManager.location.coordinate.longitude];
                
                NSString *url = [[NSString stringWithFormat:@"daummaps://route?sp=%@,%@&ep=%@,%@&by=CAR",userxPos, useryPos, xPos, yPos] stringByReplacingOccurrencesOfString:@" " withString:@""];;
                
                NSLog(@"길찾기 url2 : %@",url);
                
                NSURL *routeUrl = [NSURL URLWithString:url];
                
                if([[UIApplication sharedApplication] canOpenURL: routeUrl] == NO)
                {
                    routeUrl = [NSURL URLWithString:@"https://itunes.apple.com/kr/app/da-eum-jido-gilchajgi-jihacheol/id304608425?mt=8"];
                }
                
                [[UIApplication sharedApplication] openURL:routeUrl
                                                   options:@{}
                                         completionHandler:nil];
            }
            
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    WKNavigationResponsePolicy wkNaviResponsePolicy =
    WKNavigationResponsePolicyAllow;
    
    NSString *urlStr = [webView.URL absoluteString];
    
    if([urlStr rangeOfString:@"file"].location != NSNotFound)
    {
        NSLog(@"파일 다운로드 링크 선택함!!!");
    }
    
    decisionHandler(wkNaviResponsePolicy);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
//    NSLog(@"didStartProvisionalNavigation");
    NSRange range = [[webView.URL absoluteString] rangeOfString:@"about:blank"];
    if(range.location == NSNotFound)
        [self setHiddenLoadingView:NO];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
//    NSLog(@"didCommitNavigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
//    NSLog(@"didFinishNavigation");
    [self setHiddenLoadingView:YES];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
//    NSLog(@"didFailNavigation : error : %@",error);
    [self setHiddenLoadingView:YES];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    //웹 컨텐츠 로딩 시작중에 중단되면 호출됨(컨텐츠 로드 중지 시키면 호출됨)
//    NSLog(@"didFailProvisionalNavigation : error : %@",error);
    [self setHiddenLoadingView:YES];
}

@end
