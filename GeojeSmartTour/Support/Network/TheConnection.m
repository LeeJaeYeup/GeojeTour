//
//  TheConnection.m
//  UiryeongBeacon
//
//  Created by Skoinfo on 2016. 3. 8..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import "TheConnection.h"
#import "SBJSON.h"

@interface TheConnection ()

@property (nonatomic, strong) NSString *queueIdentifier;

@end

@implementation TheConnection

#pragma mark - public

-(id)init
{
    if(self = [super init])
    {
        self.convertDataToString = YES;
        receiveData = [[NSMutableData alloc] init];
        self.identifier = nil;
    }
    
    return self;
}

//POST 방식
-(void)startConnectionWithUrl:(NSString*)urlStr delegate:(id)delegate postData:(NSDictionary*)data queueName:(NSString*)name
{
    if([name length] > 0)
    {
        self.queueIdentifier = name;
    }
    
    [self stopRequest];
    
    NSCharacterSet *encodingSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    
    _requestUrl = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:encodingSet];
    
    self.delegate = delegate;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                   delegate:self
                                              delegateQueue:[NSOperationQueue mainQueue]];

    NSURL *url = [NSURL URLWithString:_requestUrl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:15.0f];
    [urlRequest setHTTPMethod:@"POST"];
    
    if(data)
    {
        // 임시 변수 선언
        NSMutableArray *parts = [NSMutableArray array];
        NSString *part;
        id key;
        id value;
        
        // 값을 하나하나 변환
        for(key in data)
        {
            value = [data objectForKey:key];
            NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:encodingSet];
            NSString *encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:encodingSet];
            
            part = [NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue];

            
            [parts addObject:part];
        }
        
        // 값들을 &로 연결하여 Body에 사용
        [urlRequest setHTTPBody:[[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    dataTask = [defaultSession dataTaskWithRequest:urlRequest];
    [dataTask resume];
}

//GET방식
-(void)startConnectionWithUrl:(NSString*)urlStr delegate:(id)delegate queueName:(NSString*)name;
{
    if([name length] > 0)
    {
        self.queueIdentifier = name;
    }
    
    [self stopRequest];
    
    _requestUrl = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    self.delegate = delegate;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                   delegate:self
                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:_requestUrl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    dataTask = [defaultSession dataTaskWithRequest:urlRequest];
    [dataTask resume];
}

-(void)stopRequest
{
    if(dataTask != nil)
    {
        [receiveData setData:[NSData dataWithBytes:nil length:0]];
        [dataTask cancel];
        dataTask = nil;
        [defaultSession finishTasksAndInvalidate];
        defaultSession = nil;
        self.error = nil;
    }
}

#pragma mark - NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    self.allHeaderFields = httpResponse.allHeaderFields;
    NSLog(@"allHeaderFields : %@",self.allHeaderFields);
    
    //콘텐츠 길이 (-1을 리턴해줄 경우 컨텐츠 길이를 알 수 없음.)
    long long contentLength = [response expectedContentLength];
//    NSLog(@"contentLength : %lld",contentLength);
    
//    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields
//                                                              forURL:response.URL];
//    for(NSHTTPCookie *cookie in cookies)
//    {
//        NSLog(@"name : %@",cookie.name);
//        NSLog(@"value : %@",cookie.value);
//        NSLog(@"domain : %@",cookie.domain);
//        NSLog(@"path : %@",cookie.path);
//    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [receiveData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    self.error = error;
    
    id  resultData = nil;
    
    if(error == nil)
    {
        if(self.convertDataToString == YES)
        {
            NSString *resultStr = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
            SBJsonParser*   parser = [SBJsonParser new];
            resultData = [parser objectWithString:resultStr];
        }
        else
            resultData = [receiveData copy];
    }
    else
    {
//        NSLog(@"URLSession Error %@",[error userInfo]);
    }
    
    if([self.delegate respondsToSelector:@selector(theConnection:didFinishConnectionWithResult:error:)])
    {
        [self.delegate theConnection:self didFinishConnectionWithResult:resultData error:error];
    }
    
    if([self.endDelegate respondsToSelector:@selector(theConnection:didFinishConnectionWithQueueId:isCanceled:)])
    {
        BOOL canceled = [error code] == -999;
        [self.endDelegate theConnection:self didFinishConnectionWithQueueId:self.queueIdentifier isCanceled:canceled];
    }

    //통신실패시...
    if(error != nil && [error code] != -999)
    {
        [self stopRequest];
        [UTILITY showToastWithText:@"인터넷 상태가 오프라인 이거나 서버에서 응답이 없습니다.\n잠시후 다시 시도해 주세요."
                          duration:6];
    }
}

-(void)dealloc
{
    [self stopRequest];
}

@end
