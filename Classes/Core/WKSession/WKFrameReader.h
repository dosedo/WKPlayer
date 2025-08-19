//
//  WKFrameReader.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDemuxerOptions.h"
#import "WKDecoderOptions.h"
#import "WKAsset.h"
#import "WKFrame.h"

@protocol WKFrameReaderDelegate;

@interface WKFrameReader : NSObject

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
@property (nonatomic, weak) id<WKFrameReaderDelegate> delegate;

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
- (NSError *)open;

/**
 *
 */
- (NSError *)close;

/**
 *
 */
- (NSError *)seekable;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter;

/**
 *
 */
- (NSError *)selectTracks:(NSArray<WKTrack *> *)tracks;

/**
 *
 */
- (NSError *)nextFrame:(__kindof WKFrame **)frame;

@end

@protocol WKFrameReaderDelegate <NSObject>

/**
 *
 */
- (BOOL)frameReaderShouldAbortBlockingFunctions:(WKFrameReader *)frameReader;

@end
