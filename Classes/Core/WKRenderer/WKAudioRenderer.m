//
//  WKAudioRenderer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioRenderer.h"
#import "WKRenderer+Internal.h"
#import "WKAudioPlayer.h"
#import "WKAudioFrame.h"
#import "WKOptions.h"
#import "WKFFmpeg.h"
#import "WKLock.h"

@interface WKAudioRenderer () <WKAudioPlayerDelegate>

{
    struct {
        WKRenderableState state;
        CMTime renderTime;
        CMTime renderDuration;
        int bufferCopiedFrames;
        int currentFrameCopiedFrames;
    } _flags;
    WKCapacity _capacity;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) WKClock *clock;
@property (nonatomic, strong, readonly) WKAudioPlayer *player;
@property (nonatomic, strong, readonly) WKAudioFrame *currentFrame;

@end

@implementation WKAudioRenderer

@synthesize rate = _rate;
@synthesize pitch = _pitch;
@synthesize volume = _volume;
@synthesize delegate = _delegate;
@synthesize descriptor = _descriptor;

+ (WKAudioDescriptor *)supportedAudioDescriptor
{
    return [[WKAudioDescriptor alloc] init];
}

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithClock:(WKClock *)clock
{
    if (self = [super init]) {
        self->_clock = clock;
        self->_rate = 1.0;
        self->_pitch = 0.0;
        self->_volume = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_capacity = WKCapacityCreate();
        self->_descriptor = [WKAudioRenderer supportedAudioDescriptor];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Setter & Getter

- (WKBlock)setState:(WKRenderableState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (WKRenderableState)state
{
    __block WKRenderableState ret = WKRenderableStateNone;
    WKLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (WKCapacity)capacity
{
    __block WKCapacity ret;
    WKLockEXE00(self->_lock, ^{
        ret = self->_capacity;
    });
    return ret;
}

- (void)setRate:(Float64)rate
{
    WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_rate != rate;
    }, ^WKBlock {
        self->_rate = rate;
        return nil;
    }, ^BOOL(WKBlock block) {
        self->_player.rate = rate;
        return YES;
    });
}

- (Float64)rate
{
    __block Float64 ret = 1.0;
    WKLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (void)setPitch:(Float64)pitch
{
    WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_pitch != pitch;
    }, ^WKBlock {
        self->_pitch = pitch;
        return nil;
    }, ^BOOL(WKBlock block) {
        self->_player.pitch = pitch;
        return YES;
    });
}

- (Float64)pitch
{
    __block Float64 ret = 0.0f;
    WKLockEXE00(self->_lock, ^{
        ret = self->_pitch;
    });
    return ret;
}

- (void)setVolume:(Float64)volume
{
    WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_volume != volume;
    }, ^WKBlock {
        self->_volume = volume;
        return nil;
    }, ^BOOL(WKBlock block) {
        self->_player.volume = volume;
        return YES;
    });
}

- (Float64)volume
{
    __block Float64 ret = 1.0f;
    WKLockEXE00(self->_lock, ^{
        ret = self->_volume;
    });
    return ret;
}

- (WKAudioDescriptor *)descriptor
{
    __block WKAudioDescriptor *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = self->_descriptor;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKRenderableStateNone;
    }, ^WKBlock {
        self->_player = [[WKAudioPlayer alloc] init];
        self->_player.delegate = self;
        self->_player.rate = self->_rate;
        self->_player.pitch = self->_pitch;
        self->_player.volume = self->_volume;
        return [self setState:WKRenderableStatePaused];
    }, nil);
}

- (BOOL)close
{
    return WKLockEXE11(self->_lock, ^WKBlock {
        self->_flags.currentFrameCopiedFrames = 0;
        self->_flags.bufferCopiedFrames = 0;
        self->_flags.renderTime = kCMTimeZero;
        self->_flags.renderDuration = kCMTimeZero;
        self->_capacity = WKCapacityCreate();
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        return [self setState:WKRenderableStateNone];
    }, ^BOOL(WKBlock block) {
        [self->_player pause];
        self->_player = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKRenderableStateRendering || self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock {
        return [self setState:WKRenderableStatePaused];
    }, ^BOOL(WKBlock block) {
        [self->_player pause];
        block();
        return YES;
    });
}

- (BOOL)resume
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKRenderableStatePaused || self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock {
        return [self setState:WKRenderableStateRendering];
    }, ^BOOL(WKBlock block) {
        [self->_player play];
        block();
        return YES;
    });
}

- (BOOL)flush
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKRenderableStatePaused || self->_flags.state == WKRenderableStateRendering || self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock {
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.currentFrameCopiedFrames = 0;
        self->_flags.bufferCopiedFrames = 0;
        self->_flags.renderTime = kCMTimeZero;
        self->_flags.renderDuration = kCMTimeZero;
        return ^{};
    }, ^BOOL(WKBlock block) {
        [self->_player flush];
        block();
        return YES;
    });
}

- (BOOL)finish
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKRenderableStateRendering || self->_flags.state == WKRenderableStatePaused;
    }, ^WKBlock {
        return [self setState:WKRenderableStateFinished];
    }, ^BOOL(WKBlock block) {
        [self->_player pause];
        block();
        return YES;
    });
}


#pragma mark - WKAudioPlayerDelegate

- (void)audioPlayer:(WKAudioPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data numberOfFrames:(UInt32)numberOfFrames
{
    [self->_lock lock];
    self->_flags.bufferCopiedFrames = 0;
    self->_flags.renderTime = kCMTimeZero;
    self->_flags.renderDuration = kCMTimeZero;
    if (self->_flags.state != WKRenderableStateRendering) {
        [self->_lock unlock];
        return;
    }
    UInt32 bufferLeftFrames = numberOfFrames;
    while (YES) {
        if (bufferLeftFrames <= 0) {
            [self->_lock unlock];
            break;
        }
        if (!self->_currentFrame) {
            [self->_lock unlock];
            WKAudioFrame *frame = [self.delegate renderable:self fetchFrame:nil];
            if (!frame) {
                break;
            }
            [self->_lock lock];
            self->_currentFrame = frame;
        }
        WKAudioDescriptor *descriptor = self->_currentFrame.descriptor;
        NSAssert(descriptor.format == AV_SAMPLE_FMT_FLTP, @"Invaild audio frame format.");
        UInt32 currentFrameLeftFrames = self->_currentFrame.numberOfSamples - self->_flags.currentFrameCopiedFrames;
        UInt32 framesToCopy = MIN(bufferLeftFrames, currentFrameLeftFrames);
        UInt32 sizeToCopy = framesToCopy * (UInt32)sizeof(float);
        UInt32 bufferOffset = self->_flags.bufferCopiedFrames * (UInt32)sizeof(float);
        UInt32 currentFrameOffset = self->_flags.currentFrameCopiedFrames * (UInt32)sizeof(float);
        for (int i = 0; i < data->mNumberBuffers && i < descriptor.numberOfChannels; i++) {
            memcpy(data->mBuffers[i].mData + bufferOffset, self->_currentFrame.data[i] + currentFrameOffset, sizeToCopy);
        }
        if (self->_flags.bufferCopiedFrames == 0) {
            CMTime duration = CMTimeMultiplyByRatio(self->_currentFrame.duration, self->_flags.currentFrameCopiedFrames, self->_currentFrame.numberOfSamples);
            self->_flags.renderTime = CMTimeAdd(self->_currentFrame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self->_currentFrame.duration, framesToCopy, self->_currentFrame.numberOfSamples);
        self->_flags.renderDuration = CMTimeAdd(self->_flags.renderDuration, duration);
        self->_flags.bufferCopiedFrames += framesToCopy;
        self->_flags.currentFrameCopiedFrames += framesToCopy;
        if (self->_currentFrame.numberOfSamples <= self->_flags.currentFrameCopiedFrames) {
            [self->_currentFrame unlock];
            self->_currentFrame = nil;
            self->_flags.currentFrameCopiedFrames = 0;
        }
        bufferLeftFrames -= framesToCopy;
    }
    UInt32 framesCopied = numberOfFrames - bufferLeftFrames;
    UInt32 sizeCopied = framesCopied * (UInt32)sizeof(float);
    for (int i = 0; i < data->mNumberBuffers; i++) {
        UInt32 sizeLeft = data->mBuffers[i].mDataByteSize - sizeCopied;
        if (sizeLeft > 0) {
            memset(data->mBuffers[i].mData + sizeCopied, 0, sizeLeft);
        }
    }
}

- (void)audioPlayer:(WKAudioPlayer *)player didRender:(const AudioTimeStamp *)timestamp
{
    [self->_lock lock];
    CMTime renderTime = self->_flags.renderTime;
    CMTime renderDuration = CMTimeMultiplyByFloat64(self->_flags.renderDuration, self->_rate);
    CMTime frameDuration = !self->_currentFrame ? kCMTimeZero : CMTimeMultiplyByRatio(self->_currentFrame.duration, self->_currentFrame.numberOfSamples - self->_flags.currentFrameCopiedFrames, self->_currentFrame.numberOfSamples);
    WKBlock clockBlock = ^{};
    if (self->_flags.state == WKRenderableStateRendering) {
        if (self->_flags.bufferCopiedFrames) {
            clockBlock = ^{
                [self->_clock setAudioTime:renderTime running:YES];
            };
        } else {
            clockBlock = ^{
                [self->_clock setAudioTime:kCMTimeInvalid running:NO];
            };
        }
    }
    WKCapacity capacity = WKCapacityCreate();
    capacity.duration = CMTimeAdd(renderDuration, frameDuration);
    WKBlock capacityBlock = ^{};
    if (!WKCapacityIsEqual(self->_capacity, capacity)) {
        self->_capacity = capacity;
        capacityBlock = ^{
            [self.delegate renderable:self didChangeCapacity:capacity];
        };
    }
    [self->_lock unlock];
    clockBlock();
    capacityBlock();
}

@end
