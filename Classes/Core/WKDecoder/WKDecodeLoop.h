//
//  WKDecodeLoop.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDecodable.h"
#import "WKCapacity.h"

@protocol WKDecodeLoopDelegate;

/**
 *
 */
typedef NS_ENUM(NSUInteger, WKDecodeLoopState) {
    WKDecodeLoopStateNone     = 0,
    WKDecodeLoopStateDecoding = 1,
    WKDecodeLoopStateStalled  = 2,
    WKDecodeLoopStatePaused   = 3,
    WKDecodeLoopStateClosed   = 4,
};

@interface WKDecodeLoop : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecoderClass:(Class)decoderClass;

/**
 *
 */
@property (nonatomic, weak) id<WKDecodeLoopDelegate> delegate;

/**
 *
 */
@property (nonatomic, copy) WKDecoderOptions *options;

/**
 *
 */
- (WKDecodeLoopState)state;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)finish:(NSArray<WKTrack *> *)tracks;

/**
 *
 */
- (BOOL)putPacket:(WKPacket *)packet;

@end

@protocol WKDecodeLoopDelegate <NSObject>

/**
 *
 */
- (void)decodeLoop:(WKDecodeLoop *)decodeLoop didChangeState:(WKDecodeLoopState)state;

/**
 *
 */
- (void)decodeLoop:(WKDecodeLoop *)decodeLoop didChangeCapacity:(WKCapacity)capacity;

/**
 *
 */
- (void)decodeLoop:(WKDecodeLoop *)decodeLoop didOutputFrames:(NSArray<__kindof WKFrame *> *)frames needsDrop:(BOOL(^)(void))needsDrop;

@end
