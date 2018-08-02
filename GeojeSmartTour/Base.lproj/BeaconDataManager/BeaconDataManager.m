//
//  BeaconDataManager.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 21..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "BeaconDataManager.h"
#import "TheConnection.h"
#import "ViewController.h"

typedef NS_ENUM(NSUInteger, ConnectionType)
{
    ConnectionTypeGetAllBeaconData,
    ConnectionTypeGetOneBeaconData
};

#define kUrlForGetAllBeaconData     [NSString stringWithFormat:@"%@/cms/beacon/openapi_beaconAll.sko",BASE_URL]

@interface BeaconDataManager () <TheConnectionDelegate>
@end

@implementation BeaconDataManager

-(id)init
{
    if(self = [super init])
    {
        _dbInterface = [[DBInterFace alloc] initWithDataBaseFilename:@"geojeDB"];
        [_dbInterface createSqlFile];
        
        //검색된 비콘 히스토리 table 생성
        NSString *detectBeaconHistoryTableMakeQuery = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (id INTEGER PRIMARY KEY AUTOINCREMENT, detectDate TEXT, beaconFullPathLink TEXT, beaconResearchTime TEXT, beaconNotiShowingYN TEXT, stampOrCouponYN TEXT, couponUseYN TEXT, couponUseDate TEXT, groupSid TEXT)",kTableNameDetectedBeaconHistory];
        
        [_dbInterface createTableWithQuery:detectBeaconHistoryTableMakeQuery];
    }
    
    return self;
}

-(void)getAllBeaconDataWithVersion:(NSString*)version
{
    //모든 비콘 데이터 가져오기
    NSLog(@"모든비콘 데이터 다운로드 url : %@",kUrlForGetAllBeaconData);
    
    [self startConnectionWithURL:kUrlForGetAllBeaconData
                             tag:ConnectionTypeGetAllBeaconData
                      identifier:version];
}

#pragma mark -

-(void)startConnectionWithURL:(NSString*)url tag:(NSInteger)tag identifier:(id)identifier
{
    TheConnection *connection = [[TheConnection alloc] init];
    connection.identifier = identifier;
    connection.tag = tag;
    [connection startConnectionWithUrl:url delegate:self queueName:nil];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    ConnectionType connType = connection.tag;
    
    if(error == nil)
    {
        //모든비콘 데이터 받아오기
        if(connType == ConnectionTypeGetAllBeaconData)
        {
//            NSLog(@"모든비콘 데이터 result : %@",result);
            NSLog(@"모든비콘수량 : %ld",[[result objectForKey:@"RFCBeaconData"] count]);
            
            NSArray *beaconDataArr = [result objectForKey:@"RFCBeaconData"];
            
            if([beaconDataArr count] > 0)
            {
                //데이터를 DB에 저장한다.
                NSLog(@"sql 테이블 컬럼 숫자 : %ld",[[[beaconDataArr objectAtIndex:0] allKeys] count]);
                
                //딕셔너리 키값을 테이블 필드값으로 사용한다...
                NSArray *allKeysArr = [[beaconDataArr objectAtIndex:0] allKeys];
                
                NSString *tableName = kTableNameAllBeacon;

                NSMutableString *queryStr = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@'",tableName]];
                
                for(int i = 0; i < allKeysArr.count; i ++)
                {
//                    NSLog(@"테이블 컬럼명 : %@",[allKeysArr objectAtIndex:i]);
                    
                    if(i == 0)
                       [queryStr appendString:@"(id INTEGER PRIMARY KEY AUTOINCREMENT, "];

                    [queryStr appendString:[NSString stringWithFormat:@"%@ TEXT",[allKeysArr objectAtIndex:i]]];
                    
                    //마지막이다..
                    if(i == allKeysArr.count - 1)
                    {
                        [queryStr appendString:@");"];
                    }
                    else
                    {
                        [queryStr appendString:@", "];
                    }
                    
//                    NSLog(@"queryStr 112233 : %@",queryStr);
                    
                } //end of for
                
                //기존 테이블은 삭제...
                [_dbInterface removeTableWithName:tableName];

//                NSLog(@"모든비콘 테이블 생성 queryStr : %@",queryStr);
                
                //테이블 생성하기!!
                [_dbInterface createTableWithQuery:queryStr];
                
                //데이터 집어넣기
                [queryStr deleteCharactersInRange:NSMakeRange(0, [queryStr length])];
                [queryStr appendFormat:@"INSERT INTO %@ ",tableName];
                
                NSMutableString *columnsString = [[NSMutableString alloc] init];
                NSMutableString *valuesString = [[NSMutableString alloc] init];
                
                //컬럼숫자..
                NSInteger columnCount = allKeysArr.count;
                
                for(int i = 0; i < columnCount; i ++)
                {
                    //처음
                    if(i == 0)
                    {
                        [valuesString appendString:@"("];
                        [columnsString appendFormat:@"("];
                    }
                    //마지막
                    else if(i == (columnCount - 1))
                    {
                        [valuesString appendString:@"?)"];
                        [columnsString appendFormat:@"%@)",[allKeysArr objectAtIndex:i]];
                    }
                    
                    if(i < (columnCount -1) )
                    {
                        [columnsString appendFormat:@"%@,",[allKeysArr objectAtIndex:i]];
                        [valuesString appendString:@"?,"];
                    }
                }
                
                [queryStr appendFormat:@"%@ VALUES %@",columnsString, valuesString];
                
//                NSLog(@"insert queryStr : %@",queryStr);
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{

                    for(int i = 0; i < [beaconDataArr count]; i ++)
                    {
                        NSDictionary *beaconDataInfo = [beaconDataArr objectAtIndex:i];

                        //db에 인서트 하기...
                        [_dbInterface insertToTableName:tableName
                                                  query:queryStr
                                             insertData:beaconDataInfo
                              insertColumnSequenceArray:nil];
                        
                        //여기서 진행사항을 알려줘야 될듯?
                        if([self.delegate respondsToSelector:@selector(beaconDataManager:didProgressInsertInDbWithIndex:totalCount:)])
                        {
                            [self.delegate beaconDataManager:self didProgressInsertInDbWithIndex:i + 1 totalCount:(int)[beaconDataArr count]];
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        //모든비콘 데이터 다운로드 완료시 호출....
                        if([self.delegate respondsToSelector:@selector(didFinishGetAllBeaconData:beaconVersion:)])
                            [self.delegate didFinishGetAllBeaconData:self beaconVersion:connection.identifier];
                    });
                });
                
            }
            else
            {
                NSLog(@"비콘 데이터 개수가 0!!");
                
            } // end of inner if
            
        } //end of second if
    
    } //end of first if
}

@end
