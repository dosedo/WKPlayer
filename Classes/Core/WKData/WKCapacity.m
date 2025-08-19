//
//  WKCapacity.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKCapacity.h"

WKCapacity WKCapacityCreate(void)
{
    WKCapacity ret;
    ret.size = 0;
    ret.count = 0;
    ret.duration = kCMTimeZero;
    return ret;
}

WKCapacity WKCapacityAdd(WKCapacity c1, WKCapacity c2)
{
    WKCapacity ret = WKCapacityCreate();
    ret.size = c1.size + c2.size;
    ret.count = c1.count + c2.count;
    ret.duration = CMTimeAdd(c1.duration, c2.duration);
    return ret;
}

WKCapacity WKCapacityMinimum(WKCapacity c1, WKCapacity c2)
{
    if (CMTimeCompare(c1.duration, c2.duration) < 0) {
        return c1;
    } else if (CMTimeCompare(c1.duration, c2.duration) > 0) {
        return c1;
    }
    if (c1.count < c2.count) {
        return c1;
    } else if (c1.count > c2.count) {
        return c2;
    }
    if (c1.size < c2.size) {
        return c1;
    } else if (c1.size > c2.size) {
        return c2;
    }
    return c1;
}

WKCapacity WKCapacityMaximum(WKCapacity c1, WKCapacity c2)
{
    if (CMTimeCompare(c1.duration, c2.duration) < 0) {
        return c2;
    } else if (CMTimeCompare(c1.duration, c2.duration) > 0) {
        return c1;
    }
    if (c1.count < c2.count) {
        return c2;
    } else if (c1.count > c2.count) {
        return c1;
    }
    if (c1.size < c2.size) {
        return c2;
    } else if (c1.size > c2.size) {
        return c1;
    }
    return c1;
}

BOOL WKCapacityIsEqual(WKCapacity c1, WKCapacity c2)
{
    return
    c1.size == c2.size &&
    c1.count == c2.count &&
    CMTimeCompare(c1.duration, c2.duration) == 0;
}

BOOL WKCapacityIsEnough(WKCapacity c1)
{
    /*
    return
    c1.count >= 30 &&
    CMTimeCompare(c1.duration, CMTimeMake(1, 1)) > 0;
     */
    return
    c1.count >= 50000;
}

BOOL WKCapacityIsEmpty(WKCapacity c1)
{
    return
    c1.size == 0 &&
    c1.count == 0 &&
    (CMTIME_IS_INVALID(c1.duration) ||
     CMTimeCompare(c1.duration, kCMTimeZero) == 0);
}
