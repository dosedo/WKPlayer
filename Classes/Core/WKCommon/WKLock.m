//
//  WKLock.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKLock.h"

BOOL WKLockEXE00(id<NSLocking> locking, void (^run)(void))
{
    [locking lock];
    if (run) {
        run();
    }
    [locking unlock];
    return YES;
}

BOOL WKLockEXE10(id<NSLocking> locking, WKBlock (^run)(void))
{
    [locking lock];
    WKBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}

BOOL WKLockEXE11(id<NSLocking> locking, WKBlock (^run)(void), BOOL (^finish)(WKBlock block))
{
    [locking lock];
    WKBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (finish) {
        return finish(r ? r : ^{});
    } else if (r) {
        r();
    }
    return YES;
}

BOOL WKLockCondEXE00(id<NSLocking> locking, BOOL (^verify)(void), void (^run)(void))
{
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    if (run) {
        run();
    }
    [locking unlock];
    return YES;
}

BOOL WKLockCondEXE10(id<NSLocking> locking, BOOL (^verify)(void), WKBlock (^run)(void))
{
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    WKBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}

BOOL WKLockCondEXE11(id<NSLocking> locking, BOOL (^verify)(void), WKBlock (^run)(void), BOOL (^finish)(WKBlock block))
{
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    WKBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (finish) {
        return finish(r ? r : ^{});
    } else if (r) {
        r();
    }
    return YES;
}
