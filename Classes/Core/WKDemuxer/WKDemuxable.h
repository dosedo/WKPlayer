//
//  WKDemuxable.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDemuxerOptions.h"
#import "WKPacket.h"

@protocol WKDemuxableDelegate;

@protocol WKDemuxable <NSObject>

/**
 *
 */
@property (nonatomic, copy) WKDemuxerOptions *options;

/**
 *
 */
@property (nonatomic, weak) id<WKDemuxableDelegate> delegate;

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
- (id<WKDemuxable>)sharedDemuxer;

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
- (NSError *)nextPacket:(WKPacket **)packet;

@end

@protocol WKDemuxableDelegate <NSObject>

/**
 *
 */
- (BOOL)demuxableShouldAbortBlockingFunctions:(id<WKDemuxable>)demuxable;

@end
