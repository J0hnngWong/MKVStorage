//
//  MRWStorageManager.m
//  MRWS
//
//  Created by 王嘉宁 on 2019/7/4.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import "MRWStorageManager.h"
#import <sys/mman.h>
#import <sys/stat.h>

#define MAX_PAGE_SIZE 4096

@interface MRWStorageManager()

@property (strong, nonatomic, readwrite) dispatch_semaphore_t file_operation_lock;
@property (strong, nonatomic, readwrite) NSString *filePath;
@property (strong, nonatomic, readwrite) NSString *fileName;

//错误类型
@property (strong, nonatomic, readwrite) NSError *error;
//c文件操作需要的变量
@property (assign, nonatomic, readwrite) int32_t file_descriptor;
@property (assign, nonatomic, readwrite) int32_t file_off_set;
@property (assign, nonatomic, readwrite) size_t file_size;
@property (assign, nonatomic, readwrite) int32_t page_number;
@property (assign, nonatomic, readwrite) void * file_ptr;
//c error code
@property (assign, nonatomic, readwrite) int error_number;

@end

@implementation MRWStorageManager

#pragma mark - init

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.file_operation_lock = dispatch_semaphore_create(1);
        [self setWorkPath:MRWSDefaultFilePath fileName:MRWSDefaultFileName];
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
    [self setWorkPath:MRWSDefaultFilePath fileName:fileName];
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
    temp_file_ptr = [self _mapFile];
    if (temp_file_ptr == nil || temp_file_ptr == ((void *)-1)) {
        printf("fail to load from file\n");
        return;
    }
    self.file_ptr = temp_file_ptr;
}

- (BOOL)removeDefaultFile
{
    return [self removeFileInPath:MRWSDefaultFilePath fileName:MRWSDefaultFileName];
}

- (BOOL)removeFileInDefaultPathWithFileName:(NSString *)fileName
{
    return [self removeFileInPath:MRWSDefaultFilePath fileName:fileName];
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

- (BOOL)_createDirectoryAndFile
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if (is_empty_string(self.filePath)) {
        self.filePath = MRWSDefaultFilePath;
    }
    if (is_empty_string(self.fileName)) {
        self.fileName = MRWSDefaultFileName;
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
        if (![fileManager createFileAtPath:fileFullPath contents:nil attributes:nil]) {
            dispatch_semaphore_signal(self.file_operation_lock);
            return NO;
        }
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return YES;
}


- (NSString *)_getFullFilePathWithFilePath:(NSString *)path fileName:(NSString *)fileName
{
    //如果名字中含有路径内容，就返回nil
    if ([self.fileName containsString:@"/"]) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@/%@", path, fileName];
}

#pragma mark - write log
- (void)setLogContent:(NSString *)log
{
    if (![self _preWriteToMemory:log.UTF8String size:log.length]) {
        printf("fail to pre write to memory");
        return;
    }
    if (![self _writeToMemory:log.UTF8String size:log.length]) {
        printf("failt to write to memory");
        return;
    }
}

#pragma mark - mmap map file

//映射之后，我们主要应该拿到映射到内存这部分的开头的指针，以及文件的大小，即映射大小
- (void *)_mapFile
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    //这个过程就是建立映射的过程
    //设定需要暂时储存文件信息使用的变量
    int32_t file_descriptor;//用来描述文件描述信息
    struct stat file_stat;//用来描述文件状态的结构体
    void *memory_ptr;//映射之后的指针
    
    file_descriptor = open([self _getFullFilePathWithFilePath:self.filePath fileName:self.fileName].UTF8String, O_RDWR, 0);
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
    //如果是空文件不能让file_stat.st_size为<nil>
    self.file_off_set = (int32_t)self.file_size;
    if (!file_stat.st_size) {
        self.file_size = 1;
        self.file_off_set = 0;
    }
    self.page_number = 0;
    memory_ptr = mmap(NULL, self.file_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FILE, file_descriptor, MAX_PAGE_SIZE * self.page_number);
    if (memory_ptr == ((void *)-1)) {
        printf("map failed\n");
        self.error_number = errno;
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return memory_ptr;
}

- (void *)remap
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    if (munmap(self.file_ptr, self.file_size) != 0) {
        printf("fail to munmap file\n");
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    size_t oldSize = self.file_size;
    self.file_size = 1;
    self.file_off_set = 0;
    self.page_number++;
    self.file_ptr = mmap(self.file_ptr, self.file_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FILE, self.file_descriptor, MAX_PAGE_SIZE * self.page_number);
    if (self.file_ptr == ((void *)-1)) {
        printf("map failed\n");
        self.error_number = errno;
        dispatch_semaphore_signal(self.file_operation_lock);
        return nil;
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return self.file_ptr;
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

#pragma mark - write to memory

- (BOOL)_preWriteToMemory:(const char *)log size:(size_t)size
{
    if (self.file_size + size > MAX_PAGE_SIZE) {
        printf("reach max page size, will automaticlly move to next page\n");
        if ([self remap] == nil) {
            printf("remap fail\n");
            return NO;
        }
        return YES;
    }
    return YES;
}

- (BOOL)_writeToMemory:(const char *)log size:(size_t)size
{
    dispatch_semaphore_wait(self.file_operation_lock, DISPATCH_TIME_FOREVER);
    //修改文件大小
    ftruncate(self.file_descriptor, self.file_size + size);
    //将要写入的内容拷贝到内存的file_ptr所指向的内存当中
    if (self.file_ptr && size > 0 && self.file_ptr != ((void *)-1)) {
        memcpy(self.file_ptr + self.file_off_set, log, size);
        //拷贝完成后off_set向后移动
        self.file_off_set += (int32_t)size;
        //拷贝完成后也要改变文件整体大小
        self.file_size += size;
        dispatch_semaphore_signal(self.file_operation_lock);
        return YES;
    } else {
        printf("write to memory fail\n");
    }
    dispatch_semaphore_signal(self.file_operation_lock);
    return NO;
}

#pragma mark - tools
BOOL is_empty_string(NSString *string)
{
    NSCharacterSet *aCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    BOOL isEmpty = ([string isKindOfClass:[NSString class]] && [@"" isEqualToString:[string stringByTrimmingCharactersInSet:aCharacterSet]]);
    return !string || [string isEqual:[NSNull null]] || isEmpty;
}

#pragma mark - debug

- (void)printFilePath
{
    NSLog(@"file path : %@", [self _getFullFilePathWithFilePath:self.filePath fileName:self.fileName]);
}

@end