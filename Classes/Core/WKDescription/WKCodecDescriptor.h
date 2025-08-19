//
//  WKCodecDescriptor.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTimeLayout.h"
#import "WKFFmpeg.h"
#import "WKTrack.h"

@interface WKCodecDescriptor : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic) AVRational timebase;

/**
 *
 */
@property (nonatomic) AVCodecParameters *codecpar;

/**
 *
 */
@property (nonatomic, strong) WKTrack *track;

/**
 *
 */
@property (nonatomic, strong) NSDictionary *metadata;

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
- (CMTime)convertTimeStamp:(CMTime)timeStamp;

/**
 *
 */
- (CMTime)convertDuration:(CMTime)duration;

/**
 *
 */
- (void)appendTimeRange:(CMTimeRange)timeRange;

/**
 *
 */
- (void)appendTimeLayout:(WKTimeLayout *)timeLayout;

/**
 *
 */
- (void)fillToDescriptor:(WKCodecDescriptor *)descriptor;

/**
 *
 */
- (BOOL)isEqualToDescriptor:(WKCodecDescriptor *)descriptor;

/**
 *
 */
- (BOOL)isEqualCodecContextToDescriptor:(WKCodecDescriptor *)descriptor;

@end
