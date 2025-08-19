//
//  WKURLSegment.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKURLSegment.h"
#import "WKSegment+Internal.h"
#import "WKExtractingDemuxer.h"
#import "WKURLDemuxer.h"
#import "WKTime.h"

@implementation WKURLSegment

- (id)copyWithZone:(NSZone *)zone
{
    WKURLSegment *obj = [super copyWithZone:zone];
    obj->_URL = [self->_URL copy];
    obj->_index = self->_index;
    obj->_timeRange = self->_timeRange;
    obj->_scale = self->_scale;
    return obj;
}

- (instancetype)initWithURL:(NSURL *)URL index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    scale = WKCMTimeValidate(scale, CMTimeMake(1, 1), NO);
    NSAssert(CMTimeCompare(scale, CMTimeMake(1, 10)) >= 0, @"Invalid Scale.");
    NSAssert(CMTimeCompare(scale, CMTimeMake(10, 1)) <= 0, @"Invalid Scale.");
    if (self = [super init]) {
        self->_URL = [URL copy];
        self->_index = index;
        self->_timeRange = timeRange;
        self->_scale = scale;
    }
    return self;
}

- (NSString *)sharedDemuxerKey
{
    return self->_URL.isFileURL ? self->_URL.path : self->_URL.absoluteString;
}

- (id<WKDemuxable>)newDemuxer
{
    return [self newDemuxerWithSharedDemuxer:nil];
}

- (id<WKDemuxable>)newDemuxerWithSharedDemuxer:(id<WKDemuxable>)demuxer
{
    if (!demuxer) {
        demuxer = [[WKURLDemuxer alloc] initWithURL:self->_URL];
    }
    WKExtractingDemuxer *obj = [[WKExtractingDemuxer alloc] initWithDemuxable:demuxer index:self->_index timeRange:self->_timeRange scale:self->_scale];
    return obj;
}

@end
