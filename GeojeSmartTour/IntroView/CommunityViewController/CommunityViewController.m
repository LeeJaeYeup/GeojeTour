//
//  CommunityViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 23..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "CommunityViewController.h"
#import <WebKit/WebKit.h>
#import "TheConnection.h"

@interface CommunityViewController ()
<WKNavigationDelegate, TheConnectionDelegate, UIDocumentInteractionControllerDelegate, WKUIDelegate>
{
    WKWebView           *wkWebView;
    TheConnection       *webFileDownloader;
    
    UIDocumentInteractionController *docInteractionController;
}

@property (weak, nonatomic) IBOutlet UIView *topNaviView;
@property (weak, nonatomic) IBOutlet UILabel *topNaviTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation CommunityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _topNaviTitleLabel.text = [[[[UTILITY settingView] currenetLanguageDict] objectForKey:@"lk_intro_main_menu_text"] objectAtIndex:5];
    
    webFileDownloader = [[TheConnection alloc] init];
    webFileDownloader.convertDataToString = NO;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if(wkWebView == nil)
    {
        wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, _topNaviView.frame.origin.y + _topNaviView.frame.size.height, _topNaviView.frame.size.width, self.view.frame.size.height - (_topNaviView.frame.origin.y + _topNaviView.frame.size.height))];
        wkWebView.configuration.dataDetectorTypes = WKDataDetectorTypeAll;
        wkWebView.navigationDelegate = self;
        wkWebView.UIDelegate = self;
        wkWebView.allowsBackForwardNavigationGestures = YES;
        [self.view insertSubview:wkWebView belowSubview:_loadingView];
        
        if(_webViewUrl)
        {
            NSLog(@"_webViewUrl : %@",_webViewUrl);
            [self loadRequestWithUrl:_webViewUrl];
        }
    }
}


#pragma mark - private

-(NSString*)documentFilePathWithTargetStr:(NSString*)target
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSAllDomainsMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:target];
}

//웹 링크 파일 다운로드
-(void)webLinkFileDownloadWithURL:(NSString*)url
{
    [self setHiddenLoadingView:NO];
    NSString *utf8decodedUrlStr = [url stringByRemovingPercentEncoding];
    
    [webFileDownloader startConnectionWithUrl:utf8decodedUrlStr
                                     delegate:self
                                    queueName:nil];
}

//웹 페이지 로드
-(void)loadRequestWithUrl:(NSString*)url
{
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet]]];
    [wkWebView loadRequest:request];
}

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

#pragma mark - button Event

- (IBAction)pressedBackBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSLog(@"Allowing all");
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    CFDataRef exceptions = SecTrustCopyExceptions (serverTrust);
    SecTrustSetExceptions (serverTrust, exceptions);
    CFRelease (exceptions);
    completionHandler (NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"커뮤니티 웹페이지 1");
    
    // 앱 취약점 SSL 예외처리 (http > https)
    NSRange ssl_range = [[navigationAction.request.URL absoluteString] rangeOfString:@"http://"];
    if(ssl_range.location != NSNotFound &&
       ![[navigationAction.request.URL absoluteString] containsString:@"fileSid"] &&
       ![[navigationAction.request.URL absoluteString] containsString:@"docviewer"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        [self loadRequestWithUrl:[[navigationAction.request.URL absoluteString] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
//        NSLog(@"웹뷰 켄슬@@@@@@");
        return;
    }
    
//    NSLog(@"webView.URL.absoluteString : %@",navigationAction.request.URL.absoluteString);
    
    
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
        NSString *urlStr = [navigationAction.request.URL absoluteString];
        
        if([urlStr containsString:@"fileSid"])
        {
            NSLog(@"파일 링크 선택함!!!!!");
//            NSLog(@"urlStr : %@",urlStr);
            decisionHandler(WKNavigationActionPolicyCancel);
            
            //다운로드 중인 파일이 있으면 취소한다.
            [webFileDownloader stopRequest];
            
            // 게시판 다운로드 HTTPS 예외처리 (HTTPS > HTTP)
            NSString *urlChangeHTTPstr = [urlStr stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"];
            
            //파일 다운로드 시작하기.
            [self webLinkFileDownloadWithURL:urlChangeHTTPstr];
            
//            NSLog(@"urlChangeHTTPstr : %@",urlChangeHTTPstr);
            
            return;
        }
        
        NSLog(@"링크 선택함!!!!112233--");
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"커뮤니티 웹페이지 2");
    WKNavigationResponsePolicy wkNaviResponsePolicy =
    WKNavigationResponsePolicyAllow;
    
    decisionHandler(wkNaviResponsePolicy);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSRange range = [[webView.URL absoluteString] rangeOfString:@"about:blank"];
    if(range.location == NSNotFound)
        [self setHiddenLoadingView:NO];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
        NSLog(@"didCommitNavigation");
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

#pragma mark - WKWebView UIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"알림"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"확인"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler();
                                                      }]];
    
    [[UTILITY rootViewControllerPtr] presentViewController:alertController
                                                  animated:YES
                                                completion:nil];
                                          
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"알림"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"확인"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(YES);
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"취소"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(NO);
                                                      }]];
    
    [[UTILITY rootViewControllerPtr] presentViewController:alertController
                                                  animated:YES
                                                completion:nil];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
        NSDictionary *fileHeaderInfo = connection.allHeaderFields;
        
        NSString *fileInfoStr = [fileHeaderInfo objectForKey:@"Content-Disposition"];
        NSString *fileExtenstion = [fileInfoStr pathExtension];
//        NSLog(@"fileExtenstion : %@",fileExtenstion);
        
        if(fileExtenstion == nil)
        {
            [wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:connection.requestUrl]]];
            return;
        }
        
        //도큐멘트 파일저장 경로
        NSString *filePath = [self documentFilePathWithTargetStr:[NSString stringWithFormat:@"temp.%@",fileExtenstion]];
        
//        NSLog(@"filePath : %@",filePath);
        
        BOOL isWrite = [result writeToFile:filePath atomically:YES];
        
        if(isWrite == YES)
        {
            NSURL *resultURL = [NSURL fileURLWithPath:filePath];
            
            docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:resultURL];
            docInteractionController.delegate = self;
            BOOL canOpenMenu = [docInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:NO];
            
            if(canOpenMenu == NO)
            {
                NSLog(@"도큐먼트 인터렉션 컨트롤러 메뉴를 열수가 없음.");
                [UTILITY makeAlertWithTitle:@"알림"
                                    message:@"선택한 파일을 열수있는 앱이 설치되어 있지 않습니다."
                             viewController:UTILITY.rootViewControllerPtr];
            }
        }
    }
    
    [self setHiddenLoadingView:YES];
}

#pragma mark - UIDocumentInteractionController Delegate

- (void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller
{
    
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{

}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(nullable NSString *)application
{

}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(nullable NSString *)application
{

}

@end
