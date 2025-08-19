//
//  WKPaddingSegment.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPaddingSegment.h"
#import "WKSegment+Internal.h"
#import "WKPaddingDemuxer.h"

@implementation WKPaddingSegment

- (id)copyWithZone:(NSZone *)zone
{
    WKPaddingSegment *obj = [super copyWithZone:zone];
    obj->_duration = self->_duration;
    return obj;
}

- (instancetype)initWithDuration:(CMTime)duration
{
    if (self = [super init]) {
        self->_duration = duration;
    }
    return self;
}

- (NSString *)sharedDemuxerKey
{
    return nil;
}

- (id<WKDemuxable>)newDemuxer
{
    return [[WKPaddingDemuxer alloc] initWithDuration:self->_duration];
}

- (id<WKDemuxable>)newDemuxerWithSharedDemuxer:(id<WKDemuxable>)demuxer
{
    return [self newDemuxer];
}

@end
