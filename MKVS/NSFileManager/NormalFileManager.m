//
//  NormalFileManager.m
//  MKVS
//
//  Created by 王嘉宁 on 2019/7/2.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import "NormalFileManager.h"

@interface NormalFileManager()

@property (nonatomic, strong, readwrite) NSMutableDictionary *cacheDict;

@end

@implementation NormalFileManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createDirectoryAndFile];
    }
    return self;
}

- (BOOL)setStringValue:(NSString *)string forKey:(NSString *)key
{
    [self.cacheDict setObject:string forKey:key];
    
    return [self writeToFile];
}

- (NSString *)fileFullPath
{
    return [NFMDefaultFilePath stringByAppendingFormat:@"/%@", NFMDefaultFileName];
}

- (BOOL)writeToFile
{
    return [self.cacheDict writeToFile:[NFMDefaultFilePath stringByAppendingFormat:@"/%@", NFMDefaultFileName] atomically:YES];
}

- (BOOL)createDirectoryAndFile
{
    NSString *fileFullPath = [NFMDefaultFilePath stringByAppendingFormat:@"/%@", NFMDefaultFileName];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    BOOL isDir = NO;
    BOOL isDirectoryExist = NO;
    BOOL isFileExist = NO;
    isDirectoryExist = [fileManager fileExistsAtPath:NFMDefaultFilePath isDirectory:&isDir];
    isFileExist = [fileManager fileExistsAtPath:fileFullPath];
    if (!isDirectoryExist) {
        if (![fileManager createDirectoryAtPath:NFMDefaultFilePath withIntermediateDirectories:YES attributes:nil error:nil]) {
            return NO;
        }
    }
    //要保证文件不能是空的，如果是不存在的文件就新建并且存入空字典
    //如果文件存在但是是空的也要存入一个空字典
    if (!isFileExist) {
        if (self.cacheDict == nil) {
            self.cacheDict = [[NSMutableDictionary alloc] init];
        } else {
            [self.cacheDict removeAllObjects];
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.cacheDict options:NSJSONWritingSortedKeys error:nil];
        if (![fileManager createFileAtPath:fileFullPath contents:data attributes:nil]) {
            return NO;
        }
    }
    return YES;
}

- (NSMutableDictionary *)cacheDict
{
    if (_cacheDict == nil) {
        _cacheDict = [[NSMutableDictionary alloc] init];
    }
    return _cacheDict;
}

@end
