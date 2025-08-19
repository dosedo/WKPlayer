//
//  WKTime.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKTime.h"
#import "WKFFmpeg.h"

BOOL WKCMTimeIsValid(CMTime time, BOOL infinity)
{
    return
    CMTIME_IS_VALID(time) &&
    (infinity || (!CMTIME_IS_NEGATIVE_INFINITY(time) &&
                  !CMTIME_IS_POSITIVE_INFINITY(time)));
}

CMTime WKCMTimeValidate(CMTime time, CMTime defaultTime, BOOL infinity)
{
    if (WKCMTimeIsValid(time, infinity)) {
        return time;
    }
    NSCAssert(WKCMTimeIsValid(defaultTime, infinity), @"Invalid Default Time.");
    return defaultTime;
}

CMTime WKCMTimeMakeWithSeconds(Float64 seconds)
{
    return CMTimeMakeWithSeconds(seconds, AV_TIME_BASE);
}

CMTime WKCMTimeMultiply(CMTime time, CMTime multiplier)
{
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (multiplier.value > maxV || multiplier.value < -maxV || multiplier.timescale > maxT || multiplier.timescale < -maxT) {
        return CMTimeMultiplyByFloat64(time, CMTimeGetSeconds(multiplier));
    }
    return CMTimeMake(time.value * multiplier.value, time.timescale * multiplier.timescale);
}

CMTime WKCMTimeDivide(CMTime time, CMTime divisor)
{
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (divisor.timescale > maxV || divisor.timescale < -maxV || divisor.value > maxT || divisor.value < -maxT) {
        return CMTimeMultiplyByFloat64(time, 1.0 / CMTimeGetSeconds(divisor));
    }
    return CMTimeMake(time.value * divisor.timescale, time.timescale * (int32_t)divisor.value);
}

CMTimeRange WKCMTimeRangeFitting(CMTimeRange timeRange)
{
    return CMTimeRangeMake(WKCMTimeValidate(timeRange.start, kCMTimeNegativeInfinity, YES),
                           WKCMTimeValidate(timeRange.duration, kCMTimePositiveInfinity, YES));
}

CMTimeRange WKCMTimeRangeGetIntersection(CMTimeRange timeRange1, CMTimeRange timeRange2)
{
    CMTime start1 = WKCMTimeValidate(timeRange1.start, kCMTimeNegativeInfinity, YES);
    CMTime start2 = WKCMTimeValidate(timeRange2.start, kCMTimeNegativeInfinity, YES);
    CMTime end1 = WKCMTimeValidate(CMTimeRangeGetEnd(timeRange1), kCMTimePositiveInfinity, YES);
    CMTime end2 = WKCMTimeValidate(CMTimeRangeGetEnd(timeRange2), kCMTimePositiveInfinity, YES);
    return CMTimeRangeFromTimeToTime(CMTimeMaximum(start1, start2), CMTimeMinimum(end1, end2));
}
