//
//  WKSMB2AVIOContextCreator.h
//  WKPlayer
//
//  Created by wkun on 2025/8/18.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSMB2AVIOContextCreator : NSObject

/// 为 SMB URL 创建 AVIOContext
/// @param url SMB 协议的 URL
/// @param bufferSize 缓冲区大小
+ (AVIOContext *)createAVIOContextForSMBURL:(NSURL *)url bufferSize:(int)bufferSize;

/// 判断 URL 是否为 SMB 协议
+ (BOOL)isSMBURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
