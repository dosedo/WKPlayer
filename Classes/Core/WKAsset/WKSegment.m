//
//  WKSegment.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKSegment.h"
#import "WKSegment+Internal.h"
#import "WKPaddingSegment.h"
#import "WKURLSegment.h"

@implementation WKSegment

+ (instancetype)segmentWithDuration:(CMTime)duration
{
    return [[WKPaddingSegment alloc] initWithDuration:duration];
}

+ (instancetype)segmentWithURL:(NSURL *)URL index:(NSInteger)index
{
    return [[WKURLSegment alloc] initWithURL:URL index:index timeRange:kCMTimeRangeInvalid scale:kCMTimeInvalid];
}

+ (instancetype)segmentWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    return [[WKURLSegment alloc] initWithURL:URL index:index timeRange:timeRange scale:scale];
}

- (id)copyWithZone:(NSZone *)zone
{
    WKSegment *obj = [[self.class alloc] init];
    return obj;
}

- (NSString *)sharedDemuxerKey
{
    NSAssert(NO, @"Subclass only.");
    return nil;
}

- (id<WKDemuxable>)newDemuxer
{
    NSAssert(NO, @"Subclass only.");
    return nil;
}

- (id<WKDemuxable>)newDemuxerWithSharedDemuxer:(id<WKDemuxable>)demuxer
{
    NSAssert(NO, @"Subclass only.");
    return nil;
}

@end
