//
//  WKSegment.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface WKSegment : NSObject <NSCopying>

/*!
 @method segmentWithDuration:
 @abstract
    Returns an instance of WKSegment with the given duration.
 
 @discussion
    For audio track:
 *
 */
+ (instancetype)segmentWithDuration:(CMTime)duration;

/**
 *
 */
+ (instancetype)segmentWithURL:(NSURL *)URL index:(NSInteger)index;

/**
 *
 */
+ (instancetype)segmentWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

@end
