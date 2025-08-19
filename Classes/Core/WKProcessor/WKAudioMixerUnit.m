//
//  WKAudioMixerUnit.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioMixerUnit.h"

@interface WKAudioMixerUnit ()

{
    WKCapacity _capacity;
}

@property (nonatomic, strong, readonly) NSMutableArray<WKAudioFrame *> *frames;

@end

@implementation WKAudioMixerUnit

- (instancetype)init
{
    if (self = [super init]) {
        [self flush];
    }
    return self;
}

- (void)dealloc
{
    for (WKAudioFrame *obj in self->_frames) {
        [obj unlock];
    }
}

#pragma mark - Control

- (BOOL)putFrame:(WKAudioFrame *)frame
{
    if (CMTIMERANGE_IS_VALID(self->_timeRange) &&
        CMTimeCompare(CMTimeAdd(frame.timeStamp, frame.duration), CMTimeRangeGetEnd(self->_timeRange)) <= 0) {
        return NO;
    }
    [frame lock];
    [self->_frames addObject:frame];
    [self updateTimeRange];
    return YES;
}

- (NSArray<WKAudioFrame *> *)framesToEndTime:(CMTime)endTime
{
    NSMutableArray<WKAudioFrame *> *ret = [NSMutableArray array];
    NSMutableArray<WKAudioFrame *> *remove = [NSMutableArray array];
    for (WKAudioFrame *obj in self->_frames) {
        if (CMTimeCompare(obj.timeStamp, endTime) < 0) {
            [obj lock];
            [ret addObject:obj];
        }
        if (CMTimeCompare(CMTimeAdd(obj.timeStamp, obj.duration), endTime) <= 0) {
            [obj unlock];
            [remove addObject:obj];
        }
    }
    [self->_frames removeObjectsInArray:remove];
    [self updateTimeRange];
    return [ret copy];
}

- (WKCapacity)capacity
{
    return self->_capacity;
}

- (void)flush
{
    for (WKAudioFrame *obj in self->_frames) {
        [obj unlock];
    }
    self->_capacity = WKCapacityCreate();
    self->_frames = [NSMutableArray array];
    self->_timeRange = kCMTimeRangeInvalid;
}

#pragma mark - Internal

- (void)updateTimeRange
{
    self->_capacity.count = (int)self->_frames.count;
    if (self->_frames.count == 0) {
        self->_timeRange = kCMTimeRangeInvalid;
    } else {
        CMTime start = self->_frames.firstObject.timeStamp;
        CMTime end = CMTimeAdd(self->_frames.lastObject.timeStamp, self->_frames.lastObject.duration);
        self->_timeRange = CMTimeRangeFromTimeToTime(start, end);
    }
}

@end
