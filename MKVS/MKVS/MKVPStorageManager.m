//
//  MKVPStorageManager.m
//  MKVPS
//
//  Created by 王嘉宁 on 2019/6/20.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import "MKVPStorageManager.h"
#import <UIKit/UIKit.h>
#import <sys/mman.h>
#import <sys/stat.h>

//the best size of each file is a few virtual memory pages in size
#define MAX_FILE_SIZE 4096

#define CURRENT_PAGE_NAME [NSString stringWithFormat:@"dict%ld", (long)self.currentPageNumber]

@interface MKVPStorageManager ()

//@property (strong, nonatomic, readwrite) MKVPStorageManager *defaultManager;

@property (strong, nonatomic, readwrite) dispatch_semaphore_t file_operation_lock;
@property (strong, nonatomic, readwrite) NSString *filePath;
@property (strong, nonatomic, readwrite) NSString *fileName;
@property (strong, nonatomic, readwrite) NSMutableDictionary *cacheDictionary;

@property (assign, nonatomic, readwrite) NSInteger currentPageNumber;
@property (assign, nonatomic, readwrite) NSInteger totalPageNumber;
@property (strong, nonatomic, readwrite) NSMutableSet *currentKeySet;
@property (strong, nonatomic, readwrite) NSMutableDictionary<NSString *, NSMutableSet *> *pageIndexDictionary;

//错误类型
@property (strong, nonatomic, readwrite) NSError *error;
//c文件操作需要的变量
@property (assign, nonatomic, readwrite) int32_t file_descriptor;
@property (assign, nonatomic, readwrite) size_t file_size;
@property (assign, nonatomic, readwrite) void * file_ptr;
//c error code
@property (assign, nonatomic, readwrite) int error_number;

@end

@implementation MKVPStorageManager

//+ (instancetype)defaultManager
//{
//    static id manager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        manager = [[MKVPStorageManager alloc] init];
//    });
//    return manager;
//}

#pragma mark - init

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.file_operation_lock = dispatch_semaphore_create(1);
        [self setWorkPath:MKVPSDefaultFilePath fileName:MKVPSDefaultFileName];
    }
    return self;
}

- (instancetype)initWithFilePath:(NSString *)path fileName:(NSString *)fileName
{
    self = [super init];
    if (self) {
        self.file_operation_lock = dispatch_semaphore_create(1);
        [self setWorkPath:path fileName:fileName];
    }
    return self;
}

#pragma mark - file operation

- (void)setWorkFileName:(NSString *)fileName
{
    [self setWorkPath:MKVPSDefaultFilePath fileName:fileName];
}

- (void)setWorkPath:(NSString *)path fileName:(NSString *)fileName
{
    self.filePath = path;
    self.fileName = fileName;
    __block void *temp_file_ptr = nil;
    if (self.file_ptr != nil && self.file_ptr != ((void *)-1)) {
        [self unmapAndCloseFile];
    }
    if (![self _createDirectoryAndFile]) {
        printf("fail to create file\n");
        return;
    }
    temp_file_ptr = [self _loadFromFile];
    if (temp_file_ptr == nil || temp_file_ptr == ((void *)-1)) {
        printf("fail to load from file\n");
        return;
    }
}

- (BOOL)removeDefaultFile
{
    return [self removeFileInPath:MKVPSDefaultFilePath fileName:MKVPSDefaultFileName];
}

- (BOOL)removeFileInDefaultPathWithFileName:(NSString *)fileName
{
    return [self removeFileInPath:MKVPSDefaultFilePath fileName:fileName];
}

- (BOOL)removeFileInPath:(NSString *)path fileName:(NSString *)fileName
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if ([path isEqualToString:self.filePath] && [fileName isEqualToString:self.fileName]) {
        printf("delete the file which are mapped on\n");
        dispatch_semaphore_signal(self.file_operation_lock);
        return NO;
    }
    NSString *fileFullPath = [self _getFullFilePathWithFilePath:path fileName:fileName];
    if (fileFullPath == nil) {
        printf("the file name have \\ \n");
        dispatch_semaphore_signal(self.file_operation_lock);
        return NO;
    }
    if (![NSFileManager.defaultManager fileExistsAtPath:fileFullPath]) {
        printf("file not exist\n");
        dispatch_semaphore_signal(self.file_operation_lock);
        return YES;
    }
    BOOL result = [NSFileManager.defaultManager removeItemAtPath:fileFullPath error:nil];
    dispatch_semaphore_signal(self.file_operation_lock);
    return result;
}

#pragma mark - write back observer

- (void)setFileWriteBackWhileAppTerminate
{
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillTerminateNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self removeObserverForAppTerminate];
    }];
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self removeObserverForAppTerminate];
    }];
}

#pragma mark - close
- (void)removeObserverForAppTerminate
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [self unmapAndCloseFile];
}

#pragma mark - unmap and close file
- (void)unmapAndCloseFile
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if (self.file_ptr == nil || self.file_descriptor < 0) {
        printf("file unmap fail\n");
        self.error_number = errno;
        return;
    }
    if (munmap(self.file_ptr, self.file_size) != 0) {
        printf("fail to unmap the file\n");
        return;
    }
    if (close(self.file_descriptor) != 0) {
        printf("fail to close the file\n");
        return;
    }
    dispatch_semaphore_signal(self.file_operation_lock);
}

#pragma mark - public function

#pragma mark - setter
- (BOOL)setBoolValue:(BOOL)value forKey:(NSString *)key
{
    NSNumber *boolValue = [NSNumber numberWithBool:value];
    if (![self preWriteDictToFileWith:boolValue key:key]) {
        return NO;
    }
    [self.currentKeySet addObject:key];
    return [self _writeToMemoryWithPageNumber:self.currentPageNumber];
}

- (BOOL)setIntValue:(NSInteger)value forKey:(NSString *)key
{
    NSNumber *intValue = [NSNumber numberWithInteger:value];
    if (![self preWriteDictToFileWith:intValue key:key]) {
        return NO;
    }
    [self.currentKeySet addObject:key];
    return [self _writeToMemoryWithPageNumber:self.currentPageNumber];
}

- (BOOL)setStringValue:(NSString *)value forKey:(NSString *)key
{
    if (![self preWriteDictToFileWith:value key:key]) {
        return NO;
    }
    [self.currentKeySet addObject:key];
    return [self _writeToMemoryWithPageNumber:self.currentPageNumber];
}

- (BOOL)setFloatValue:(float)value forKey:(NSString *)key
{
    NSNumber *floatValue = [NSNumber numberWithFloat:value];
    if (![self preWriteDictToFileWith:floatValue key:key]) {
        return NO;
    }
    [self.currentKeySet addObject:key];
    return [self _writeToMemoryWithPageNumber:self.currentPageNumber];
}

- (BOOL)setDateValue:(NSDate *)value forKey:(NSString *)key
{
    if ([value timeIntervalSince1970] < 0) {
        printf("try to store a date before 1970/1/1\n");
        return NO;
    }
    [self.currentKeySet addObject:key];
    NSUInteger timestamp = [value timeIntervalSince1970];
    return [self setIntValue:timestamp forKey:key];
}

- (BOOL)setDataValue:(NSData *)value forKey:(NSString *)key
{
    return YES;
}


- (BOOL)setObject:(id)object forKey:(NSString *)key
{
    return YES;
}

#pragma mark - getter
- (BOOL)getBoolValueForKey:(NSString *)key
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    
    NSNumber *number = [[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] objectForKey:key];
    dispatch_semaphore_signal(self.file_operation_lock);
    if (!number) {
        return NO;
    }
    return number.boolValue;
}

- (long)getIntValueForKey:(NSString *)key
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    NSNumber *number = [[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] objectForKey:key];
    dispatch_semaphore_signal(self.file_operation_lock);
    if (!number) {
        return 0;
    }
    return number.longValue;
}

- (NSString *)getStringValueForKey:(NSString *)key
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    id result = [[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] objectForKey:key];
    dispatch_semaphore_signal(self.file_operation_lock);
    if (result == nil || ![result isKindOfClass:NSString.class]) {
        return nil;
    }
    return result;
}

- (float)getFloatValueForKey:(NSString *)key
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    NSNumber *number = [[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] objectForKey:key];
    dispatch_semaphore_signal(self.file_operation_lock);
    if (!number) {
        return 0;
    }
    return number.floatValue;
}

- (nullable NSDate *)getDateValueForKey:(NSString *)key
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    NSNumber *number = [[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] objectForKey:key];
    dispatch_semaphore_signal(self.file_operation_lock);
    if (!number) {
        return nil;
    }
    NSUInteger timestamp = number.unsignedIntegerValue;
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
    return date;
}


- (NSData *)getDataValueForKey:(NSString *)key
{
    return nil;
}

- (id)getObjectValueForKey:(NSString *)key
{
    return nil;
}

#pragma mark - delete
- (BOOL)removeObjectForKey:(NSString *)key
{
    if (![self.cacheDictionary objectForKey:key]) {
        printf("object does not exist\n");
        return NO;
    } else {
        [self.pageIndexDictionary enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString * _Nonnull pageKey, NSMutableSet * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj containsObject:key]) {
                NSString *pageNumber = [pageKey substringFromIndex:4];
                NSMutableDictionary *tempDict = [self.cacheDictionary objectForKey:pageKey];
                dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
                [tempDict removeObjectForKey:key];
                dispatch_semaphore_signal(self.file_operation_lock);
                [self _writeToMemoryWithPageNumber:pageNumber.integerValue];
                *stop = YES;
            }
        }];
        return YES;
    }
}

#pragma mark - file size pre check

- (BOOL)preWriteDictToFileWith:(id)object key:(NSString *)key
{
    if ([self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] == nil) {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        [self.cacheDictionary setObject:newDict forKey:CURRENT_PAGE_NAME];
    }
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if ([[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] objectForKey:key] != nil) {
        printf("object already exist\n");
        dispatch_semaphore_signal(self.file_operation_lock);
        return NO;
    }
    NSMutableDictionary *tempDict = [self.cacheDictionary objectForKey:CURRENT_PAGE_NAME];
    [tempDict setObject:object forKey:key];
    if ([self _isWriteDataReachFileSizeLimit]) {
        //文件到达最大大小需要写入下一页
        printf("change page\n");
        [tempDict removeObjectForKey:key];
        [self appendPage];
        NSMutableDictionary *tempDict = [self.cacheDictionary objectForKey:CURRENT_PAGE_NAME];
        [tempDict setObject:object forKey:key];
        dispatch_semaphore_signal(self.file_operation_lock);
        return YES;
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return YES;
}

#pragma mark - private function

#pragma mark - file operation

- (NSString *)_getFullFilePathForMappingFile
{
    //如果名字中含有路径内容，就返回nil
    if ([self.fileName containsString:@"/"]) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@/%@", self.filePath, self.fileName];
}

- (NSString *)_getFullFilePathWithFilePath:(NSString *)path fileName:(NSString *)fileName
{
    //如果名字中含有路径内容，就返回nil
    if ([self.fileName containsString:@"/"]) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@/%@", path, fileName];
}

- (BOOL)_createDirectoryAndFile
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if (is_empty_string(self.filePath)) {
        self.filePath = MKVPSDefaultFilePath;
    }
    if (is_empty_string(self.fileName)) {
        self.fileName = MKVPSDefaultFileName;
    }
    //如果名字中含有路径内容，就返回NO
    if ([self.fileName containsString:@"/"]) {
        dispatch_semaphore_signal(self.file_operation_lock);
        return NO;
    }
    NSString *fileFullPath = [self.filePath stringByAppendingFormat:@"/%@", self.fileName];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    BOOL isDir = NO;
    BOOL isDirectoryExist = NO;
    BOOL isFileExist = NO;
    isDirectoryExist = [fileManager fileExistsAtPath:self.filePath isDirectory:&isDir];
    isFileExist = [fileManager fileExistsAtPath:fileFullPath];
    if (!isDirectoryExist) {
        if (![fileManager createDirectoryAtPath:self.filePath withIntermediateDirectories:YES attributes:nil error:nil]) {
            dispatch_semaphore_signal(self.file_operation_lock);
            return NO;
        }
    }
    //要保证文件不能是空的，如果是不存在的文件就新建并且存入空字典
    //如果文件存在但是是空的也要存入一个空字典
    if (!isFileExist) {
        if (self.cacheDictionary == nil) {
            self.cacheDictionary = [[NSMutableDictionary alloc] init];
        } else {
            [self.cacheDictionary removeAllObjects];
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.cacheDictionary options:NSJSONWritingSortedKeys error:nil];
        if (![fileManager createFileAtPath:fileFullPath contents:data attributes:nil]) {
            dispatch_semaphore_signal(self.file_operation_lock);
            return NO;
        }
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return YES;
}

#pragma mark - mmap map file

//映射之后，我们主要应该拿到映射到内存这部分的开头的指针，以及文件的大小，即映射大小
- (void *)_loadFromFile
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    //这个过程就是建立映射的过程
    //设定需要暂时储存文件信息使用的变量
    int32_t file_descriptor;//用来描述文件描述信息
    struct stat file_stat;//用来描述文件状态的结构体
    void *memory_ptr;//映射之后的指针
    
    file_descriptor = open([self _getFullFilePathForMappingFile].UTF8String, O_RDWR, 0);
    self.file_descriptor = file_descriptor;
    if (file_descriptor < 0) {
        //权限出错
        printf("authenticate error\n");
        self.error_number = errno;
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    
    //由文件描述取得文件状态
    if (fstat(file_descriptor, &file_stat) != 0)
    {
        printf("fstat fail to get file descriptor\n");
        self.error_number = errno;
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    //同步文件读写操作
    if (fsync(file_descriptor) != 0) {
        printf("fail to synchronize the read write to file\n");
        self.error_number = errno;
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    //建立映射返回指针
    //如果是空文件不能让file_stat.st_size为<nil>，新建文件的时候一定会先写入一个空字典
    memory_ptr = mmap(NULL, file_stat.st_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FILE, file_descriptor, 0);
    if (memory_ptr == ((void *)-1)) {
        printf("map failed\n");
        self.error_number = errno;
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    self.file_size = file_stat.st_size;
    self.file_ptr = memory_ptr;
    //将读出的数据读入内存当中
    if (self.file_ptr) {
        NSInteger pageNumber = ((file_stat.st_size - 1) / MAX_FILE_SIZE) + 1;
        self.totalPageNumber = pageNumber;
        for (int i = 0; i < pageNumber; i++) {
            NSMutableData *data = [NSMutableData dataWithBytes:(self.file_ptr + (i * MAX_FILE_SIZE)) length:MAX_FILE_SIZE];
            NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (tempDict != nil) {
                [self.cacheDictionary setObject:tempDict forKey:[NSString stringWithFormat:@"dict%d", i]];
            }
        }
        self.currentPageNumber = 0;
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return memory_ptr;
}

#pragma mark - mmap write

- (BOOL)_writeToMemoryWithPageNumber:(NSInteger)pageNumber
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if (self.cacheDictionary == nil) {
        dispatch_semaphore_signal(self.file_operation_lock);
        printf("cache dictionary is nil");
        return NO;
    }
    //序列化
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self.cacheDictionary objectForKey:[NSString stringWithFormat:@"dict%ld", (long)pageNumber]] options:NSJSONWritingSortedKeys error:nil];
    NSMutableData *writeData = [NSMutableData dataWithData:data];
    if (writeData.length > MAX_FILE_SIZE) {
        printf("reach max file size");
        dispatch_semaphore_signal(self.file_operation_lock);
        return NO;
    }
    //将要写入的内容拷贝到内存的file_ptr所指向的内存当中
    if (self.file_ptr && writeData.mutableBytes && self.file_size > 0 && self.file_ptr != ((void *)-1)) {
        memcpy(self.file_ptr + (pageNumber * MAX_FILE_SIZE), writeData.mutableBytes, MAX_FILE_SIZE);
        dispatch_semaphore_signal(self.file_operation_lock);
        return YES;
    } else {
        printf("write to memory fail\n");
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return NO;
}

- (BOOL)_isWriteDataReachFileSizeLimit
{
    if ([self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] == nil) {
        return NO;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self.cacheDictionary objectForKey:CURRENT_PAGE_NAME] options:NSJSONWritingSortedKeys error:nil];
    if (data && data.length > MAX_FILE_SIZE) {
        [NSNotificationCenter.defaultCenter postNotificationName:kReadyToWriteDataIsReachMaxFileSizeNotification object:data userInfo:self.cacheDictionary];
        return YES;
    }
    return NO;
}

- (void)appendPage
{
    if (self.currentKeySet != nil) {
        [self.pageIndexDictionary setObject:self.currentKeySet forKey:CURRENT_PAGE_NAME];
        self.currentPageNumber++;
        self.currentKeySet = nil;
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        [self.cacheDictionary setObject:newDict forKey:CURRENT_PAGE_NAME];
        //修改文件大小
        ftruncate(self.file_descriptor, self.totalPageNumber * MAX_FILE_SIZE);
    }
}

#pragma mark - mmap read

#pragma mark - tools

BOOL is_empty_string(NSString *string)
{
    NSCharacterSet *aCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    BOOL isEmpty = ([string isKindOfClass:[NSString class]] && [@"" isEqualToString:[string stringByTrimmingCharactersInSet:aCharacterSet]]);
    return !string || [string isEqual:[NSNull null]] || isEmpty;
}

#pragma mark - getter

- (NSMutableDictionary *)cacheDictionary
{
    if (_cacheDictionary == nil) {
        _cacheDictionary = [[NSMutableDictionary alloc] init];
    }
    return _cacheDictionary;
}

- (NSMutableDictionary<NSString *,NSMutableSet *> *)pageIndexDictionary
{
    if (_pageIndexDictionary == nil) {
        _pageIndexDictionary = [[NSMutableDictionary alloc] init];
    }
    return _pageIndexDictionary;
}

- (NSMutableSet *)currentKeySet
{
    if (_currentKeySet == nil) {
        _currentKeySet = [[NSMutableSet alloc] init];
    }
    return _currentKeySet;
}

#pragma mark - debug

- (void)printFilePath
{
    NSLog(@"file path : %@", [self _getFullFilePathForMappingFile]);
}

@end
