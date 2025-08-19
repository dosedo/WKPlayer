//
//  WKPacket.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPacket.h"
#import "WKPacket+Internal.h"
#import "WKObjectPool.h"

@interface WKPacket ()

{
    NSLock *_lock;
    uint64_t _lockingCount;
}

@end

@implementation WKPacket

@synthesize flags = _flags;
@synthesize reuseName = _reuseName;

+ (instancetype)packet
{
    static NSString *name = @"WKPacket";
    return [[WKObjectPool sharedPool] objectWithClass:[self class] reuseName:name];
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_core = av_packet_alloc();
        self->_coreptr = self->_core;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self->_lockingCount == 0, @"WKPacket, Invalid locking count");
    [self clear];
    if (self->_core) {
        av_packet_free(&self->_core);
        self->_core = nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>, track: %d, pts: %f, end: %f, duration: %f",
            NSStringFromClass(self.class), self,
            (int)self->_codecDescriptor.track.index,
            CMTimeGetSeconds(self->_timeStamp),
            CMTimeGetSeconds(CMTimeAdd(self->_timeStamp, self->_duration)),
            CMTimeGetSeconds(self->_duration)];
}

#pragma mark - Setter & Getter

#pragma mark - Data

- (void)lock
{
    [self->_lock lock];
    self->_lockingCount += 1;
    [self->_lock unlock];
}

- (void)unlock
{
    [self->_lock lock];
    NSAssert(self->_lockingCount > 0, @"WKPacket, Invalid locking count");
    self->_lockingCount -= 1;
    BOOL comeback = self->_lockingCount == 0;
    [self->_lock unlock];
    if (comeback) {
        [[WKObjectPool sharedPool] comeback:self];
    }
}

- (void)clear
{
    if (self->_core) {
        av_packet_unref(self->_core);
    }
    self->_size = 0;
    self->_flags = 0;
    self->_track = nil;
    self->_duration = kCMTimeZero;
    self->_timeStamp = kCMTimeZero;
    self->_decodeTimeStamp = kCMTimeZero;
    self->_codecDescriptor = nil;
}

#pragma mark - Control

- (void)fill
{
    AVPacket *pkt = self->_core;
    AVRational timebase = self->_codecDescriptor.timebase;
    WKCodecDescriptor *cd = self->_codecDescriptor;
    if (pkt->pts == AV_NOPTS_VALUE) {
        pkt->pts = pkt->dts;
    }
    self->_size = pkt->size;
    self->_track = cd.track;
    self->_metadata = cd.metadata;
    CMTime duration = CMTimeMake(pkt->duration * timebase.num, timebase.den);
    CMTime timeStamp = CMTimeMake(pkt->pts * timebase.num, timebase.den);
    CMTime decodeTimeStamp = CMTimeMake(pkt->dts * timebase.num, timebase.den);
    self->_duration = [cd convertDuration:duration];
    self->_timeStamp = [cd convertTimeStamp:timeStamp];
    self->_decodeTimeStamp = [cd convertTimeStamp:decodeTimeStamp];
}

@end
