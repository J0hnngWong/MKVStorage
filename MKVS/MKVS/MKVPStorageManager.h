//
//  MKVPStorageManager.h
//  MKVPS
//
//  Created by 王嘉宁 on 2019/6/20.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kReadyToWriteDataIsReachMaxFileSizeNotification @"readyToWriteDataIsReachMaxFileSizeNotification"

#define MKVPSDefaultFilePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"DaDa/MKVPS"]
#define MKVPSDocumentFilePath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define MKVPSDefaultFileName @"defaultStorage"

NS_ASSUME_NONNULL_BEGIN

@interface MKVPStorageManager : NSObject

//+ (instancetype)defaultManager;
/// initialize
- (instancetype)init;
- (instancetype)initWithFilePath:(nonnull NSString *)path fileName:(nonnull NSString *)fileName;

/// file operation
- (void)setWorkFileName:(nonnull NSString *)fileName;
- (void)setWorkPath:(nonnull NSString *)path fileName:(nonnull NSString *)fileName;
- (BOOL)removeFileInDefaultPathWithFileName:(nonnull NSString *)fileName;
- (BOOL)removeFileInPath:(nonnull NSString *)path fileName:(nonnull NSString *)fileName;

/// write value
- (BOOL)setBoolValue:(BOOL)value forKey:(nonnull NSString *)key;
- (BOOL)setIntValue:(NSInteger)value forKey:(nonnull NSString *)key;
- (BOOL)setStringValue:(nonnull NSString *)value forKey:(nonnull NSString *)key;
- (BOOL)setFloatValue:(float)value forKey:(nonnull NSString *)key;
- (BOOL)setDateValue:(nonnull NSDate *)value forKey:(nonnull NSString *)key;

- (BOOL)setDataValue:(nonnull NSData *)value forKey:(nonnull NSString *)key;
- (BOOL)setObject:(nonnull id)object forKey:(nonnull NSString *)key;

/// get value
- (BOOL)getBoolValueForKey:(nonnull NSString *)key;
- (long)getIntValueForKey:(nonnull NSString *)key;
- (nullable NSString *)getStringValueForKey:(nonnull NSString *)key;
- (float)getFloatValueForKey:(nonnull NSString *)key;
- (nullable NSDate *)getDateValueForKey:(nonnull NSString *)key;

- (nullable NSData *)getDataValueForKey:(nonnull NSString *)key;
- (id)getObjectValueForKey:(nonnull NSString *)key;

/// delete value
- (BOOL)removeObjectForKey:(nonnull NSString *)key;

/// app terminate observer
- (void)setFileWriteBackWhileAppTerminate;
- (void)removeObserverForAppTerminate;

/// unmap and close file
- (void)unmapAndCloseFile;

/// debug
- (void)printFilePath;

@end

NS_ASSUME_NONNULL_END
