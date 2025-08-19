//
//  WKAudioMixer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioMixer.h"
#import "WKFrame+Internal.h"
#import "WKAudioMixerUnit.h"

@interface WKAudioMixer ()

@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, strong, readonly) WKAudioDescriptor *descriptor;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, WKAudioMixerUnit *> *units;

@end

@implementation WKAudioMixer

- (instancetype)initWithTracks:(NSArray<WKTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights
{
    if (self = [super init]) {
        self->_tracks = [tracks copy];
        self->_weights = [weights copy];
        self->_startTime = kCMTimeNegativeInfinity;
        self->_units = [NSMutableDictionary dictionary];
        for (WKTrack *obj in self->_tracks) {
            [self->_units setObject:[[WKAudioMixerUnit alloc] init] forKey:@(obj.index)];
        }
    }
    return self;
}

#pragma mark - Control

- (WKAudioFrame *)putFrame:(WKAudioFrame *)frame
{
    if (self->_tracks.count <= 1) {
        return frame;
    }
    if (CMTimeCompare(CMTimeAdd(frame.timeStamp, frame.duration), self->_startTime) <= 0) {
        [frame unlock];
        return nil;
    }
    if (!self->_descriptor) {
        self->_descriptor = frame.descriptor.copy;
    }
    NSAssert([self->_descriptor isEqualToDescriptor:frame.descriptor], @"Invalid Format.");
    NSAssert(self->_descriptor.format == AV_SAMPLE_FMT_FLTP, @"Invalid Format.");
    WKAudioMixerUnit *unit = [self->_units objectForKey:@(frame.track.index)];
    BOOL ret = [unit putFrame:frame];
    [frame unlock];
    if (ret) {
        return [self mixForPutFrame];
    }
    return nil;
}

- (WKAudioFrame *)finish
{
    if (self->_tracks.count <= 1) {
        return nil;
    }
    return [self mixForFinish];
}

- (WKCapacity)capacity
{
    __block WKCapacity capacity = WKCapacityCreate();
    [self->_units enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, WKAudioMixerUnit *obj, BOOL *stop) {
        capacity = WKCapacityMaximum(capacity, obj.capacity);
    }];
    return capacity;
}

- (void)flush
{
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, WKAudioMixerUnit *obj, BOOL *stop) {
        [obj flush];
    }];
    self->_startTime = kCMTimeNegativeInfinity;
}

#pragma mark - Mix

- (WKAudioFrame *)mixForPutFrame
{
    __block CMTime start = kCMTimePositiveInfinity;
    __block CMTime end = kCMTimePositiveInfinity;
    __block CMTime maximumDuration = kCMTimeZero;
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, WKAudioMixerUnit *obj, BOOL *stop) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            return;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_startTime);
        end = CMTimeMinimum(end, CMTimeRangeGetEnd(obj.timeRange));
        maximumDuration = CMTimeMaximum(maximumDuration, obj.timeRange.duration);
    }];
    if (CMTimeCompare(maximumDuration, CMTimeMake(8, 100)) < 0) {
        return nil;
    }
    return [self mixWithRange:CMTimeRangeFromTimeToTime(start, end)];
}

- (WKAudioFrame *)mixForFinish
{
    __block CMTime start = kCMTimePositiveInfinity;
    __block CMTime end = kCMTimeNegativeInfinity;
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, WKAudioMixerUnit *obj, BOOL *stop) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            return;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_startTime);
        end = CMTimeMaximum(end, CMTimeRangeGetEnd(obj.timeRange));
    }];
    if (CMTimeCompare(CMTimeSubtract(end, start), kCMTimeZero) <= 0) {
        return nil;
    }
    WKAudioFrame *frame = [self mixWithRange:CMTimeRangeFromTimeToTime(start, end)];
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, WKAudioMixerUnit *obj, BOOL *stop) {
        [obj flush];
    }];
    return frame;
}

- (WKAudioFrame *)mixWithRange:(CMTimeRange)range
{
    if (CMTIMERANGE_IS_INVALID(range)) {
        return nil;
    }
    self->_startTime = CMTimeRangeGetEnd(range);
    
    NSArray<NSNumber *> *weights = self->_weights;
    if (weights.count != self->_tracks.count) {
        NSMutableArray *obj = [NSMutableArray array];
        for (int i = 0; i < self->_tracks.count; i++) {
            [obj addObject:@(1.0 / self->_tracks.count)];
        }
        weights = [obj copy];
    } else {
        Float64 sum = 0;
        for (NSNumber *obj in weights) {
            sum += obj.doubleValue;
        }
        NSMutableArray *obj = [NSMutableArray array];
        for (int i = 0; i < self->_tracks.count; i++) {
            [obj addObject:@(weights[i].doubleValue / sum)];
        }
        weights = [obj copy];
    }
    
    CMTime start = range.start;
    CMTime duration = range.duration;
    WKAudioDescriptor *descriptor = self->_descriptor;
    int numberOfSamples = (int)CMTimeConvertScale(duration, descriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
    WKAudioFrame *ret = [WKAudioFrame frameWithDescriptor:descriptor numberOfSamples:numberOfSamples];
    NSMutableDictionary *list = [NSMutableDictionary dictionary];
    for (WKTrack *obj in self->_tracks) {
        NSArray *frames = [self->_units[@(obj.index)] framesToEndTime:CMTimeRangeGetEnd(range)];
        if (frames.count > 0) {
            [list setObject:frames forKey:@(obj.index)];
        }
    }
    NSMutableArray *discontinuous = [NSMutableArray array];
    for (int t = 0; t < self->_tracks.count; t++) {
        int lastEE = 0;
        for (WKAudioFrame *obj in list[@(self->_tracks[t].index)]) {
            int s = (int)CMTimeConvertScale(CMTimeSubtract(obj.timeStamp, start), descriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            int e = s + obj.numberOfSamples;
            int ss = MAX(0, s);
            int ee = MIN(numberOfSamples, e);
            if (ss - lastEE != 0) {
                NSRange range = NSMakeRange(MIN(ss, lastEE), ABS(ss - lastEE));
                [discontinuous addObject:[NSValue valueWithRange:range]];
            }
            lastEE = ee;
            for (int i = ss; i < ee; i++) {
                for (int c = 0; c < descriptor.numberOfPlanes; c++) {
                    ((float *)ret.core->data[c])[i] += (((float *)obj.data[c])[i - s] * weights[t].floatValue);
                }
            }
        }
    }
    for (NSValue *obj in discontinuous) {
        NSRange range = obj.rangeValue;
        for (int c = 0; c < descriptor.numberOfPlanes; c++) {
            float value = 0;
            if (range.location > 0) {
                value += ((float *)ret.core->data[c])[range.location - 1] * 0.5;
            }
            if (NSMaxRange(range) < numberOfSamples - 1) {
                value += ((float *)ret.core->data[c])[NSMaxRange(range)] * 0.5;
            }
            for (int i = (int)range.location; i < NSMaxRange(range); i++) {
                ((float *)ret.core->data[c])[i] = value;
            }
        }
    }
    [list enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *objs, BOOL *stop) {
        for (WKAudioFrame *obj in objs) {
            [obj unlock];
        }
    }];
    [ret setCodecDescriptor:[[WKCodecDescriptor alloc] init]];
    [ret fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    return ret;
}

@end
