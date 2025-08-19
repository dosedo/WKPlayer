//
//  WKExtractingDemuxer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKExtractingDemuxer.h"
#import "WKPacket+Internal.h"
#import "WKObjectQueue.h"
#import "WKError.h"
#import "WKMacro.h"

@interface WKExtractingDemuxer ()

{
    struct {
        BOOL finished;
        BOOL inputting;
        BOOL outputting;
    } _flags;
}

@property (nonatomic, strong, readonly) WKTrack *track;
@property (nonatomic, strong, readonly) WKTimeLayout *scaleLayout;
@property (nonatomic, strong, readonly) WKTimeLayout *offsetLayout;
@property (nonatomic, strong, readonly) WKObjectQueue *packetQueue;

@end

@implementation WKExtractingDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithDemuxable:(id<WKDemuxable>)demuxable index:(NSInteger)index timeRange:(CMTimeRange)timeRange scale:(CMTime)scale
{
    if (self = [super init]) {
        self->_overgop = YES;
        self->_scale = scale;
        self->_index = index;
        self->_demuxable = demuxable;
        self->_timeRange = WKCMTimeRangeFitting(timeRange);
        self->_packetQueue = [[WKObjectQueue alloc] init];
    }
    return self;
}

#pragma mark - Mapping

WKGet0Map(id<WKDemuxableDelegate>, delegate, self->_demuxable)
WKSet1Map(void, setDelegate, id<WKDemuxableDelegate>, self->_demuxable)
WKGet0Map(WKDemuxerOptions *, options, self->_demuxable)
WKSet1Map(void, setOptions, WKDemuxerOptions *, self->_demuxable)
WKGet0Map(NSDictionary *, metadata, self->_demuxable)
WKGet0Map(NSError *, close, self->_demuxable)
WKGet0Map(NSError *, seekable, self->_demuxable)

#pragma mark - Control

- (id<WKDemuxable>)sharedDemuxer
{
    return [self->_demuxable sharedDemuxer];
}

- (NSError *)open
{
    NSError *error = [self->_demuxable open];
    if (error) {
        return error;
    }
    for (WKTrack *obj in self->_demuxable.tracks) {
        if (self->_index == obj.index) {
            self->_track = obj;
            self->_tracks = @[obj];
            break;
        }
    }
    CMTime start = self->_timeRange.start;
    if (!CMTIME_IS_NUMERIC(start)) {
        start = kCMTimeZero;
    }
    CMTime duration = self->_timeRange.duration;
    if (!CMTIME_IS_NUMERIC(duration)) {
        duration = CMTimeSubtract(self->_demuxable.duration, start);
    }
    self->_timeRange = CMTimeRangeMake(start, duration);
    self->_duration = WKCMTimeMultiply(duration, self->_scale);
    self->_scaleLayout = [[WKTimeLayout alloc] initWithScale:self->_scale];
    self->_offsetLayout = [[WKTimeLayout alloc] initWithOffset:CMTimeMultiply(start, -1)];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return WKCreateError(WKErrorCodeInvlidTime, WKActionCodeFormatSeekFrame);
    }
    time = [self->_scaleLayout reconvertTimeStamp:time];
    time = [self->_offsetLayout reconvertTimeStamp:time];
    NSError *error = [self->_demuxable seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
    if (error) {
        return error;
    }
    [self->_packetQueue flush];
    self->_flags.finished = NO;
    self->_flags.inputting = NO;
    self->_flags.outputting = NO;
    self->_finishedTracks = nil;
    return nil;
}

- (NSError *)nextPacket:(WKPacket **)packet
{
    if (self->_overgop) {
        return [self nextPacketInternalOvergop:packet];
    }
    return [self nextPacketInternal:packet];
}

- (NSError *)nextPacketInternal:(WKPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        WKPacket *pkt = nil;
        error = [self->_demuxable nextPacket:&pkt];
        if (error) {
            break;
        }
        if (self->_index != pkt.track.index) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start) < 0) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            [pkt unlock];
            error = WKCreateError(WKErrorCodeDemuxerEndOfFile, WKActionCodeURLDemuxerFunnelNext);
            break;
        }
        [pkt.codecDescriptor appendTimeLayout:self->_offsetLayout];
        [pkt.codecDescriptor appendTimeLayout:self->_scaleLayout];
        [pkt.codecDescriptor appendTimeRange:self->_timeRange];
        [pkt fill];
        *packet = pkt;
        break;
    }
    if (error.code == WKErrorCodeDemuxerEndOfFile) {
        self->_finishedTracks = self->_tracks.copy;
    }
    return error;
}

- (NSError *)nextPacketInternalOvergop:(WKPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        WKPacket *pkt = nil;
        if (self->_flags.outputting) {
            [self->_packetQueue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescriptor appendTimeLayout:self->_offsetLayout];
                [pkt.codecDescriptor appendTimeLayout:self->_scaleLayout];
                [pkt.codecDescriptor appendTimeRange:self->_timeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_flags.finished) {
            error = WKCreateError(WKErrorCodeDemuxerEndOfFile, WKActionCodeURLDemuxerFunnelNext);
            break;
        }
        error = [self->_demuxable nextPacket:&pkt];
        if (error) {
            if (error.code == WKErrorImmediateExitRequested) {
                break;
            }
            self->_flags.finished = YES;
            continue;
        }
        if (self->_index != pkt.track.index) {
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start) < 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                [self->_packetQueue flush];
                self->_flags.inputting = YES;
            }
            if (self->_flags.inputting) {
                [self->_packetQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_flags.finished = YES;
            } else {
                [self->_packetQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        if (!self->_flags.outputting && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self->_packetQueue flush];
        }
        self->_flags.outputting = YES;
        [self->_packetQueue putObjectSync:pkt];
        [pkt unlock];
        continue;
    }
    if (error.code == WKErrorCodeDemuxerEndOfFile) {
        self->_finishedTracks = self->_tracks.copy;
    }
    return error;
}

@end
