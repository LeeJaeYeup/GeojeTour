//
//  TheConnection.h
//  UiryeongBeacon
//
//  Created by Skoinfo on 2016. 3. 8..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

@protocol TheConnectionDelegate;
@protocol TheConnectionEndDelegate;

@interface TheConnection : NSObject <NSURLSessionDelegate>
{
    NSMutableData *receiveData;
    NSURLSession *defaultSession;
    NSURLSessionDataTask *dataTask;
}

@property (weak, nonatomic) id <TheConnectionDelegate> delegate;
@property (weak, nonatomic) id <TheConnectionEndDelegate> endDelegate;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) BOOL convertDataToString;     //default YES
@property (nonatomic, strong) id identifier;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, readonly) NSString *requestUrl;
@property (nonatomic, strong) NSDictionary *info;
@property (nonatomic, strong) NSDictionary *allHeaderFields;

-(void)startConnectionWithUrl:(NSString*)urlStr delegate:(id)delegate queueName:(NSString*)name;
-(void)startConnectionWithUrl:(NSString*)urlStr delegate:(id)delegate postData:(NSDictionary*)data queueName:(NSString*)name;
-(void)stopRequest;

@end

@protocol TheConnectionDelegate <NSObject>

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error;

@end

@protocol TheConnectionEndDelegate <NSObject>

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithQueueId:(NSString*)queueId isCanceled:(BOOL)canceled;

@end
