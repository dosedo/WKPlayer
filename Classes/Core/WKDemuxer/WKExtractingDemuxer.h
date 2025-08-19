//
//  WKExtractingDemuxer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDemuxable.h"

@interface WKExtractingDemuxer : NSObject <WKDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDemuxable:(id<WKDemuxable>)demuxable index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

/**
 *
 */
@property (nonatomic, strong, readonly) id<WKDemuxable> demuxable;

/**
 *
 */
@property (nonatomic, readonly) NSInteger index;

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
@property (nonatomic, readonly) CMTime scale;

/**
 *
 */
@property (nonatomic) BOOL overgop;

@end
