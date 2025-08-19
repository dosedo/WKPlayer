//
//  WKURLSource.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPacketOutput.h"
#import "WKAsset+Internal.h"
#import "WKOptions.h"
#import "WKError.h"
#import "WKMacro.h"
#import "WKLock.h"

@interface WKPacketOutput () <WKDemuxableDelegate>

{
    struct {
        NSError *error;
        WKPacketOutputState state;
    } _flags;
    struct {
        CMTime seekTime;
        CMTime seekToleranceBefor;
        CMTime seekToleranceAfter;
        WKSeekResult seekResult;
    } _seekFlags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSCondition *wakeup;
@property (nonatomic, strong, readonly) id<WKDemuxable> demuxable;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

@end

@implementation WKPacketOutput

- (instancetype)initWithAsset:(WKAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
        self->_demuxable = [asset newDemuxer];
        self->_demuxable.delegate = self;
        self->_demuxable.options = [WKOptions sharedOptions].demuxer.copy;
    }
    return self;
}

- (void)dealloc
{
    WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != WKPacketOutputStateClosed;
    }, ^WKBlock {
        [self setState:WKPacketOutputStateClosed];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Mapping

WKGet0Map(CMTime, duration, self->_demuxable)
WKGet0Map(NSDictionary *, metadata, self->_demuxable)
WKGet0Map(NSArray<WKTrack *> *, tracks, self->_demuxable)
WKGet0Map(NSArray<WKTrack *> *, finishedTracks, self->_demuxable)
WKGet0Map(WKDemuxerOptions *, options, self->_demuxable)
WKSet1Map(void, setOptions, WKDemuxerOptions *, self->_demuxable)

#pragma mark - Setter & Getter

- (WKBlock)setState:(WKPacketOutputState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    [self->_wakeup lock];
    [self->_wakeup broadcast];
    [self->_wakeup unlock];
    return ^{
        [self->_delegate packetOutput:self didChangeState:state];
    };
}

- (WKPacketOutputState)state
{
    __block WKPacketOutputState ret = WKPacketOutputStateNone;
    WKLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = [self->_flags.error copy];
    });
    return ret;
}

#pragma mark - Control

- (BOOL)open
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKPacketOutputStateNone;
    }, ^WKBlock {
        return [self setState:WKPacketOutputStateOpening];
    }, ^BOOL(WKBlock block) {
        block();
        NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runningThread) object:nil];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self->_operationQueue addOperation:operation];
        return YES;
    });
}

- (BOOL)close
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state != WKPacketOutputStateClosed;
    }, ^WKBlock {
        return [self setState:WKPacketOutputStateClosed];
    }, ^BOOL(WKBlock block) {
        block();
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == WKPacketOutputStateReading ||
        self->_flags.state == WKPacketOutputStateSeeking;
    }, ^WKBlock {
        return [self setState:WKPacketOutputStatePaused];
    });
}

- (BOOL)resume
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == WKPacketOutputStatePaused ||
        self->_flags.state == WKPacketOutputStateOpened;
    }, ^WKBlock {
        return [self setState:WKPacketOutputStateReading];
    });
}

#pragma mark - Seeking

- (BOOL)seekable
{
    return [self->_demuxable seekable] == nil;
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time result:nil];
}

- (BOOL)seekToTime:(CMTime)time result:(WKSeekResult)result
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
}

- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(WKSeekResult)result
{
    if (![self seekable]) {
        return NO;
    }
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == WKPacketOutputStateOpened ||
        self->_flags.state == WKPacketOutputStateReading ||
        self->_flags.state == WKPacketOutputStatePaused ||
        self->_flags.state == WKPacketOutputStateSeeking ||
        self->_flags.state == WKPacketOutputStateFinished;
    }, ^WKBlock {
        WKBlock b1 = ^{}, b2 = ^{};
        if (self->_seekFlags.seekResult) {
            CMTime lastSeekTime = self->_seekFlags.seekTime;
            WKSeekResult lastSeekResult = self->_seekFlags.seekResult;
            b1 = ^{
                lastSeekResult(lastSeekTime,
                               WKCreateError(WKErrorCodePacketOutputCancelSeek,
                                             WKActionCodePacketOutputSeek));
            };
        }
        self->_seekFlags.seekTime = time;
        self->_seekFlags.seekToleranceBefor = toleranceBefor;
        self->_seekFlags.seekToleranceAfter = toleranceAfter;
        self->_seekFlags.seekResult = [result copy];
        b2 = [self setState:WKPacketOutputStateSeeking];
        return ^{
            b1(); b2();
        };
    });
}

#pragma mark - Threading

- (void)runningThread
{
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == WKPacketOutputStateNone ||
                self->_flags.state == WKPacketOutputStateClosed ||
                self->_flags.state == WKPacketOutputStateFailed) {
                [self->_lock unlock];
                break;
            } else if (self->_flags.state == WKPacketOutputStateOpening) {
                [self->_lock unlock];
                NSError *error = [self->_demuxable open];
                [self->_lock lock];
                if (self->_flags.state != WKPacketOutputStateOpening) {
                    [self->_lock unlock];
                    continue;
                }
                self->_flags.error = error;
                WKBlock b1 = [self setState:error ? WKPacketOutputStateFailed : WKPacketOutputStateOpened];
                [self->_lock unlock];
                b1();
                continue;
            } else if (self->_flags.state == WKPacketOutputStateOpened ||
                       self->_flags.state == WKPacketOutputStatePaused ||
                       self->_flags.state == WKPacketOutputStateFinished) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_flags.state == WKPacketOutputStateSeeking) {
                CMTime seekingTime = self->_seekFlags.seekTime;
                CMTime seekingToleranceBefor = self->_seekFlags.seekToleranceBefor;
                CMTime seekingToleranceAfter = self->_seekFlags.seekToleranceAfter;
                [self->_lock unlock];
                NSError *error = [self->_demuxable seekToTime:seekingTime toleranceBefor:seekingToleranceBefor toleranceAfter:seekingToleranceAfter];
                [self->_lock lock];
                if (self->_flags.state == WKPacketOutputStateSeeking &&
                    CMTimeCompare(self->_seekFlags.seekTime, seekingTime) != 0) {
                    [self->_lock unlock];
                    continue;
                }
                WKBlock b1 = ^{}, b2 = ^{};
                if (self->_seekFlags.seekResult) {
                    CMTime seekTime = self->_seekFlags.seekTime;
                    WKSeekResult seek_result = self->_seekFlags.seekResult;
                    b1 = ^{
                        seek_result(seekTime, error);
                    };
                }
                if (self->_flags.state == WKPacketOutputStateSeeking) {
                    b2 = [self setState:WKPacketOutputStateReading];
                }
                self->_seekFlags.seekTime = kCMTimeZero;
                self->_seekFlags.seekToleranceBefor = kCMTimeInvalid;
                self->_seekFlags.seekToleranceAfter = kCMTimeInvalid;
                self->_seekFlags.seekResult = nil;
                [self->_lock unlock];
                b1(); b2();
                continue;
            } else if (self->_flags.state == WKPacketOutputStateReading) {
                [self->_lock unlock];
                WKPacket *packet = nil;
                NSError *error = [self->_demuxable nextPacket:&packet];
                if (error) {
                    WKLockCondEXE10(self->_lock, ^BOOL {
                        return self->_flags.state == WKPacketOutputStateReading;
                    }, ^WKBlock{
                        return [self setState:WKPacketOutputStateFinished];
                    });
                } else {
                    [self->_delegate packetOutput:self didOutputPacket:packet];
                    [packet unlock];
                }
                continue;
            }
        }
    }
    [self->_demuxable close];
}

#pragma mark - WKDemuxableDelegate

- (BOOL)demuxableShouldAbortBlockingFunctions:(id<WKDemuxable>)demuxable
{
    return WKLockCondEXE00(self->_lock, ^BOOL {
        switch (self->_flags.state) {
            case WKPacketOutputStateFinished:
            case WKPacketOutputStateClosed:
            case WKPacketOutputStateFailed:
                return YES;
            default:
                return NO;
        }
    }, nil);
}

@end
