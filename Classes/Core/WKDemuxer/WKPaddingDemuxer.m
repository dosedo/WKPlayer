//
//  WKPaddingDemuxer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPaddingDemuxer.h"
#import "WKPacket+Internal.h"
#import "WKError.h"

@interface WKPaddingDemuxer ()

@property (nonatomic, readonly) CMTime lasttime;

@end

@implementation WKPaddingDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize metadata = _metadata;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithDuration:(CMTime)duration
{
    if (self = [super init]) {
        self->_duration = duration;
        [self seekToTime:kCMTimeZero];
    }
    return self;
}

#pragma mark - Control

- (id<WKDemuxable>)sharedDemuxer
{
    return nil;
}

- (NSError *)open
{
    return nil;
}

- (NSError *)close
{
    return nil;
}

- (NSError *)seekable
{
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
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    self->_lasttime = time;
    return nil;
}

- (NSError *)nextPacket:(WKPacket **)packet
{
    if (CMTimeCompare(self->_lasttime, self->_duration) >= 0) {
        return WKCreateError(WKErrorCodeDemuxerEndOfFile, WKActionCodeFormatReadFrame);
    }
    CMTime timeStamp = self->_lasttime;
    CMTime duration = CMTimeSubtract(self->_duration, self->_lasttime);
    WKPacket *pkt = [WKPacket packet];
    pkt.flags |= WKDataFlagPadding;
    pkt.core->size = 1;
    pkt.core->pts = av_rescale(AV_TIME_BASE, timeStamp.value, timeStamp.timescale);
    pkt.core->dts = av_rescale(AV_TIME_BASE, timeStamp.value, timeStamp.timescale);
    pkt.core->duration = av_rescale(AV_TIME_BASE, duration.value, duration.timescale);
    WKCodecDescriptor *cd = [[WKCodecDescriptor alloc] init];
    cd.timebase = AV_TIME_BASE_Q;
    [pkt setCodecDescriptor:cd];
    [pkt fill];
    *packet = pkt;
    self->_lasttime = self->_duration;
    return nil;
}

@end
