//
//  WKDecodeLoop.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDecodeLoop.h"
#import "WKDecodeContext.h"
#import "WKMacro.h"
#import "WKLock.h"

@interface WKDecodeLoop ()

{
    struct {
        WKDecodeLoopState state;
    } _flags;
    WKCapacity _capacity;
}

@property (nonatomic, copy, readonly) Class decoderClass;
@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSCondition *wakeup;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, WKDecodeContext *> *contexts;

@end

@implementation WKDecodeLoop

- (instancetype)initWithDecoderClass:(Class)decoderClass
{
    if (self = [super init]) {
        self->_decoderClass = decoderClass;
        self->_lock = [[NSLock alloc] init];
        self->_wakeup = [[NSCondition alloc] init];
        self->_capacity = WKCapacityCreate();
        self->_contexts = [[NSMutableDictionary alloc] init];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.maxConcurrentOperationCount = 1;
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

- (void)dealloc
{
    WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != WKDecodeLoopStateClosed;
    }, ^WKBlock {
        [self setState:WKDecodeLoopStateClosed];
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, WKDecodeContext *obj, BOOL *stop) {
            [obj destory];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

#pragma mark - Setter & Getter

- (WKBlock)setState:(WKDecodeLoopState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    WKDecodeLoopState previous = self->_flags.state;
    self->_flags.state = state;
    if (previous == WKDecodeLoopStatePaused ||
        previous == WKDecodeLoopStateStalled) {
        [self->_wakeup lock];
        [self->_wakeup broadcast];
        [self->_wakeup unlock];
    }
    return ^{
        [self->_delegate decodeLoop:self didChangeState:state];
    };
}

- (WKDecodeLoopState)state
{
    __block WKDecodeLoopState ret = WKDecodeLoopStateNone;
    WKLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (WKBlock)setCapacityIfNeeded
{
    __block WKCapacity capacity = WKCapacityCreate();
    [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, WKDecodeContext *obj, BOOL *stop) {
        capacity = WKCapacityMaximum(capacity, [obj capacity]);
    }];
    if (WKCapacityIsEqual(capacity, self->_capacity)) {
        return ^{};
    }
    self->_capacity = capacity;
    return ^{
        [self->_delegate decodeLoop:self didChangeCapacity:capacity];
    };
}

#pragma mark - Context

- (WKDecodeContext *)contextWithKey:(NSNumber *)key
{
    WKDecodeContext *context = self->_contexts[key];
    if (!context) {
        context = [[WKDecodeContext alloc] initWithDecoderClass:self->_decoderClass];
        context.options = self->_options;
        self->_contexts[key] = context;
    }
    return context;
}

- (WKDecodeContext *)currentDecodeContext
{
    WKDecodeContext *context = nil;
    CMTime minimum = kCMTimePositiveInfinity;
    for (NSNumber *key in self->_contexts) {
        WKDecodeContext *obj = self->_contexts[key];
        if ([obj capacity].count == 0) {
            continue;
        }
        CMTime dts = obj.decodeTimeStamp;
        if (!CMTIME_IS_NUMERIC(dts)) {
            context = obj;
            break;
        }
        if (CMTimeCompare(dts, minimum) < 0) {
            minimum = dts;
            context = obj;
            continue;
        }
    }
    return context;
}

- (WKDecodeContext *)currentPredecodeContext
{
    WKDecodeContext *context = nil;
    for (NSNumber *key in self->_contexts) {
        WKDecodeContext *obj = self->_contexts[key];
        if ([obj needsPredecode]) {
            context = obj;
            break;
        }
    }
    return context;
}

#pragma mark - Interface

- (BOOL)open
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKDecodeLoopStateNone;
    }, ^WKBlock {
        return [self setState:WKDecodeLoopStateDecoding];
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
        return
        self->_flags.state != WKDecodeLoopStateNone &&
        self->_flags.state != WKDecodeLoopStateClosed;
    }, ^WKBlock {
        return [self setState:WKDecodeLoopStateClosed];
    }, ^BOOL(WKBlock block) {
        block();
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, WKDecodeContext *obj, BOOL *stop) {
            [obj destory];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}

- (BOOL)pause
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != WKDecodeLoopStateNone &&
        self->_flags.state == WKDecodeLoopStateDecoding;
    }, ^WKBlock {
        return [self setState:WKDecodeLoopStatePaused];
    });
}

- (BOOL)resume
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != WKDecodeLoopStateNone &&
        self->_flags.state == WKDecodeLoopStatePaused;
    }, ^WKBlock {
        return [self setState:WKDecodeLoopStateDecoding];
    });
}

- (BOOL)flush
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != WKDecodeLoopStateNone &&
        self->_flags.state != WKDecodeLoopStateClosed;
    }, ^WKBlock {
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, WKDecodeContext *obj, BOOL *stop) {
            [obj setNeedsFlush];
        }];
        WKBlock b1 = ^{};
        WKBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == WKDecodeLoopStateStalled) {
            b1 = [self setState:WKDecodeLoopStateDecoding];
        }
        return ^{
            b1(); b2();
        };
    });
}

- (BOOL)finish:(NSArray<WKTrack *> *)tracks
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != WKDecodeLoopStateNone &&
        self->_flags.state != WKDecodeLoopStateClosed;
    }, ^WKBlock {
        for (WKTrack *obj in tracks) {
            WKDecodeContext *context = [self contextWithKey:@(obj.index)];
            [context markAsFinished];
        }
        WKBlock b1 = ^{};
        WKBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == WKDecodeLoopStateStalled) {
            b1 = [self setState:WKDecodeLoopStateDecoding];
        }
        return ^{
            b1(); b2();
        };
    });
}

- (BOOL)putPacket:(WKPacket *)packet
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state != WKDecodeLoopStateNone &&
        self->_flags.state != WKDecodeLoopStateClosed;
    }, ^WKBlock {
        WKDecodeContext *context = [self contextWithKey:@(packet.track.index)];
        [context putPacket:packet];
        WKBlock b1 = ^{};
        WKBlock b2 = [self setCapacityIfNeeded];
        if (self->_flags.state == WKDecodeLoopStatePaused && [context needsPredecode]) {
            [self->_wakeup lock];
            [self->_wakeup broadcast];
            [self->_wakeup unlock];
        } else if (self->_flags.state == WKDecodeLoopStateStalled) {
            b1 = [self setState:WKDecodeLoopStateDecoding];
        }
        return ^{
            b1(); b2();
        };
    });
}

#pragma mark - Thread

- (void)runningThread
{
    WKBlock lock = ^{
        [self->_lock lock];
    };
    WKBlock unlock = ^{
        [self->_lock unlock];
    };
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == WKDecodeLoopStateNone ||
                self->_flags.state == WKDecodeLoopStateClosed) {
                [self->_lock unlock];
                break;
            } else if (self->_flags.state == WKDecodeLoopStateStalled) {
                [self->_wakeup lock];
                [self->_lock unlock];
                [self->_wakeup wait];
                [self->_wakeup unlock];
                continue;
            } else if (self->_flags.state == WKDecodeLoopStatePaused) {
                WKDecodeContext *context = [self currentPredecodeContext];
                if (!context) {
                    [self->_wakeup lock];
                    [self->_lock unlock];
                    [self->_wakeup wait];
                    [self->_wakeup unlock];
                    continue;
                }
                [context predecode:lock unlock:unlock];
                [self->_lock unlock];
                continue;
            } else if (self->_flags.state == WKDecodeLoopStateDecoding) {
                WKDecodeContext *context = [self currentDecodeContext];
                if (!context) {
                    self->_flags.state = WKDecodeLoopStateStalled;
                    [self->_lock unlock];
                    continue;
                }
                NSArray *objs = [context decode:lock unlock:unlock];
                [self->_lock unlock];
                // TODO: In special cases, use needsDrop to determine whether needs to discard frames. It is not implemented now for performance reasons.
                [self->_delegate decodeLoop:self didOutputFrames:objs needsDrop:nil];
                for (WKFrame *obj in objs) {
                    [obj unlock];
                }
                [self->_lock lock];
                WKBlock b1 = [self setCapacityIfNeeded];
                [self->_lock unlock];
                b1();
                continue;
            }
        }
    }
}

@end
