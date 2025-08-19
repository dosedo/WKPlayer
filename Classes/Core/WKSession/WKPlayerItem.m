//
//  WKPlayerItem.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPlayerItem.h"
#import "WKPlayerItem+Internal.h"
#import "WKAudioProcessor.h"
#import "WKVideoProcessor.h"
#import "WKObjectQueue.h"
#import "WKFrameOutput.h"
#import "WKMacro.h"
#import "WKLock.h"

@interface WKPlayerItem () <WKFrameOutputDelegate>

{
    struct {
        NSError *error;
        WKPlayerItemState state;
        BOOL audioFinished;
        BOOL videoFinished;
    } _flags;
    BOOL _capacityFlags[8];
    WKCapacity _capacities[8];
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) WKObjectQueue *audioQueue;
@property (nonatomic, strong, readonly) WKObjectQueue *videoQueue;
@property (nonatomic, strong, readonly) WKFrameOutput *frameOutput;
@property (nonatomic, strong, readonly) WKAudioProcessor *audioProcessor;
@property (nonatomic, strong, readonly) WKVideoProcessor *videoProcessor;

@end

@implementation WKPlayerItem

- (instancetype)initWithAsset:(WKAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_frameOutput = [[WKFrameOutput alloc] initWithAsset:asset];
        self->_frameOutput.delegate = self;
        self->_audioQueue = [[WKObjectQueue alloc] init];
        self->_videoQueue = [[WKObjectQueue alloc] init];
        for (int i = 0; i < 8; i++) {
            self->_capacityFlags[i] = NO;
            self->_capacities[i] = WKCapacityCreate();
        }
    }
    return self;
}

- (void)dealloc
{
    WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != WKPlayerItemStateClosed;
    }, ^WKBlock {
        [self setState:WKPlayerItemStateClosed];
        [self->_frameOutput close];
        WKLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_videoProcessor close];
            [self->_audioQueue destroy];
            [self->_videoQueue destroy];
        });
        return nil;
    });
}

#pragma mark - Mapping

WKGet0Map(CMTime, duration, self->_frameOutput)
WKGet0Map(NSDictionary *, metadata, self->_frameOutput)
WKGet0Map(NSArray<WKTrack *> *, tracks, self->_frameOutput)
WKGet0Map(WKDemuxerOptions *, demuxerOptions, self->_frameOutput)
WKGet0Map(WKDecoderOptions *, decoderOptions, self->_frameOutput)
WKSet1Map(void, setDemuxerOptions, WKDemuxerOptions *, self->_frameOutput)
WKSet1Map(void, setDecoderOptions, WKDecoderOptions *, self->_frameOutput)

#pragma mark - Setter & Getter

- (WKBlock)setState:(WKPlayerItemState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate playerItem:self didChangeState:state];
    };
}

- (WKPlayerItemState)state
{
    __block WKPlayerItemState ret = WKPlayerItemStateNone;
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

- (WKCapacity)capacityWithType:(WKMediaType)type
{
    __block WKCapacity ret;
    WKLockEXE00(self->_lock, ^{
         ret = self->_capacities[type];
    });
    return ret;
}

- (BOOL)isAvailable:(WKMediaType)type
{
    __block BOOL ret = NO;
    WKLockEXE00(self->_lock, ^{
        if (type == WKMediaTypeAudio) {
            ret = self->_audioSelection.tracks.count > 0;
        } else if (type == WKMediaTypeVideo) {
            ret = self->_videoSelection.tracks.count > 0;
        }
    });
    return ret;
}

- (BOOL)isFinished:(WKMediaType)type
{
    __block BOOL ret = NO;
    WKLockEXE00(self->_lock, ^{
        if (type == WKMediaTypeAudio) {
            ret = self->_flags.audioFinished;
        } else if (type == WKMediaTypeVideo) {
            ret = self->_flags.videoFinished;
        }
    });
    return ret;
}

- (void)setAudioSelection:(WKTrackSelection *)audioSelection action:(WKTrackSelectionAction)action
{
    WKLockEXE10(self->_lock, ^WKBlock {
        self->_audioSelection = [audioSelection copy];
        if (action & WKTrackSelectionActionTracks) {
            NSMutableArray *m = [NSMutableArray array];
            [m addObjectsFromArray:self->_audioSelection.tracks];
            [m addObjectsFromArray:self->_videoSelection.tracks];
            [self->_frameOutput selectTracks:[m copy]];
        }
        if (action > 0) {
            [self->_audioProcessor setSelection:self->_audioSelection action:action];
        }
        return nil;
    });
}

- (void)setVideoSelection:(WKTrackSelection *)videoSelection action:(WKTrackSelectionAction)action
{
    WKLockEXE10(self->_lock, ^WKBlock {
        self->_videoSelection = [videoSelection copy];
        if (action & WKTrackSelectionActionTracks) {
            NSMutableArray *m = [NSMutableArray array];
            [m addObjectsFromArray:self->_audioSelection.tracks];
            [m addObjectsFromArray:self->_videoSelection.tracks];
            [self->_frameOutput selectTracks:[m copy]];
        }
        if (action > 0) {
            [self->_videoProcessor setSelection:self->_videoSelection action:action];
        }
        return nil;
    });
}

#pragma mark - Control

- (BOOL)open
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKPlayerItemStateNone;
    }, ^WKBlock {
        return [self setState:WKPlayerItemStateOpening];
    }, ^BOOL(WKBlock block) {
        block();
        return [self->_frameOutput open];
    });
}

- (BOOL)start
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKPlayerItemStateOpened;
    }, ^WKBlock {
        return [self setState:WKPlayerItemStateReading];;
    }, ^BOOL(WKBlock block) {
        block();
        return [self->_frameOutput start];
    });
}

- (BOOL)close
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state != WKPlayerItemStateClosed;
    }, ^WKBlock {
        return [self setState:WKPlayerItemStateClosed];
    }, ^BOOL(WKBlock block) {
        block();
        [self->_frameOutput close];
        WKLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_videoProcessor close];
            [self->_audioQueue destroy];
            [self->_videoQueue destroy];
        });
        return YES;
    });
}

- (BOOL)seekable
{
    return self->_frameOutput.seekable;
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
    WKWeakify(self)
    return ![self->_frameOutput seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        WKStrongify(self)
        if (!error) {
            WKLockEXE10(self->_lock, ^WKBlock {
                [self->_audioProcessor flush];
                [self->_videoProcessor flush];
                [self->_audioQueue flush];
                [self->_videoQueue flush];
                WKBlock b1 = [self setFrameQueueCapacity:WKMediaTypeAudio];
                WKBlock b2 = [self setFrameQueueCapacity:WKMediaTypeVideo];
                return ^{b1(); b2();};
            });
        }
        if (result) {
            result(time, error);
        }
    }];
}

- (WKFrame *)copyAudioFrame:(WKTimeReader)timeReader
{
    __block WKFrame *ret = nil;
    WKLockEXE10(self->_lock, ^WKBlock {
        uint64_t discarded = 0;
        BOOL success = [self->_audioQueue getObjectAsync:&ret timeReader:timeReader discarded:&discarded];
        if (success || discarded) {
            return [self setFrameQueueCapacity:WKMediaTypeAudio];
        };
        return nil;
    });
    return ret;
}

- (WKFrame *)copyVideoFrame:(WKTimeReader)timeReader
{
    __block WKFrame *ret = nil;
    WKLockEXE10(self->_lock, ^WKBlock {
        uint64_t discarded = 0;
        BOOL success = [self->_videoQueue getObjectAsync:&ret timeReader:timeReader discarded:&discarded];
        if (success || discarded) {
            return [self setFrameQueueCapacity:WKMediaTypeVideo];
        };
        return nil;
    });
    return ret;
}

#pragma mark - WKFrameOutputDelegate

- (void)frameOutput:(WKFrameOutput *)frameOutput didChangeState:(WKFrameOutputState)state
{
    switch (state) {
        case WKFrameOutputStateOpened: {
            WKLockEXE10(self->_lock, ^WKBlock {
                NSMutableArray *video = [NSMutableArray array];
                NSMutableArray *audio = [NSMutableArray array];
                for (WKTrack *obj in frameOutput.selectedTracks) {
                    if (obj.type == WKMediaTypeAudio) {
                        [audio addObject:obj];
                    } else if (obj.type == WKMediaTypeVideo) {
                        [video addObject:obj];
                    }
                }
                if (audio.count > 0) {
                    WKTrackSelectionAction action = 0;
                    action |= WKTrackSelectionActionTracks;
                    action |= WKTrackSelectionActionWeights;
                    self->_audioSelection = [[WKTrackSelection alloc] init];
                    self->_audioSelection.tracks = @[audio.firstObject];
                    self->_audioSelection.weights = @[@(1.0)];
                    self->_audioProcessor = [[self->_processorOptions.audioClass alloc] init];
                    [self->_audioProcessor setSelection:self->_audioSelection action:action];
                }
                if (video.count > 0) {
                    WKTrackSelectionAction action = 0;
                    action |= WKTrackSelectionActionTracks;
                    action |= WKTrackSelectionActionWeights;
                    self->_videoSelection = [[WKTrackSelection alloc] init];
                    self->_videoSelection.tracks = @[video.firstObject];
                    self->_videoSelection.weights = @[@(1.0)];
                    self->_videoProcessor = [[self->_processorOptions.videoClass alloc] init];
                    [self->_videoProcessor setSelection:self->_videoSelection action:action];
                }
                return [self setState:WKPlayerItemStateOpened];
            });
        }
            break;
        case WKFrameOutputStateReading: {
            WKLockEXE10(self->_lock, ^WKBlock {
                return [self setState:WKPlayerItemStateReading];
            });
        }
            break;
        case WKFrameOutputStateSeeking: {
            WKLockEXE10(self->_lock, ^WKBlock {
                return [self setState:WKPlayerItemStateSeeking];
            });
        }
            break;
        case WKFrameOutputStateFinished: {
            WKLockEXE10(self->_lock, ^WKBlock {
                WKFrame *aobj = [self->_audioProcessor finish];
                if (aobj) {
                    [self->_audioQueue putObjectSync:aobj];
                    [aobj unlock];
                }
                WKFrame *vobj = [self->_videoProcessor finish];
                if (vobj) {
                    [self->_videoQueue putObjectSync:vobj];
                    [vobj unlock];
                }
                WKBlock b1 = [self setFrameQueueCapacity:WKMediaTypeAudio];
                WKBlock b2 = [self setFrameQueueCapacity:WKMediaTypeVideo];
                WKBlock b3 = [self setFinishedIfNeeded];
                return ^{b1(); b2(); b3();};
            });
        }
            break;
        case WKFrameOutputStateFailed: {
            WKLockEXE10(self->_lock, ^WKBlock {
                self->_flags.error = [frameOutput.error copy];
                return [self setState:WKPlayerItemStateFailed];
            });
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(WKFrameOutput *)frameOutput didChangeCapacity:(WKCapacity)capacity type:(WKMediaType)type
{
    WKLockEXE10(self->_lock, ^WKBlock {
        WKCapacity additional = [self frameQueueCapacity:type];
        return [self setCapacity:WKCapacityAdd(capacity, additional) type:type];
    });
}

- (void)frameOutput:(WKFrameOutput *)frameOutput didOutputFrames:(NSArray<__kindof WKFrame *> *)frames needsDrop:(BOOL (^)(void))needsDrop
{
    WKLockEXE10(self->_lock, ^WKBlock {
        if (needsDrop && needsDrop()) {
            return nil;
        }
        BOOL hasAudio = NO, hasVideo = NO;
        NSArray<__kindof WKFrame *> *objs = frames;
        for (NSInteger i = 0; i < objs.count; i++) {
            __kindof WKFrame *obj = objs[i];
            [obj lock];
            WKMediaType type = obj.track.type;
            if (type == WKMediaTypeAudio) {
                obj = [self->_audioProcessor putFrame:obj];
                if (obj) {
                    hasAudio = YES;
                    [self->_audioQueue putObjectSync:obj];
                }
            } else if (type == WKMediaTypeVideo) {
                obj = [self->_videoProcessor putFrame:obj];
                if (obj) {
                    hasVideo = YES;
                    [self->_videoQueue putObjectSync:obj];
                }
            }
            [obj unlock];
        }
        WKBlock b1 = ^{}, b2 = ^{};
        if (hasAudio) {
            b1 = [self setFrameQueueCapacity:WKMediaTypeAudio];
        }
        if (hasVideo) {
            b2 = [self setFrameQueueCapacity:WKMediaTypeVideo];
        }
        return ^{b1(); b2();};
    });
}

#pragma mark - Capacity

- (WKBlock)setFrameQueueCapacity:(WKMediaType)type
{
    BOOL paused = NO;
    if (type == WKMediaTypeAudio) {
        paused = _audioQueue.capacity.count > 5;
    } else if (type == WKMediaTypeVideo) {
        paused = _videoQueue.capacity.count > 3;
    }
    WKBlock b1 = ^{
        if (paused) {
            [self->_frameOutput pause:type];
        } else {
            [self->_frameOutput resume:type];
        }
    };
    WKCapacity capacity = [self frameQueueCapacity:type];
    WKCapacity additional = [self->_frameOutput capacityWithType:type];
    WKBlock b2 = [self setCapacity:WKCapacityAdd(capacity, additional) type:type];
    return ^{b1(); b2();};
}

- (WKCapacity)frameQueueCapacity:(WKMediaType)type
{
    WKCapacity capacity = WKCapacityCreate();
    if (type == WKMediaTypeAudio) {
        capacity = self->_audioQueue.capacity;
        if (self->_audioProcessor) {
            capacity = WKCapacityAdd(capacity, self->_audioProcessor.capacity);
        }
    } else if (type == WKMediaTypeVideo) {
        capacity = self->_videoQueue.capacity;
        if (self->_videoProcessor) {
            capacity = WKCapacityAdd(capacity, self->_videoProcessor.capacity);
        }
    }
    return capacity;
}

- (WKBlock)setCapacity:(WKCapacity)capacity type:(WKMediaType)type
{
    WKCapacity obj = self->_capacities[type];
    if (WKCapacityIsEqual(obj, capacity)) {
        return ^{};
    }
    self->_capacityFlags[type] = YES;
    self->_capacities[type] = capacity;
    WKBlock b1 = ^{
        [self->_delegate playerItem:self didChangeCapacity:capacity type:type];
    };
    WKBlock b2 = [self setFinishedIfNeeded];
    return ^{b1(); b2();};
}

- (WKBlock)setFinishedIfNeeded
{
    BOOL nomore = self->_frameOutput.state == WKFrameOutputStateFinished;
    WKCapacity ac = self->_capacities[WKMediaTypeAudio];
    WKCapacity vc = self->_capacities[WKMediaTypeVideo];
    self->_flags.audioFinished = nomore && (!self->_capacityFlags[WKMediaTypeAudio] || WKCapacityIsEmpty(ac));
    self->_flags.videoFinished = nomore && (!self->_capacityFlags[WKMediaTypeVideo] || WKCapacityIsEmpty(vc));
    if (self->_flags.audioFinished && self->_flags.videoFinished) {
        return [self setState:WKPlayerItemStateFinished];
    }
    return ^{};
}

@end
