//
//  WKURLSource.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDemuxerOptions.h"
#import "WKPacket.h"
#import "WKAsset.h"

@protocol WKPacketOutputDelegate;

/**
 *
 */
typedef NS_ENUM(NSUInteger, WKPacketOutputState) {
    WKPacketOutputStateNone     = 0,
    WKPacketOutputStateOpening  = 1,
    WKPacketOutputStateOpened   = 2,
    WKPacketOutputStateReading  = 3,
    WKPacketOutputStatePaused   = 4,
    WKPacketOutputStateSeeking  = 5,
    WKPacketOutputStateFinished = 6,
    WKPacketOutputStateClosed   = 7,
    WKPacketOutputStateFailed   = 8,
};

@interface WKPacketOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(WKAsset *)asset;

/**
 *
 */
@property (nonatomic, copy) WKDemuxerOptions *options;

/**
 *
 */
@property (nonatomic, weak) id<WKPacketOutputDelegate> delegate;

/**
 *
 */
@property (nonatomic, readonly) WKPacketOutputState state;

/**
 *
 */
@property (nonatomic, copy, readonly) NSError *error;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<WKTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<WKTrack *> *finishedTracks;

/**
 *
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

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
- (BOOL)seekable;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(WKSeekResult)result;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(WKSeekResult)result;

@end

@protocol WKPacketOutputDelegate <NSObject>

/**
 *
 */
- (void)packetOutput:(WKPacketOutput *)packetOutput didChangeState:(WKPacketOutputState)state;

/**
 *
 */
- (void)packetOutput:(WKPacketOutput *)packetOutput didOutputPacket:(WKPacket *)packet;

@end
