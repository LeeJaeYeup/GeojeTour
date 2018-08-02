//
//  DBInterFace.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 21..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBInterFace : NSObject
-(instancetype)initWithDataBaseFilename:(NSString*)databaseFilename;
-(void)createTableWithQuery:(NSString*)queryStr;
-(void)removeTableWithName:(NSString*)name;
-(void)insertToTableName:(NSString*)tableName query:(NSString*)queryStr insertData:(NSDictionary*)insertDict insertColumnSequenceArray:(NSArray*)columnSequenceArr;
-(void)createSqlFile;
-(NSArray*)selectAllWithTableName:(NSString *)name where:(NSString*)whereStr;
-(NSArray*)selectWithColumns:(NSArray*)selectColumns WithTableName:(NSString *)name where:(NSString*)whereStr distinct:(BOOL)bDistinct;
-(BOOL)updateWithTableName:(NSString *)name values:(NSDictionary*)valueDict where:(NSString*)where;
-(void)deleteRowWithTableName:(NSString *)tblName where:(NSString*)where;

@end
