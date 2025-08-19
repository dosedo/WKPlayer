//
//  WKMutilDemuxer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMutilDemuxer.h"
#import "WKError.h"

@interface WKMutilDemuxer ()

@property (nonatomic, strong, readonly) NSArray<id<WKDemuxable>> *demuxers;
@property (nonatomic, strong, readonly) NSMutableArray<WKTrack *> *finishedTracksInternal;
@property (nonatomic, strong, readonly) NSMutableArray<id<WKDemuxable>> *finishedDemuxers;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSValue *> *timeStamps;

@end

@implementation WKMutilDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize metadata = _metadata;

- (instancetype)initWithDemuxables:(NSArray<id<WKDemuxable>> *)demuxables
{
    if (self = [super init]) {
        self->_demuxers = demuxables;
        self->_finishedDemuxers = [NSMutableArray array];
        self->_finishedTracksInternal = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<WKDemuxableDelegate>)delegate
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        obj.delegate = delegate;
    }
}

- (id<WKDemuxableDelegate>)delegate
{
    return self->_demuxers.firstObject.delegate;
}

- (void)setOptions:(WKDemuxerOptions *)options
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        obj.options = options;
    }
}

- (WKDemuxerOptions *)options
{
    return self->_demuxers.firstObject.options;
}

- (NSArray<WKTrack *> *)finishedTracks
{
    return self->_finishedTracksInternal.copy;
}

#pragma mark - Control

- (id<WKDemuxable>)sharedDemuxer
{
    return nil;
}

- (NSError *)open
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        NSError *error = [obj open];
        if (error) {
            return error;
        }
    }
    CMTime duration = kCMTimeZero;
    NSMutableArray<WKTrack *> *tracks = [NSMutableArray array];
    for (id<WKDemuxable> obj in self->_demuxers) {
        NSAssert(CMTIME_IS_VALID(obj.duration), @"Invalid Duration.");
        duration = CMTimeMaximum(duration, obj.duration);
        [tracks addObjectsFromArray:obj.tracks];
    }
    self->_duration = duration;
    self->_tracks = [tracks copy];
    NSMutableArray<NSNumber *> *indexes = [NSMutableArray array];
    for (WKTrack *obj in self->_tracks) {
        NSAssert(![indexes containsObject:@(obj.index)], @"Invalid Track Indexes");
        [indexes addObject:@(obj.index)];
    }
    self->_timeStamps = [NSMutableDictionary dictionary];
    return nil;
}

- (NSError *)close
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        NSError *error = [obj close];
        if (error) {
            return error;
        }
    }
    return nil;
}

- (NSError *)seekable
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        NSError *error = [obj seekable];
        if (error) {
            return error;
        }
    }
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
    for (id<WKDemuxable> obj in self->_demuxers) {
        NSError *error = [obj seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
        if (error) {
            return error;
        }
    }
    [self->_timeStamps removeAllObjects];
    [self->_finishedDemuxers removeAllObjects];
    [self->_finishedTracksInternal removeAllObjects];
    return nil;
}

- (NSError *)nextPacket:(WKPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        id<WKDemuxable> demuxable = nil;
        CMTime minimumTime = kCMTimePositiveInfinity;
        for (id<WKDemuxable> obj in self->_demuxers) {
            if ([self->_finishedDemuxers containsObject:obj]) {
                continue;
            }
            NSString *key = [NSString stringWithFormat:@"%p", obj];
            NSValue *value = [self->_timeStamps objectForKey:key];
            if (!value) {
                demuxable = obj;
                break;
            }
            CMTime time = kCMTimePositiveInfinity;
            [value getValue:&time];
            if (CMTimeCompare(time, minimumTime) < 0) {
                minimumTime = time;
                demuxable = obj;
            }
        }
        if (!demuxable) {
            return WKCreateError(WKErrorCodeDemuxerEndOfFile, WKActionCodeMutilDemuxerNext);
        }
        error = [demuxable nextPacket:packet];
        if (error) {
            if (error.code == WKErrorImmediateExitRequested) {
                break;
            }
            [self->_finishedDemuxers addObject:demuxable];
            [self->_finishedTracksInternal addObjectsFromArray:demuxable.tracks];
            continue;
        }
        CMTime decodeTimeStamp = (*packet).decodeTimeStamp;
        NSString *key = [NSString stringWithFormat:@"%p", demuxable];
        NSValue *value = [NSValue value:&decodeTimeStamp withObjCType:@encode(CMTime)];
        [self->_timeStamps setObject:value forKey:key];
        break;
    }
    return error;
}

@end
