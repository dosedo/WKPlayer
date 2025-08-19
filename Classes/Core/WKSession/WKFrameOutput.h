//
//  WKFrameOutput.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDemuxerOptions.h"
#import "WKDecoderOptions.h"
#import "WKCapacity.h"
#import "WKAsset.h"
#import "WKFrame.h"

@protocol WKFrameOutputDelegate;

/**
 *
 */
typedef NS_ENUM(NSUInteger, WKFrameOutputState) {
    WKFrameOutputStateNone     = 0,
    WKFrameOutputStateOpening  = 1,
    WKFrameOutputStateOpened   = 2,
    WKFrameOutputStateReading  = 3,
    WKFrameOutputStateSeeking  = 4,
    WKFrameOutputStateFinished = 5,
    WKFrameOutputStateClosed   = 6,
    WKFrameOutputStateFailed   = 7,
};

@interface WKFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAsset:(WKAsset *)asset;

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
@property (nonatomic, weak) id<WKFrameOutputDelegate> delegate;

/**
 *
 */
@property (nonatomic, readonly) WKFrameOutputState state;

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
@property (nonatomic, copy, readonly) NSArray<WKTrack *> *selectedTracks;

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
- (BOOL)start;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause:(WKMediaType)type;

/**
 *
 */
- (BOOL)resume:(WKMediaType)type;

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
- (BOOL)selectTracks:(NSArray<WKTrack *> *)tracks;

/**
 *
 */
- (WKCapacity)capacityWithType:(WKMediaType)type;

@end

@protocol WKFrameOutputDelegate <NSObject>

/**
 *
 */
- (void)frameOutput:(WKFrameOutput *)frameOutput didChangeState:(WKFrameOutputState)state;

/**
 *
 */
- (void)frameOutput:(WKFrameOutput *)frameOutput didChangeCapacity:(WKCapacity)capacity type:(WKMediaType)type;

/**
 *
 */
- (void)frameOutput:(WKFrameOutput *)frameOutput didOutputFrames:(NSArray<__kindof WKFrame *> *)frames needsDrop:(BOOL(^)(void))needsDrop;

@end
