//
//  WKDecodeContext.h
//  KTVMediaKitDemo
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDecoderOptions.h"
#import "WKCapacity.h"
#import "WKPacket.h"
#import "WKFrame.h"

@interface WKDecodeContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecoderClass:(Class)decoderClass;

/**
 *
 */
@property (nonatomic, copy) WKDecoderOptions *options;

/**
 *
 */
@property (nonatomic, readonly) CMTime decodeTimeStamp;

/**
 *
 */
- (WKCapacity)capacity;

/**
 *
 */
- (void)putPacket:(WKPacket *)packet;

/**
 *
 */
- (BOOL)needsPredecode;

/**
 *
 */
- (void)predecode:(WKBlock)lock unlock:(WKBlock)unlock;

/**
 *
 */
- (NSArray<__kindof WKFrame *> *)decode:(WKBlock)lock unlock:(WKBlock)unlock;

/**
 *
 */
- (void)setNeedsFlush;

/**
 *
 */
- (void)markAsFinished;

/**
 *
 */
- (void)destory;

@end

