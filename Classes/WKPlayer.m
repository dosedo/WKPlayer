//
//  WKPlayer.m
//  WKPlayer
//
//  Created by Kidsmiless on 08/01/2025.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "WKPlayerItem+Internal.h"
#import "WKRenderer+Internal.h"
#import "WKActivity.h"
#import "WKMacro.h"
#import "WKLock.h"

#if WKPLATFORM_TARGET_OS_IPHONE_OR_TV
#import <UIKit/UIKit.h>
#endif

NSString * const WKPlayerTimeInfoUserInfoKey   = @"WKPlayerTimeInfoUserInfoKey";
NSString * const WKPlayerStateInfoUserInfoKey  = @"WKPlayerStateInfoUserInfoKey";
NSString * const WKPlayerInfoActionUserInfoKey = @"WKPlayerInfoActionUserInfoKey";
NSNotificationName const WKPlayerDidChangeInfosNotification = @"WKPlayerDidChangeInfosNotification";

@interface WKPlayer () <WKClockDelegate, WKRenderableDelegate, WKPlayerItemDelegate>

{
    struct {
        BOOL playing;
        BOOL audioFinished;
        BOOL videoFinished;
        BOOL audioAvailable;
        BOOL videoAvailable;
        NSError *error;
        NSUInteger seekingIndex;
        WKTimeInfo timeInfo;
        WKStateInfo stateInfo;
        WKInfoAction additionalAction;
        NSTimeInterval lastNotificationTime;
    } _flags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) WKClock *clock;
@property (nonatomic, strong, readonly) WKPlayerItem *currentItem;
@property (nonatomic, strong, readonly) WKAudioRenderer *audioRenderer;
@property (nonatomic, strong, readonly) WKVideoRenderer *videoRenderer;

@end

@implementation WKPlayer

@synthesize rate = _rate;
@synthesize clock = _clock;
@synthesize currentItem = _currentItem;
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;

- (instancetype)init
{
    if (self = [super init]) {
        [self stop];
        self->_options = [WKOptions sharedOptions].copy;
        self->_rate = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_clock = [[WKClock alloc] init];
        self->_clock.delegate = self;
        self->_audioRenderer = [[WKAudioRenderer alloc] initWithClock:self->_clock];
        self->_audioRenderer.delegate = self;
        self->_videoRenderer = [[WKVideoRenderer alloc] initWithClock:self->_clock];
        self->_videoRenderer.delegate = self;
        self->_actionMask = WKInfoActionNone;
        self->_minimumTimeInfoInterval = 1.0;
        self->_notificationQueue = [NSOperationQueue mainQueue];
#if WKPLATFORM_TARGET_OS_IPHONE_OR_TV
        self->_pausesWhenInterrupted = YES;
        self->_pausesWhenEnteredBackground = NO;
        self->_pausesWhenEnteredBackgroundIfNoAudioTrack = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionHandler:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundHandler:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
#if WKPLATFORM_TARGET_OS_IPHONE_OR_TV
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
    [WKActivity removeTarget:self];
    [self->_currentItem close];
    [self->_clock close];
    [self->_audioRenderer close];
    [self->_videoRenderer close];
}

#pragma mark - Info

- (WKBlock)setPlayerState:(WKPlayerState)state action:(WKInfoAction *)action
{
    if (self->_flags.stateInfo.player == state) {
        return ^{};
    }
    *action |= WKInfoActionStatePlayer;
    self->_flags.stateInfo.player = state;
    return ^{
        if (state == WKPlayerStateReady) {
            if (self->_readyHandler) {
                self->_readyHandler(self);
            }
            if (self->_wantsToPlay) {
                [self play];
            }
        }
    };
}

- (WKBlock)setPlaybackState:(WKInfoAction *)action
{
    WKPlaybackState state = 0;
    if (self->_flags.playing) {
        state |= WKPlaybackStatePlaying;
    }
    if (self->_flags.seekingIndex > 0) {
        state |= WKPlaybackStateSeeking;
    }
    if (self->_flags.stateInfo.player == WKPlayerStateReady &&
        (!self->_flags.audioAvailable || self->_flags.audioFinished) &&
        (!self->_flags.videoAvailable || self->_flags.videoFinished)) {
        state |= WKPlaybackStateFinished;
    }
    if (self->_flags.stateInfo.playback == state) {
        return ^{};
    }
    *action |= WKInfoActionStatePlayback;
    self->_flags.stateInfo.playback = state;
    WKBlock b1 = ^{};
    if (state & WKPlaybackStateFinished) {
        [self setCachedDuration:kCMTimeZero action:action];
        [self setPlaybackTime:self->_flags.timeInfo.duration action:action];
    }
    if (state & WKPlaybackStateFinished) {
        b1 = ^{
            [self->_clock pause];
            [self->_audioRenderer finish];
            [self->_videoRenderer finish];
        };
    } else if (state & WKPlaybackStatePlaying) {
        b1 = ^{
            [self->_clock resume];
            [self->_audioRenderer resume];
            [self->_videoRenderer resume];
        };
    } else {
        b1 = ^{
            [self->_clock pause];
            [self->_audioRenderer pause];
            [self->_videoRenderer pause];
        };
    }
    return b1;
}

- (WKBlock)setLoadingState:(WKLoadingState)state action:(WKInfoAction *)action
{
    if (self->_flags.stateInfo.loading == state) {
        return ^{};
    }
    *action |= WKInfoActionStateLoading;
    self->_flags.stateInfo.loading = state;
    return ^{};
}

- (void)setPlaybackTime:(CMTime)time action:(WKInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.playback, time) == 0) {
        return;
    }
    *action |= WKInfoActionTimePlayback;
    self->_flags.timeInfo.playback = time;
}

- (void)setDuration:(CMTime)duration action:(WKInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.duration, duration) == 0) {
        return;
    }
    *action |= WKInfoActionTimeDuration;
    self->_flags.timeInfo.duration = duration;
}

- (void)setCachedDuration:(CMTime)duration action:(WKInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.cached, duration) == 0) {
        return;
    }
    *action |= WKInfoActionTimeCached;
    self->_flags.timeInfo.cached = duration;
}

#pragma mark - Setter & Getter

- (NSError *)error
{
    NSError *error;
    [self stateInfo:nil timeInfo:nil error:&error];
    return error;
}

- (WKTimeInfo)timeInfo
{
    WKTimeInfo timeInfo;
    [self stateInfo:nil timeInfo:&timeInfo error:nil];
    return timeInfo;
}

- (WKStateInfo)sstateInfo
{
    WKStateInfo stateInfo;
    [self stateInfo:&stateInfo timeInfo:nil error:nil];
    return stateInfo;
}

- (BOOL)stateInfo:(WKStateInfo *)stateInfo timeInfo:(WKTimeInfo *)timeInfo error:(NSError **)error
{
    __block NSError *err = nil;
    WKLockEXE00(self->_lock, ^{
        if (stateInfo) {
            *stateInfo = self->_flags.stateInfo;
        }
        if (timeInfo) {
            *timeInfo = self->_flags.timeInfo;
        }
        err = self->_flags.error;
    });
    if (error) {
        *error = err;
    }
    return YES;
}

- (WKPlayerItem *)currentItem
{
    __block WKPlayerItem *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = self->_currentItem;
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
        self->_clock.rate = rate;
        self->_audioRenderer.rate = rate;
        self->_videoRenderer.rate = rate;
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

- (WKClock *)clock
{
    __block WKClock *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = self->_clock;
    });
    return ret;
}

- (WKAudioRenderer *)audioRenderer
{
    __block WKAudioRenderer *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = self->_audioRenderer;
    });
    return ret;
}

- (WKVideoRenderer *)videoRenderer
{
    __block WKVideoRenderer *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = self->_videoRenderer;
    });
    return ret;
}

- (void)setPlayView:(UIView *)playView{
    _playView = playView;
    
    self.videoRenderer.view = playView;
}

#pragma mark - Item

- (BOOL)replaceWithURL:(NSURL *)URL
{
    return [self replaceWithAsset:URL ? [[WKURLAsset alloc] initWithURL:URL] : nil];
}

- (BOOL)replaceWithAsset:(WKAsset *)asset
{
    return [self replaceWithPlayerItem:asset ? [[WKPlayerItem alloc] initWithAsset:asset] : nil];
}

- (BOOL)replaceWithPlayerItem:(WKPlayerItem *)item
{
    [self stop];
    if (!item) {
        return NO;
    }
    return WKLockEXE11(self->_lock, ^WKBlock {
        self->_currentItem = item;
        self->_currentItem.delegate = self;
        self->_currentItem.demuxerOptions = self->_options.demuxer;
        self->_currentItem.decoderOptions = self->_options.decoder;
        self->_currentItem.processorOptions = self->_options.processor;
        return nil;
    }, ^BOOL(WKBlock block) {
        return [item open];
    });
}

- (BOOL)stop
{
    [WKActivity removeTarget:self];
    return WKLockEXE10(self->_lock, ^WKBlock {
        WKPlayerItem *currentItem = self->_currentItem;
        self->_currentItem = nil;
        self->_flags.error = nil;
        self->_flags.playing = NO;
        self->_flags.seekingIndex = 0;
        self->_flags.audioFinished = NO;
        self->_flags.videoFinished = NO;
        self->_flags.audioAvailable = NO;
        self->_flags.videoAvailable = NO;
        self->_flags.additionalAction = WKInfoActionNone;
        self->_flags.lastNotificationTime = 0.0;
        self->_flags.timeInfo.cached = kCMTimeInvalid;
        self->_flags.timeInfo.playback = kCMTimeInvalid;
        self->_flags.timeInfo.duration = kCMTimeInvalid;
        self->_flags.stateInfo.player = WKPlayerStateNone;
        self->_flags.stateInfo.loading = WKLoadingStateNone;
        self->_flags.stateInfo.playback = WKPlaybackStateNone;
        WKInfoAction action = WKInfoActionNone;
        WKBlock b1 = [self setPlayerState:WKPlayerStateNone action:&action];
        WKBlock b2 = [self setPlaybackState:&action];
        WKBlock b3 = [self setLoadingState:WKLoadingStateNone action:&action];
        WKBlock b4 = [self infoCallback:action];
        return ^{
            [currentItem close];
            [self->_clock close];
            [self->_audioRenderer close];
            [self->_videoRenderer close];
            b1(); b2(); b3(); b4();
        };
    });
}

#pragma mark - Playback

- (BOOL)play
{
    self->_wantsToPlay = YES;
    [WKActivity addTarget:self];
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == WKPlayerStateReady;
    }, ^WKBlock {
        self->_flags.playing = YES;
        WKInfoAction action = WKInfoActionNone;
        WKBlock b1 = [self setPlaybackState:&action];
        WKBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
}

- (BOOL)pause
{
    self->_wantsToPlay = NO;
    [WKActivity removeTarget:self];
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == WKPlayerStateReady;
    }, ^WKBlock {
        self->_flags.playing = NO;
        WKInfoAction action = WKInfoActionNone;
        WKBlock b1 = [self setPlaybackState:&action];
        WKBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
}

-  (BOOL)seekable
{
    WKPlayerItem *currentItem = [self currentItem];
    return [currentItem seekable];
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
    __block NSUInteger seekingCount = 0;
    __block WKPlayerItem *currentItem = nil;
    BOOL ret = WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == WKPlayerStateReady;
    }, ^WKBlock {
        self->_flags.seekingIndex += 1;
        currentItem = self->_currentItem;
        seekingCount = self->_flags.seekingIndex;
        WKInfoAction action = WKInfoActionNone;
        WKBlock b1 = [self setPlaybackState:&action];
        WKBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
    if (!ret) {
        return NO;
    }
    WKWeakify(self)
    return [currentItem seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        WKStrongify(self)
        WKLockCondEXE11(self->_lock, ^BOOL {
            return seekingCount == self->_flags.seekingIndex;
        }, ^WKBlock {
            WKBlock b1 = ^{};
            self->_flags.seekingIndex = 0;
            if (!error) {
                self->_flags.audioFinished = NO;
                self->_flags.videoFinished = NO;
                self->_flags.lastNotificationTime = 0.0;
                b1 = ^{
                    [self->_clock flush];
                    [self->_audioRenderer flush];
                    [self->_videoRenderer flush];
                };
            }
            WKInfoAction action = WKInfoActionNone;
            WKBlock b2 = [self setPlaybackState:&action];
            WKBlock b3 = [self infoCallback:action];
            return ^{b1(); b2(); b3();};
        }, ^BOOL(WKBlock block) {
            block();
            if (result) {
                [self callback:^{
                    result(time, error);
                }];
            }
            return YES;
        });
    }];
}

#pragma mark - WKClockDelegate

- (void)clock:(WKClock *)clock didChcnageCurrentTime:(CMTime)currentTime
{
    WKLockEXE10(self->_lock, ^WKBlock {
        WKInfoAction action = WKInfoActionNone;
        [self setPlaybackTime:currentTime action:&action];
        return [self infoCallback:action];
    });
}

#pragma mark - WKRenderableDelegate

- (void)renderable:(id<WKRenderable>)renderable didChangeState:(WKRenderableState)state
{
    NSAssert(state != WKRenderableStateFailed, @"Invaild renderer, %@", renderable);
}

- (void)renderable:(id<WKRenderable>)renderable didChangeCapacity:(WKCapacity)capacity
{
    if (WKCapacityIsEmpty(capacity)) {
        WKLockEXE10(self->_lock, ^WKBlock {
            if (WKCapacityIsEmpty(self->_audioRenderer.capacity) && [self->_currentItem isFinished:WKMediaTypeAudio]) {
                self->_flags.audioFinished = YES;
            }
            if (WKCapacityIsEmpty(self->_videoRenderer.capacity) && [self->_currentItem isFinished:WKMediaTypeVideo]) {
                self->_flags.videoFinished = YES;
            }
            WKInfoAction action = WKInfoActionNone;
            WKBlock b1 = [self setPlaybackState:&action];
            WKBlock b2 = [self infoCallback:action];
            return ^{b1(); b2();};
        });
    }
}

- (__kindof WKFrame *)renderable:(id<WKRenderable>)renderable fetchFrame:(WKTimeReader)timeReader
{
    WKPlayerItem *currentItem = self.currentItem;
    if (renderable == self->_audioRenderer) {
        return [currentItem copyAudioFrame:timeReader];
    } else if (renderable == self->_videoRenderer) {
        return [currentItem copyVideoFrame:timeReader];
    }
    return nil;
}

#pragma mark - WKPlayerItemDelegate

- (void)playerItem:(WKPlayerItem *)playerItem didChangeState:(WKPlayerItemState)state
{
    WKLockEXE10(self->_lock, ^WKBlock {
        WKInfoAction action = WKInfoActionNone;
        WKBlock b1 = ^{}, b2 = ^{}, b3 = ^{}, b4 = ^{};
        switch (state) {
            case WKPlayerItemStateOpening: {
                b1 = [self setPlayerState:WKPlayerStatePreparing action:&action];
            }
                break;
            case WKPlayerItemStateOpened: {
                CMTime duration = self->_currentItem.duration;
                [self setDuration:duration action:&action];
                [self setPlaybackTime:kCMTimeZero action:&action];
                [self setCachedDuration:kCMTimeZero action:&action];
                b1 = ^{
                    [self->_clock open];
                    if ([playerItem isAvailable:WKMediaTypeAudio]) {
                        self->_flags.audioAvailable = YES;
                        [self->_audioRenderer open];
                    }
                    if ([playerItem isAvailable:WKMediaTypeVideo]) {
                        self->_flags.videoAvailable = YES;
                        [self->_videoRenderer open];
                    }
                };
                b2 = [self setPlayerState:WKPlayerStateReady action:&action];
                b3 = [self setLoadingState:WKLoadingStateStalled action:&action];
                b4 = ^{
                    [playerItem start];
                };
            }
                break;
            case WKPlayerItemStateReading: {
                b1 = [self setPlaybackState:&action];
            }
                break;
            case WKPlayerItemStateFinished: {
                b1 = [self setLoadingState:WKLoadingStateFinished action:&action];
                if (WKCapacityIsEmpty(self->_audioRenderer.capacity)) {
                    self->_flags.audioFinished = YES;
                }
                if (WKCapacityIsEmpty(self->_videoRenderer.capacity)) {
                    self->_flags.videoFinished = YES;
                }
                b2 = [self setPlaybackState:&action];
            }
                break;
            case WKPlayerItemStateFailed: {
                self->_flags.error = [playerItem.error copy];
                b1 = [self setPlayerState:WKPlayerStateFailed action:&action];
            }
                break;
            default:
                break;
        }
        WKBlock b5 = [self infoCallback:action];
        return ^{b1(); b2(); b3(); b4(); b5();};
    });
}

- (void)playerItem:(WKPlayerItem *)playerItem didChangeCapacity:(WKCapacity)capacity type:(WKMediaType)type
{
    BOOL should = NO;
    if (type == WKMediaTypeAudio &&
        ![playerItem isFinished:WKMediaTypeAudio]) {
        should = YES;
    } else if (type == WKMediaTypeVideo &&
               ![playerItem isFinished:WKMediaTypeVideo] &&
               (![playerItem isAvailable:WKMediaTypeAudio] || [playerItem isFinished:WKMediaTypeAudio])) {
        should = YES;
    }
    if (should) {
        WKLockEXE10(self->_lock, ^WKBlock {
            WKInfoAction action = WKInfoActionNone;
            CMTime duration = capacity.duration;
            WKLoadingState loadingState = (WKCapacityIsEmpty(capacity) || self->_flags.stateInfo.loading == WKLoadingStateFinished) ? WKLoadingStateStalled : WKLoadingStatePlaybale;
            [self setCachedDuration:duration action:&action];
            WKBlock b1 = [self setLoadingState:loadingState action:&action];
            WKBlock b2 = [self infoCallback:action];
            return ^{b1(); b2();};
        });
    }
}

#pragma mark - Notification

- (WKBlock)infoCallback:(WKInfoAction)action
{
    action &= ~self->_actionMask;
    BOOL needed = NO;
    if (action & WKInfoActionState) {
        needed = YES;
    } else if (action & WKInfoActionTime) {
        NSTimeInterval currentTime = CACurrentMediaTime();
        NSTimeInterval interval = currentTime - self->_flags.lastNotificationTime;
        if (self->_flags.playing == NO ||
            interval >= self->_minimumTimeInfoInterval) {
            needed = YES;
            self->_flags.lastNotificationTime = currentTime;
        } else {
            self->_flags.additionalAction |= (action & WKInfoActionTime);
        }
    }
    if (!needed) {
        return ^{};
    }
    action |= self->_flags.additionalAction;
    self->_flags.additionalAction = WKInfoActionNone;
    NSValue *timeInfo = [NSValue value:&self->_flags.timeInfo withObjCType:@encode(WKTimeInfo)];
    NSValue *stateInfo = [NSValue value:&self->_flags.stateInfo withObjCType:@encode(WKStateInfo)];
    id userInfo = @{WKPlayerTimeInfoUserInfoKey : timeInfo,
                    WKPlayerStateInfoUserInfoKey : stateInfo,
                    WKPlayerInfoActionUserInfoKey : @(action)};
    return ^{
        [self callback:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:WKPlayerDidChangeInfosNotification
                                                                object:self
                                                              userInfo:userInfo];
        }];
    };
}

- (void)callback:(void (^)(void))block
{
    if (!block) {
        return;
    }
    if (self->_notificationQueue) {
        [self->_notificationQueue addOperation:[NSBlockOperation blockOperationWithBlock:block]];
    } else {
        block();
    }
}

+ (WKTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo
{
    WKTimeInfo info;
    NSValue *value = userInfo[WKPlayerTimeInfoUserInfoKey];
    [value getValue:&info];
    return info;
}

+ (WKStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo
{
    WKStateInfo info;
    NSValue *value = userInfo[WKPlayerStateInfoUserInfoKey];
    [value getValue:&info];
    return info;
}

+ (WKInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo
{
    return [userInfo[WKPlayerInfoActionUserInfoKey] unsignedIntegerValue];
}

#if WKPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)interruptionHandler:(NSNotification *)notification
{
    if (self->_pausesWhenInterrupted == YES) {
        AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        if (type == AVAudioSessionInterruptionTypeBegan) {
            [self pause];
        }
    }
}

- (void)enterBackgroundHandler:(NSNotification *)notification
{
    if (self->_pausesWhenEnteredBackground) {
        [self pause];
    } else if (self->_pausesWhenEnteredBackgroundIfNoAudioTrack) {
        WKLockCondEXE11(self->_lock, ^BOOL {
            return self->_flags.audioAvailable == NO && self->_flags.videoAvailable == YES;
        }, nil, ^BOOL(WKBlock block) {
            return [self pause];
        });
    }
}
#endif

@end
