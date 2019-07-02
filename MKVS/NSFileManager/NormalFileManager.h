//
//  NormalFileManager.h
//  MKVS
//
//  Created by 王嘉宁 on 2019/7/2.
//  Copyright © 2019 Johnny. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#define NFMDefaultFilePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"DaDa/NoramlFileManager"]
#define NFMDocumentFilePath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define NFMDefaultFileName @"defaultStorage"

@interface NormalFileManager : NSObject

- (BOOL)setStringValue:(NSString *)string forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
