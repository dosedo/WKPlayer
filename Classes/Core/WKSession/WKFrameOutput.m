//
//  WKFrameOutput.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKFrameOutput.h"
#import "WKAudioDecoder.h"
#import "WKVideoDecoder.h"
#import "WKPacketOutput.h"
#import "WKDecodeLoop.h"
#import "WKOptions.h"
#import "WKMacro.h"
#import "WKLock.h"

@interface WKFrameOutput () <WKPacketOutputDelegate, WKDecodeLoopDelegate>

{
    struct {
        NSError *error;
        WKFrameOutputState state;
    } _flags;
    BOOL _capacityFlags[8];
    WKCapacity _capacities[8];
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) WKDecodeLoop *audioDecoder;
@property (nonatomic, strong, readonly) WKDecodeLoop *videoDecoder;
@property (nonatomic, strong, readonly) WKPacketOutput *packetOutput;
@property (nonatomic, strong, readonly) NSArray<WKTrack *> *finishedTracks;

@end

@implementation WKFrameOutput

@synthesize selectedTracks = _selectedTracks;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithAsset:(WKAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_audioDecoder = [[WKDecodeLoop alloc] initWithDecoderClass:[WKAudioDecoder class]];
        self->_audioDecoder.delegate = self;
        self->_videoDecoder = [[WKDecodeLoop alloc] initWithDecoderClass:[WKVideoDecoder class]];
        self->_videoDecoder.delegate = self;
        self->_packetOutput = [[WKPacketOutput alloc] initWithAsset:asset];
        self->_packetOutput.delegate = self;
        for (int i = 0; i < 8; i++) {
            self->_capacityFlags[i] = NO;
            self->_capacities[i] = WKCapacityCreate();
        }
        [self setDecoderOptions:[WKOptions sharedOptions].decoder.copy];
    }
    return self;
}

- (void)dealloc
{
    WKLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != WKFrameOutputStateClosed;
    }, ^WKBlock {
        [self setState:WKFrameOutputStateClosed];
        [self->_packetOutput close];
        [self->_audioDecoder close];
        [self->_videoDecoder close];
        return nil;
    });
}

#pragma mark - Mapping

WKGet0Map(CMTime, duration, self->_packetOutput)
WKGet0Map(NSDictionary *, metadata, self->_packetOutput)
WKGet0Map(NSArray<WKTrack *> *, tracks, self->_packetOutput)
WKGet00Map(WKDemuxerOptions *,demuxerOptions, options, self->_packetOutput)
WKGet00Map(WKDecoderOptions *, decoderOptions, options, self->_audioDecoder)
WKSet11Map(void, setDemuxerOptions, setOptions, WKDemuxerOptions *, self->_packetOutput)

#pragma mark - Setter & Getter

- (void)setDecoderOptions:(WKDecoderOptions *)decoderOptions
{
    self->_audioDecoder.options = decoderOptions;
    self->_videoDecoder.options = decoderOptions;
}

- (WKBlock)setState:(WKFrameOutputState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate frameOutput:self didChangeState:state];
    };
}

- (WKFrameOutputState)state
{
    __block WKFrameOutputState ret = WKFrameOutputStateNone;
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

- (BOOL)selectTracks:(NSArray<WKTrack *> *)tracks
{
    return WKLockCondEXE10(self->_lock, ^BOOL {
        return ![self->_selectedTracks isEqualToArray:tracks];
    }, ^WKBlock {
        self->_selectedTracks = [tracks copy];
        return nil;
    });
}

- (NSArray<WKTrack *> *)selectedTracks
{
    __block NSArray<WKTrack *> *ret = nil;
    WKLockEXE00(self->_lock, ^{
        ret = [self->_selectedTracks copy];
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

- (WKBlock)setFinishedTracks:(NSArray<WKTrack *> *)tracks
{
    if (tracks.count <= 0) {
        self->_finishedTracks = nil;
        return ^{};
    }
    WKBlock b1 = ^{}, b2 = ^{};
    if (![tracks isEqualToArray:self->_finishedTracks]) {
        NSMutableArray<WKTrack *> *audioTracks = [NSMutableArray array];
        NSMutableArray<WKTrack *> *videoTracks = [NSMutableArray array];
        for (WKTrack *obj in tracks) {
            if ([self->_selectedTracks containsObject:obj] &&
                ![self->_finishedTracks containsObject:obj]) {
                if (obj.type == WKMediaTypeAudio) {
                    [audioTracks addObject:obj];
                } else if (obj.type == WKMediaTypeVideo) {
                    [videoTracks addObject:obj];
                }
            }
        }
        self->_finishedTracks = tracks;
        if (audioTracks.count) {
            WKDecodeLoop *decoder = self->_audioDecoder;
            b1 = ^{
                [decoder finish:audioTracks];
            };
        }
        if (videoTracks.count) {
            WKDecodeLoop *decoder = self->_videoDecoder;
            b2 = ^{
                [decoder finish:videoTracks];
            };
        }
    }
    return ^{b1(); b2();};
}

#pragma mark - Control

- (BOOL)open
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKFrameOutputStateNone;
    }, ^WKBlock {
        return [self setState:WKFrameOutputStateOpening];
    }, ^BOOL(WKBlock block) {
        block();
        return [self->_packetOutput open];
    });
}

- (BOOL)start
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKFrameOutputStateOpened;
    }, ^WKBlock {
        return [self setState:WKFrameOutputStateReading];
    }, ^BOOL(WKBlock block) {
        block();
        return [self->_packetOutput resume];
    });
}

- (BOOL)close
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state != WKFrameOutputStateClosed;
    }, ^WKBlock {
        return [self setState:WKFrameOutputStateClosed];
    }, ^BOOL(WKBlock block) {
        block();
        [self->_packetOutput close];
        [self->_audioDecoder close];
        [self->_videoDecoder close];
        return YES;
    });
}

- (BOOL)pause:(WKMediaType)type
{
    return WKLockEXE00(self->_lock, ^{
        if (type == WKMediaTypeAudio) {
            [self->_audioDecoder pause];
        } else if (type == WKMediaTypeVideo) {
            [self->_videoDecoder pause];
        }
    });
}

- (BOOL)resume:(WKMediaType)type
{
    return WKLockEXE00(self->_lock, ^{
        if (type == WKMediaTypeAudio) {
            [self->_audioDecoder resume];
        } else if (type == WKMediaTypeVideo) {
            [self->_videoDecoder resume];
        }
    });
}

- (BOOL)seekable
{
    return [self->_packetOutput seekable];
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
    return [self->_packetOutput seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        WKStrongify(self)
        if (!error) {
            [self->_audioDecoder flush];
            [self->_videoDecoder flush];
        }
        if (result) {
            result(time, error);
        }
    }];
}

#pragma mark - WKPacketOutputDelegate

- (void)packetOutput:(WKPacketOutput *)packetOutput didChangeState:(WKPacketOutputState)state
{
    WKLockEXE10(self->_lock, ^WKBlock {
        WKBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        switch (state) {
            case WKPacketOutputStateOpened: {
                b1 = [self setState:WKFrameOutputStateOpened];
                int nb_a = 0, nb_v = 0;
                NSMutableArray *tracks = [NSMutableArray array];
                for (WKTrack *obj in packetOutput.tracks) {
                    if (obj.type == WKMediaTypeAudio && nb_a == 0) {
                        [tracks addObject:obj];
                        nb_a += 1;
                    } else if (obj.type == WKMediaTypeVideo && nb_v == 0) {
                        [tracks addObject:obj];
                        nb_v += 1;
                    }
                    if (nb_a && nb_v) {
                        break;
                    }
                }
                self->_selectedTracks = [tracks copy];
                if (nb_a) {
                    [self->_audioDecoder open];
                }
                if (nb_v) {
                    [self->_videoDecoder open];
                }
            }
                break;
            case WKPacketOutputStateReading:
                b1 = [self setState:WKFrameOutputStateReading];
                break;
            case WKPacketOutputStateSeeking:
                b1 = [self setState:WKFrameOutputStateSeeking];
                break;
            case WKPacketOutputStateFinished: {
                b1 = [self setFinishedTracks:self->_selectedTracks];
            }
                break;
            case WKPacketOutputStateFailed:
                self->_flags.error = [packetOutput.error copy];
                b1 = [self setState:WKFrameOutputStateFailed];
                break;
            default:
                break;
        }
        return ^{
            b1(); b2(); b3();
        };
    });
}

- (void)packetOutput:(WKPacketOutput *)packetOutput didOutputPacket:(WKPacket *)packet
{
    WKLockEXE10(self->_lock, ^WKBlock {
        WKBlock b1 = ^{}, b2 = ^{};
        b1 = [self setFinishedTracks:packetOutput.finishedTracks];
        if ([self->_selectedTracks containsObject:packet.track]) {
            WKDecodeLoop *decoder = nil;
            if (packet.track.type == WKMediaTypeAudio) {
                decoder = self->_audioDecoder;
            } else if (packet.track.type == WKMediaTypeVideo) {
                decoder = self->_videoDecoder;
            }
            b2 = ^{
                [decoder putPacket:packet];
            };
        }
        return ^{b1(); b2();};
    });
}

#pragma mark - WKDecoderDelegate

- (void)decodeLoop:(WKDecodeLoop *)decodeLoop didChangeState:(WKDecodeLoopState)state
{
    
}

- (void)decodeLoop:(WKDecodeLoop *)decodeLoop didChangeCapacity:(WKCapacity)capacity
{
    __block WKBlock finished = ^{};
    __block WKMediaType type = WKMediaTypeUnknown;
    WKLockCondEXE11(self->_lock, ^BOOL {
        if (decodeLoop == self->_audioDecoder) {
            type = WKMediaTypeAudio;
        } else if (decodeLoop == self->_videoDecoder) {
            type = WKMediaTypeVideo;
        }
        return !WKCapacityIsEqual(self->_capacities[type], capacity);
    }, ^WKBlock {
        self->_capacityFlags[type] = YES;
        self->_capacities[type] = capacity;
        WKCapacity ac = self->_capacities[WKMediaTypeAudio];
        WKCapacity vc = self->_capacities[WKMediaTypeVideo];
        int size = ac.size + vc.size;
        BOOL enough = NO;
        if ((!self->_capacityFlags[WKMediaTypeAudio] || WKCapacityIsEnough(ac)) &&
            (!self->_capacityFlags[WKMediaTypeVideo] || WKCapacityIsEnough(vc))) {
            enough = YES;
        }
        if ((!self->_capacityFlags[WKMediaTypeAudio] || WKCapacityIsEmpty(ac)) &&
            (!self->_capacityFlags[WKMediaTypeVideo] || WKCapacityIsEmpty(vc)) &&
            self->_packetOutput.state == WKPacketOutputStateFinished) {
            finished = [self setState:WKFrameOutputStateFinished];
        }
        return ^{
//            if (enough || (size > 15 * 1024 * 1024)) {
            //wk add SGPacket包缓冲区大小设置，解决缓冲过小
            if (enough || (ac.size > 0.4 * 1024 * 1024)) {
                [self->_packetOutput pause];
            } else {
                [self->_packetOutput resume];
            }
        };
    }, ^BOOL(WKBlock block) {
        block();
        [self->_delegate frameOutput:self didChangeCapacity:capacity type:type];
        finished();
        return YES;
    });
}

- (void)decodeLoop:(WKDecodeLoop *)decodeLoop didOutputFrames:(NSArray<__kindof WKFrame *> *)frames needsDrop:(BOOL (^)(void))needsDrop
{
    [self->_delegate frameOutput:self didOutputFrames:frames needsDrop:needsDrop];
}

@end
