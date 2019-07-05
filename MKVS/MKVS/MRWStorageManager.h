//
//  MRWStorageManager.h
//  MRWS
//
//  Created by 王嘉宁 on 2019/7/4.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMRWSReadyToWriteDataIsReachMaxFileSizeNotification @"MRWSReadyToWriteDataIsReachMaxFileSizeNotification"

#define MRWSDefaultFilePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"DaDa/MRWS"]
#define MRWSDocumentFilePath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

//最好可以用设备号做记录
#define MRWSDefaultFileName @"defaultStorage"

NS_ASSUME_NONNULL_BEGIN

@interface MRWStorageManager : NSObject

/// init
- (instancetype)init;
- (instancetype)initWithFilePath:(nonnull NSString *)path fileName:(nonnull NSString *)fileName;

/// file operation
- (void)setWorkFileName:(nonnull NSString *)fileName;
- (void)setWorkPath:(nonnull NSString *)path fileName:(nonnull NSString *)fileName;
- (BOOL)removeFileInDefaultPathWithFileName:(nonnull NSString *)fileName;
- (BOOL)removeFileInPath:(nonnull NSString *)path fileName:(nonnull NSString *)fileName;

- (void)setMaxFileSize:(size_t)fileSize blockWriteOperation:(BOOL)block;

/// write log
- (void)setLogContent:(NSString *)log;

/// map
- (void)unmapAndCloseFile;

/// debug
- (void)printFilePath;

@end

NS_ASSUME_NONNULL_END
