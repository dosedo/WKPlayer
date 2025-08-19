//
//  WKTimeLayout.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKTimeLayout.h"

@implementation WKTimeLayout

- (id)copyWithZone:(NSZone *)zone
{
    WKTimeLayout *obj = [[WKTimeLayout alloc] init];
    obj->_scale = self->_scale;
    obj->_offset = self->_offset;
    return obj;
}

- (instancetype)initWithScale:(CMTime)scale
{
    if (self = [super init]) {
        self->_scale = WKCMTimeValidate(scale, CMTimeMake(1, 1), NO);
        self->_offset = kCMTimeInvalid;
    }
    return self;
}

- (instancetype)initWithOffset:(CMTime)offset
{
    if (self = [super init]) {
        self->_scale = kCMTimeInvalid;
        self->_offset = WKCMTimeValidate(offset, kCMTimeZero, NO);
    }
    return self;
}

- (CMTime)convertDuration:(CMTime)duration
{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        duration = WKCMTimeMultiply(duration, self->_scale);
    }
    return duration;
}

- (CMTime)convertTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        timeStamp = WKCMTimeMultiply(timeStamp, self->_scale);
    }
    if (CMTIME_IS_NUMERIC(self->_offset)) {
        timeStamp = CMTimeAdd(timeStamp, self->_offset);
    }
    return timeStamp;
}

- (CMTime)reconvertTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        timeStamp = WKCMTimeDivide(timeStamp, self->_scale);
    }
    if (CMTIME_IS_NUMERIC(self->_offset)) {
        timeStamp = CMTimeSubtract(timeStamp, self->_offset);
    }
    return timeStamp;
}

- (BOOL)isEqualToTimeLayout:(WKTimeLayout *)timeLayout
{
    if (!timeLayout) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_scale, self->_scale) != 0) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_offset, self->_offset) != 0) {
        return NO;
    }
    return YES;
}

@end
