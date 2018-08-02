//
//  DBInterFace.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 21..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "DBInterFace.h"
#import <sqlite3.h>

@interface DBInterFace ()
{
    sqlite3 *db;
}

@property (nonatomic, strong) NSString *dbFileName;
@end

@implementation DBInterFace

-(instancetype)initWithDataBaseFilename:(NSString*)databaseFilename
{
    if(self = [super init])
    {
        self.dbFileName = databaseFilename;
    }
    return self;
}

//sql파일 생성하기
-(void)createSqlFile
{
    NSString *dbPath = [self dbPath];
    
    NSFileManager *fm = [NSFileManager new];
    
    if([fm fileExistsAtPath:dbPath isDirectory:nil])
    {
        NSLog(@"Database already exists..");
        return;
    }
    
    if(sqlite3_open([dbPath UTF8String],&db) == SQLITE_OK)
    {
        NSLog(@"sql 파일생성 성공함!!!");
    }
    else
    {
        NSLog(@"sql 파일생성 실패함!! ㅠㅠ");
    }
    
    sqlite3_close(db);
}

//테이블 만들기
-(void)createTableWithQuery:(NSString*)queryStr
{
    [self openDB];
    
    char *err;
    if(sqlite3_exec(db, [queryStr UTF8String], NULL, NULL, &err) != SQLITE_OK)
    {
       
        NSAssert(0, @"Tabled failed to create.");
    }
    else
    {
        NSLog(@"%@ 테이블 생성 완료!!",queryStr);
    }
    
    sqlite3_close(db);
}

//테이블 삭제
-(void)removeTableWithName:(NSString*)name
{
    [self openDB];
    
    NSString *query = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",name];
    
    char *err;
    
    if (sqlite3_exec(db, [query UTF8String], NULL, NULL, &err) != SQLITE_OK)
    {
        NSAssert(0, @"Tabled2 failed to delete.");
    }
    else
    {
        NSLog(@"%@ 테이블 삭제 완료!!",name);
    }
    
    sqlite3_close(db);
}

-(void)insertToTableName:(NSString*)tableName query:(NSString*)queryStr insertData:(NSDictionary*)insertDict insertColumnSequenceArray:(NSArray*)columnSequenceArr
{
    [self openDB];
    
//    NSLog(@"insertDict : %@",insertDict);
 
    sqlite3_stmt* statement;
    
    if(sqlite3_prepare_v2(db, [queryStr UTF8String], -1, &statement, NULL) == SQLITE_OK)
    {
        for(int i = 0; i < insertDict.allKeys.count; i ++)
        {
            int columnNum = i + 1;
            NSString *columnName = [insertDict.allKeys objectAtIndex:i];
            
            if(columnSequenceArr.count == insertDict.allKeys.count)
                columnName = [columnSequenceArr objectAtIndex:i];
            
//            NSLog(@"columnName : %@",columnName);
            NSString *insertData = [NSString stringWithFormat:@"%@",[insertDict objectForKey:columnName]];

            if(insertData == nil || [insertData length] == 0)
                insertData = @"0";

            sqlite3_bind_text(statement, columnNum, [insertData UTF8String], -1, SQLITE_TRANSIENT);
        }

        sqlite3_step(statement);
    }
    else NSLog( @"insert query : %@\nFailed from sqlite3_prepare_v2. Error is:  %s", queryStr ,sqlite3_errmsg(db) );
    
    // Finalize and close database.
    sqlite3_finalize(statement);
    sqlite3_close(db);
}

-(NSArray*)selectAllWithTableName:(NSString *)name where:(NSString*)whereStr
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    sqlite3* db = NULL;
    sqlite3_stmt* stmt = NULL;
    int rc = 0;
    rc = sqlite3_open_v2([[self dbPath] UTF8String], &db, SQLITE_OPEN_READONLY , NULL);
    if(SQLITE_OK != rc)
    {
        sqlite3_close(db);
        NSLog(@"Failed to open db connection");
    }
    else
    {
        NSString *query = [NSString stringWithFormat:@"SELECT * from %@",name];
        
        if(whereStr)
            query = [query stringByAppendingFormat:@" %@",whereStr];
        
//        NSLog(@"select query : %@",query);
        
        rc = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL);
        if(rc == SQLITE_OK)
        {
            while(sqlite3_step(stmt) == SQLITE_ROW) //get each row in loop
            {
                NSMutableDictionary *pDict = [[NSMutableDictionary alloc] init];
                int index = 0;
                
                while(YES)
                {
                    const char *columnNameChar = sqlite3_column_name(stmt, index);
                    const unsigned char *valueChar = sqlite3_column_text(stmt, index);
                    
                    if(valueChar == nil)
                        break;
                    
                    NSString *value = [NSString stringWithUTF8String:(const char *)valueChar];
                    NSString *columnName = [NSString stringWithUTF8String:(const char *)columnNameChar];
                    
                    [pDict setObject:value forKey:columnName];
                    index ++;
                }
                
                [resultArray addObject:pDict];
            }
            
            sqlite3_finalize(stmt);
        }
        else
        {
            NSLog(@"select Failed to prepare statement, rc : %d",rc);
            NSLog(@"select query : %@",[NSThread currentThread]);
        }
        sqlite3_close(db);
    }
    
    return resultArray;
}

-(NSArray*)selectWithColumns:(NSArray*)selectColumns WithTableName:(NSString *)name where:(NSString*)whereStr distinct:(BOOL)bDistinct
{
    if(selectColumns.count == 0)    return nil;
    
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    sqlite3* db = NULL;
    sqlite3_stmt* stmt = NULL;
    int rc = 0;
    rc = sqlite3_open_v2([[self dbPath] UTF8String], &db, SQLITE_OPEN_READONLY , NULL);
    if(SQLITE_OK != rc)
    {
        sqlite3_close(db);
        NSLog(@"Failed to open db connection");
    }
    else
    {
        NSMutableString* query = [[NSMutableString alloc] init];
        
        if(bDistinct)
            [query appendString:@"SELECT DISTINCT "];
        else
            [query appendString:@"SELECT "];
        
        for(int i = 0; i < selectColumns.count; i ++)
        {
            NSString *columnStr = [selectColumns objectAtIndex:i];
            [query appendString:columnStr];
            
            if(i != selectColumns.count - 1)
            {
                [query appendString:@","];
            }
        }
        
        [query appendFormat:@" from %@",name];
        
        if(whereStr)
            [query appendFormat:@" %@",whereStr];
        
//        NSLog(@"select 쿼리 : %@",query);
        
        rc = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL);
        if(rc == SQLITE_OK)
        {
            while(sqlite3_step(stmt) == SQLITE_ROW) //get each row in loop
            {
                NSMutableDictionary *pDict = [[NSMutableDictionary alloc] init];
                int index = 0;
                
                while(YES)
                {
                    const char *columnNameChar = sqlite3_column_name(stmt, index);
                    const unsigned char *valueChar = sqlite3_column_text(stmt, index);
                    
                    if(valueChar == nil)
                        break;
                    
                    NSString *value = [NSString stringWithUTF8String:(const char *)valueChar];
                    NSString *columnName = [NSString stringWithUTF8String:(const char *)columnNameChar];
                    
                    [pDict setObject:value forKey:columnName];
                    index ++;
                }
                
                [resultArray addObject:pDict];
            }
            
            sqlite3_finalize(stmt);
        }
        else
        {
            NSLog(@"select Failed to prepare statement, rc : %d",rc);
            NSLog(@"select query : %@",[NSThread currentThread]);
        }
        sqlite3_close(db);
    }
    
    return resultArray;
}

-(BOOL)updateWithTableName:(NSString *)name values:(NSDictionary*)valueDict where:(NSString*)where
{
    NSMutableString *queryStr = [[NSMutableString alloc] init];
    [queryStr setString:[NSString stringWithFormat:@"UPDATE %@ SET ",name]];
    
    NSArray *keyArray = [valueDict allKeys];
    
    for(int i = 0; i < [keyArray count]; i++)
    {
        if(i != 0)
            [queryStr appendString:@", "];
        
        NSString *key = [keyArray objectAtIndex:i];
        NSString *value = [valueDict objectForKey:key];
        [queryStr appendString:[NSString stringWithFormat:@"%@='%@'",key, value]];
    }
    
    if([where length] > 0)
        [queryStr appendString:where];
    
    sqlite3* db = NULL;
    sqlite3_stmt* stmt =NULL;
    int rc=0;
    BOOL bSuccess = NO;
    rc = sqlite3_open_v2([[self dbPath] UTF8String], &db, SQLITE_OPEN_READWRITE , NULL);
    if (SQLITE_OK != rc)
    {
        sqlite3_close(db);
        NSLog(@"Failed to open db connection");
    }
    else
    {
        rc = sqlite3_prepare_v2(db, [queryStr UTF8String], -1, &stmt, NULL);
        
        if(rc == SQLITE_OK)
        {
            bSuccess = YES;
            
            while(sqlite3_step(stmt) == SQLITE_ROW)
            {
                for(int i = 0; i < [keyArray count]; i ++)
                {
                    NSString *value = [valueDict objectForKey:[keyArray objectAtIndex:i]];
                    sqlite3_bind_text(stmt, i, [value UTF8String], -1, NULL);
                }
            }
            
            sqlite3_finalize(stmt);
        }
        else
        {
            NSLog(@"update Failed to prepare statement, rc : %d",rc);
        }
        
        sqlite3_close(db);
    }
    
    return bSuccess;
}

-(void)deleteRowWithTableName:(NSString *)tblName where:(NSString*)where
{
    NSString *queryStr = [NSString stringWithFormat:@"DELETE FROM %@ %@",tblName, where];
    
    const char *sql = [queryStr UTF8String];
    
    sqlite3 *database;
    
    if(sqlite3_open([[self dbPath] UTF8String], &database) == SQLITE_OK)
    {
        sqlite3_stmt *deleteStmt;
        if(sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL) == SQLITE_OK)
        {
            
            if(sqlite3_step(deleteStmt) != SQLITE_DONE )
            {
                NSLog(@"delete Query Error!!");
            }
            else
            {
                //  NSLog( @"row id = %d", (sqlite3_last_insert_rowid(database)+1));
                NSLog(@"delete Query \"success\"");
            }
        }
        sqlite3_finalize(deleteStmt);
    }
    sqlite3_close(database);
}

#pragma mark - private

- (void)openDB
{
    if (sqlite3_open([[self dbPath] UTF8String], &db) != SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"Database failed to open.");
    }
}

-(NSString *)dbPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sql",_dbFileName]];
}

@end
