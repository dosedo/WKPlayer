//
//  WKPlayerItem+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPlayerItem.h"
#import "WKProcessorOptions.h"
#import "WKAudioDescriptor.h"
#import "WKDemuxerOptions.h"
#import "WKDecoderOptions.h"
#import "WKCapacity.h"
#import "WKFrame.h"

@protocol WKPlayerItemDelegate;

/**
 *
 */
typedef NS_ENUM(NSUInteger, WKPlayerItemState) {
    WKPlayerItemStateNone     = 0,
    WKPlayerItemStateOpening  = 1,
    WKPlayerItemStateOpened   = 2,
    WKPlayerItemStateReading  = 3,
    WKPlayerItemStateSeeking  = 4,
    WKPlayerItemStateFinished = 5,
    WKPlayerItemStateClosed   = 6,
    WKPlayerItemStateFailed   = 7,
};

@interface WKPlayerItem ()

/**
 *
 */
@property (nonatomic, copy) WKDemuxerOptions *demuxerOptions;

/**
 *
 */
@property (nonatomic, copy) WKDecoderOptions *decoderOptions;

/**
 *
 */
@property (nonatomic, copy) WKProcessorOptions *processorOptions;

/**
 *
 */
@property (nonatomic, weak) id<WKPlayerItemDelegate> delegate;

/**
 *
 */
@property (nonatomic, readonly) WKPlayerItemState state;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)start;

/**
 *
 */
- (BOOL)close;

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

/**
 *
 */
- (WKCapacity)capacityWithType:(WKMediaType)type;

/**
 *
 */
- (BOOL)isAvailable:(WKMediaType)type;

/**
 *
 */
- (BOOL)isFinished:(WKMediaType)type;

/**
 *
 */
- (__kindof WKFrame *)copyAudioFrame:(WKTimeReader)timeReader;
- (__kindof WKFrame *)copyVideoFrame:(WKTimeReader)timeReader;

@end

@protocol WKPlayerItemDelegate <NSObject>

/**
 *
 */
- (void)playerItem:(WKPlayerItem *)playerItem didChangeState:(WKPlayerItemState)state;

/**
 *
 */
- (void)playerItem:(WKPlayerItem *)playerItem didChangeCapacity:(WKCapacity)capacity type:(WKMediaType)type;

@end
