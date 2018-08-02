//
//  GetPostNumView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 27..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "GetPostNumView.h"
#import <WebKit/WebKit.h>

@interface GetPostNumView () <WKScriptMessageHandler, WKNavigationDelegate>
{
    UIActivityIndicatorView *indicatorView;
}
@end

@implementation GetPostNumView 

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        UIView *topMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 40)];
        topMenuView.backgroundColor = [UIColor colorWithRed:0.871f green:0.918f blue:0.957f alpha:1.f];
        [self addSubview:topMenuView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:topMenuView.bounds];
        [topMenuView addSubview:label];
        label.text = @"주소 검색";
        [label setTextAlignment:NSTextAlignmentCenter];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(5, 0, 50, topMenuView.frame.size.height);
        [btn setTitle:@"닫기" forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(pressedCloseBtn) forControlEvents:UIControlEventTouchUpInside];
        [topMenuView addSubview:btn];
        
        WKUserContentController *contentController = [[WKUserContentController alloc] init];
        [contentController addScriptMessageHandler:self name:@"callBackHandler"];
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = contentController;
        
        WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(topMenuView.frame.origin.x, topMenuView.frame.origin.y + topMenuView.frame.size.height, topMenuView.frame.size.width, frame.size.height - (topMenuView.frame.origin.y + topMenuView.frame.size.height))
                                                  configuration:config];
        
        wkWebView.configuration.dataDetectorTypes = WKDataDetectorTypeAll;
        wkWebView.navigationDelegate = self;
        wkWebView.allowsBackForwardNavigationGestures = YES;
        [self addSubview:wkWebView];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://poleem.github.io/daumPostNumApi/"]];
        
        [wkWebView loadRequest:request];
        
        indicatorView = [[UIActivityIndicatorView alloc]
                         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.frame = CGRectMake(frame.size.width / 2 - 20, frame.size.height / 2 - 20, 40, 40);
        [indicatorView setHidesWhenStopped:YES];
        [self addSubview:indicatorView];
    }
    
    return self;
}

#pragma mark -

-(void)pressedCloseBtn
{
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:0.f
                            completion:^(BOOL finished)
     {
         if(finished)
             if([self.delegate respondsToSelector:@selector(didSelectCloseBtnWithPostNumView:)])
                 [self.delegate didSelectCloseBtnWithPostNumView:self];
     }];
    
    NSLog(@"닫기");
    
}

#pragma mark - WKScriptMessageHandler Delegate

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [UTILITY setAlphaAnimationWithView:self
                                 alpha:0.f
                            completion:^(BOOL finished)
     {
         if(finished)
             if([self.delegate respondsToSelector:@selector(getPostNumView:didFinishGetPostNum:)])
                 [self.delegate getPostNumView:self didFinishGetPostNum:message.body];
     }];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    WKNavigationResponsePolicy wkNaviResponsePolicy =
    WKNavigationResponsePolicyAllow;
    
    decisionHandler(wkNaviResponsePolicy);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
//    NSLog(@"didStartProvisionalNavigation");
    [indicatorView startAnimating];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
//    NSLog(@"didCommitNavigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
//    NSLog(@"didFinishNavigation");
    [indicatorView stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
//    NSLog(@"didFailNavigation : error : %@",error);
    [indicatorView stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    //웹 컨텐츠 로딩 시작중에 중단되면 호출됨(컨텐츠 로드 중지 시키면 호출됨)
//    NSLog(@"didFailProvisionalNavigation : error : %@",error);
    [indicatorView stopAnimating];
}

@end
