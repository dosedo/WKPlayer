//
//  WKFrameReader.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKFrameReader.h"
#import "WKAsset+Internal.h"
#import "WKAudioDecoder.h"
#import "WKVideoDecoder.h"
#import "WKObjectQueue.h"
#import "WKDecodable.h"
#import "WKOptions.h"
#import "WKMacro.h"
#import "WKError.h"
#import "WKLock.h"

@interface WKFrameReader () <WKDemuxableDelegate>

{
    struct {
        BOOL noMorePacket;
    } _flags;
}

@property (nonatomic, strong, readonly) id<WKDemuxable> demuxer;
@property (nonatomic, strong, readonly) WKObjectQueue *frameQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, id<WKDecodable>> *decoders;

@end

@implementation WKFrameReader

@synthesize selectedTracks = _selectedTracks;

- (instancetype)initWithAsset:(WKAsset *)asset
{
    if (self = [super init]) {
        self->_demuxer = [asset newDemuxer];
        self->_demuxer.delegate = self;
        self->_demuxer.options = [WKOptions sharedOptions].demuxer.copy;
        self->_decoderOptions = [WKOptions sharedOptions].decoder.copy;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Mapping

WKGet0Map(CMTime, duration, self->_demuxer)
WKGet0Map(NSError *, seekable, self->_demuxer);
WKGet0Map(NSDictionary *, metadata, self->_demuxer)
WKGet0Map(WKDemuxerOptions *, options, self->_demuxer)
WKGet0Map(NSArray<WKTrack *> *, tracks, self->_demuxer)
WKGet00Map(WKDemuxerOptions *,demuxerOptions, options, self->_demuxer)
WKSet11Map(void, setDemuxerOptions, setOptions, WKDemuxerOptions *, self->_demuxer)

#pragma mark - Setter & Getter

- (NSArray<WKTrack *> *)selectedTracks
{
    return [self->_selectedTracks copy];
}

- (void)setDecoderOptions:(WKDecoderOptions *)decoderOptions
{
    self->_decoderOptions = decoderOptions;
    for (id<WKDecodable> obj in self->_decoders.allValues) {
        obj.options = decoderOptions;
    }
}

#pragma mark - Control

- (NSError *)open
{
    NSError *error = [self->_demuxer open];
    if (!error) {
        self->_selectedTracks = [self->_demuxer.tracks copy];
        self->_decoders = [[NSMutableDictionary alloc] init];
        self->_frameQueue = [[WKObjectQueue alloc] init];
        self->_frameQueue.shouldSortObjects = YES;
    }
    return error;
}

- (NSError *)close
{
    self->_decoders = nil;
    self->_frameQueue = nil;
    return [self->_demuxer close];
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    NSError *error = [self->_demuxer seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
    if (!error) {
        for (id<WKDecodable> obj in self->_decoders.allValues) {
            [obj flush];
        }
        [self->_frameQueue flush];
        self->_flags.noMorePacket = NO;
    }
    return error;
}

- (NSError *)selectTracks:(NSArray<WKTrack *> *)tracks
{
    self->_selectedTracks = [tracks copy];
    return nil;
}

- (NSError *)nextFrame:(__kindof WKFrame **)frame
{
    NSError *err= nil;
    __kindof WKFrame *ret = nil;
    while (!ret && !err) {
        if ([self->_frameQueue getObjectAsync:&ret]) {
            continue;
        }
        if (self->_flags.noMorePacket) {
            err = WKCreateError(WKErrorCodeDemuxerEndOfFile, WKActionCodeNextFrame);
            continue;
        }
        WKPacket *packet = nil;
        [self->_demuxer nextPacket:&packet];
        NSArray<__kindof WKFrame *> *objs = nil;
        if (packet) {
            if (![self->_selectedTracks containsObject:packet.track]) {
                [packet unlock];
                continue;
            }
            id<WKDecodable> decoder = [self->_decoders objectForKey:@(packet.track.index)];
            if (!decoder) {
                if (packet.track.type == WKMediaTypeAudio) {
                    decoder = [[WKAudioDecoder alloc] init];
                }
                if (packet.track.type == WKMediaTypeVideo) {
                    decoder = [[WKVideoDecoder alloc] init];
                }
                if (decoder) {
                    decoder.options = self->_decoderOptions;
                    [self->_decoders setObject:decoder forKey:@(packet.track.index)];
                }
            }
            objs = [decoder decode:packet];
            [packet unlock];
        } else {
            NSMutableArray<__kindof WKFrame *> *mObjs = [NSMutableArray array];
            for (id<WKDecodable> decoder in self->_decoders.allValues) {
                [mObjs addObjectsFromArray:[decoder finish]];
            }
            objs = [mObjs copy];
            self->_flags.noMorePacket = YES;
        }
        for (id<WKData> obj in objs) {
            [self->_frameQueue putObjectSync:obj];
            [obj unlock];
        }
    }
    if (ret) {
        if (frame) {
            *frame = ret;
        } else {
            [ret unlock];
        }
    }
    return err;
}

#pragma mark - WKDemuxableDelegate

- (BOOL)demuxableShouldAbortBlockingFunctions:(id<WKDemuxable>)demuxable
{
    if ([self->_delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        return [self->_delegate frameReaderShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
