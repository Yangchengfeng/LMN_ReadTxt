//
//  ViewController.m
//  LMN_ReadTxt
//
//  Created by 阳丞枫 on 16/12/12.
//  Copyright © 2016年 chengfengYang. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>

@interface ViewController ()

@property (nonatomic, assign) sqlite3 *db; // db只是一个指针

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self openDatabase];
}

/**
 *  打开数据库并创建一个表
 */
- (void)openDatabase {
    
    sqlite3 *database = nil;
    _db = database;
    
    NSLog(@"%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject); // 获取article.sqlite将要存储的位置
    //1.设置文件名
    NSString *filename = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"article.sqlite"];
    const char *cfileName = filename.UTF8String;
    
    //2.打开数据库文件，如果没有会自动创建一个文件
    NSInteger openResult = sqlite3_open(cfileName, &database);
    if (openResult == SQLITE_OK) {
        NSLog(@"打开数据库成功！");
        
        //3.创建表
        char *errmsg;
        NSString *sql = @"CREATE TABLE IF NOT EXISTS t_articles (id integer primary key autoincrement,article text);";
        sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &errmsg); // 设置主键id:自动增长
        if (errmsg) {
            NSLog(@"错误：%s", errmsg);
        } else {
            NSLog(@"创表成功！");
            [self insertData];
            [self selectArticleWithID:47];
        }
        
    } else {
        NSLog(@"打开数据库失败！");
    }
}

/**
 *  插入数据
 */
- (void)insertData {
    
    __block int j = 1;
    __block NSMutableArray *text = [NSMutableArray array];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filePath=[[NSBundle mainBundle] pathForResource:@"新概念英语第4册" ofType:@"txt"];
        NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *arr = [str componentsSeparatedByString:@"\n"];
        NSUInteger lineCount = arr.count;
        for(int i = 0; i<lineCount; i++) {
            NSString *lineContent = arr[i];
            if([lineContent rangeOfString:@"Unit"].location == NSNotFound) {
                if([lineContent rangeOfString:@"Lesson"].location == NSNotFound) {
                    
                    if([lineContent rangeOfString:@"'"].location != NSNotFound) { // '在数据库中有特殊含义
                        lineContent = [lineContent stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
                    }
                    [text addObject:lineContent];
                    
                    if(i == lineCount-1) { // 文件结束
                        //1.拼接SQL语句
                        NSString *article = [NSString stringWithFormat:@"%@", text];
                        NSString *sql=[NSString stringWithFormat:@"INSERT INTO t_articles (article) VALUES ('%@');", article];
                        
                        //2.执行SQL语句
                        char *errmsg=NULL;
                        sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &errmsg);
                        if (errmsg) {//如果有错误信息
                            NSLog(@"插入数据失败--%s",errmsg);
                        }else
                        {
                            NSLog(@"插入数据成功 - 第%d篇", j++);
                            
                        }
                    }
                    
                    
                } else {
                    if(text.count != 0) {
                        //1.拼接SQL语句
                        NSString *article = [NSString stringWithFormat:@"%@", text];
                        NSString *sql=[NSString stringWithFormat:@"INSERT INTO t_articles (article) VALUES ('%@');", article];
                        
                        //2.执行SQL语句
                        char *errmsg=NULL;
                        sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &errmsg);
                        if (errmsg) {//如果有错误信息
                            NSLog(@"插入数据失败--%s",errmsg);
                        }else
                        {
                            NSLog(@"插入数据成功 - 第%d篇", j++);
                            
                        }
                        
                        // 清空
                        [text removeAllObjects];
                    }
                }
            }
        }
    });
}

/**
 *  查找数据的接口
 */
- (void)selectArticleWithID:(int)articleID {
    NSString *sql = @"SELECT * FROM t_articles where id = 4;";
    const unsigned char *cArticle;
    sqlite3_stmt *stmt = NULL;
    
    if (sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL)==SQLITE_OK) { //SQL语句没有问题
        NSLog(@"查询语句没有问题");
        
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            cArticle = sqlite3_column_text(stmt, 0);
            NSString *article = [NSString stringWithCString:(const char *)cArticle encoding:NSNonLossyASCIIStringEncoding];
            NSLog(@"%@", article);
        }
    } else {
        NSLog(@"查询语句有问题");
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
