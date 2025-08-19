//
//  WKTrackDemuxer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKTrackDemuxer.h"
#import "WKTrack+Internal.h"
#import "WKPacket+Internal.h"
#import "WKSegment+Internal.h"
#import "WKError.h"

@interface WKTrackDemuxer ()

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, strong, readonly) WKMutableTrack *track;
@property (nonatomic, strong, readonly) WKTimeLayout *currentLayout;
@property (nonatomic, strong, readonly) id<WKDemuxable> currentDemuxer;
@property (nonatomic, strong, readonly) NSMutableArray<WKTimeLayout *> *layouts;
@property (nonatomic, strong, readonly) NSMutableArray<id<WKDemuxable>> *demuxers;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id<WKDemuxable>> *sharedDemuxers;

@end

@implementation WKTrackDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize duration = _duration;
@synthesize metadata = _metadata;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithTrack:(WKMutableTrack *)track
{
    if (self = [super init]) {
        self->_track = [track copy];
        self->_tracks = @[self->_track];
        self->_layouts = [NSMutableArray array];
        self->_demuxers = [NSMutableArray array];
        self->_sharedDemuxers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Setter & Getter

- (void)setDelegate:(id<WKDemuxableDelegate>)delegate
{
    self->_delegate = delegate;
    for (id<WKDemuxable> obj in self->_demuxers) {
        obj.delegate = delegate;
    }
}

- (void)setOptions:(WKDemuxerOptions *)options
{
    self->_options = [options copy];
    for (id<WKDemuxable> obj in self->_demuxers) {
        obj.options = options;
    }
}

#pragma mark - Control

- (id<WKDemuxable>)sharedDemuxer
{
    return nil;
}

- (NSError *)open
{
    CMTime basetime = kCMTimeZero;
    NSMutableArray<WKTrack *> *subTracks = [NSMutableArray array];
    for (WKSegment *obj in self->_track.segments) {
        WKTimeLayout *layout = [[WKTimeLayout alloc] initWithOffset:basetime];
        NSString *demuxerKey = [obj sharedDemuxerKey];
        id<WKDemuxable> sharedDemuxer = self->_sharedDemuxers[demuxerKey];
        id<WKDemuxable> demuxer = nil;
        if (!demuxerKey) {
            demuxer = [obj newDemuxer];
        } else if (sharedDemuxer) {
            demuxer = [obj newDemuxerWithSharedDemuxer:sharedDemuxer];
        } else {
            demuxer = [obj newDemuxer];
            id<WKDemuxable> reuseDemuxer = [demuxer sharedDemuxer];
            if (reuseDemuxer) {
                self->_sharedDemuxers[demuxerKey] = reuseDemuxer;
            }
        }
        demuxer.options = self->_options;
        demuxer.delegate = self->_delegate;
        [self->_layouts addObject:layout];
        [self->_demuxers addObject:demuxer];
        NSError *error = [demuxer open];
        if (error) {
            return error;
        }
        NSAssert(CMTIME_IS_VALID(demuxer.duration), @"Invaild Duration.");
        NSAssert(!demuxer.tracks.firstObject || demuxer.tracks.firstObject.type == self->_track.type, @"Invaild mediaType.");
        basetime = CMTimeAdd(basetime, demuxer.duration);
        if (demuxer.tracks.firstObject) {
            [subTracks addObject:demuxer.tracks.firstObject];
        }
    }
    self->_duration = basetime;
    self->_track.subTracks = subTracks;
    self->_currentIndex = 0;
    self->_currentLayout = self->_layouts.firstObject;
    self->_currentDemuxer = self->_demuxers.firstObject;
    [self->_currentDemuxer seekToTime:kCMTimeZero];
    return nil;
}

- (NSError *)close
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        [obj close];
    }
    return nil;
}

- (NSError *)seekable
{
    for (id<WKDemuxable> obj in self->_demuxers) {
        NSError *error = [obj seekable];
        if (error) {
            return error;
        }
    }
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return WKCreateError(WKErrorCodeInvlidTime, WKActionCodeFormatSeekFrame);
    }
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    NSInteger currentIndex = self->_demuxers.count - 1;
    WKTimeLayout *currentLayout = self->_layouts.lastObject;
    id<WKDemuxable> currentDemuxer = self->_demuxers.lastObject;
    for (NSUInteger i = 0; i < self->_demuxers.count; i++) {
        WKTimeLayout *layout = [self->_layouts objectAtIndex:i];
        id<WKDemuxable> demuxer = [self->_demuxers objectAtIndex:i];
        if (CMTimeCompare(time, CMTimeAdd(layout.offset, demuxer.duration)) <= 0) {
            currentIndex = i;
            currentLayout = layout;
            currentDemuxer = demuxer;
            break;
        }
    }
    time = CMTimeSubtract(time, currentLayout.offset);
    self->_finishedTracks = nil;
    self->_currentIndex = currentIndex;
    self->_currentLayout = currentLayout;
    self->_currentDemuxer = currentDemuxer;
    return [self->_currentDemuxer seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
}

- (NSError *)nextPacket:(WKPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        if (!self->_currentDemuxer) {
            error = WKCreateError(WKErrorCodeDemuxerEndOfFile, WKActionCodeFormatReadFrame);
            break;
        }
        error = [self->_currentDemuxer nextPacket:packet];
        if (error) {
            if (error.code == WKErrorImmediateExitRequested) {
                break;
            }
            NSInteger nextIndex = self->_currentIndex + 1;
            if (nextIndex < self->_demuxers.count) {
                self->_currentIndex = nextIndex;
                self->_currentLayout = [self->_layouts objectAtIndex:nextIndex];
                self->_currentDemuxer = [self->_demuxers objectAtIndex:nextIndex];
                [self->_currentDemuxer seekToTime:kCMTimeZero];
            } else {
                self->_currentIndex = 0;
                self->_currentLayout = nil;
                self->_currentDemuxer = nil;
            }
            continue;
        }
        [(*packet).codecDescriptor setTrack:self->_track];
        [(*packet).codecDescriptor appendTimeLayout:self->_currentLayout];
        [(*packet) fill];
        break;
    }
    if (error.code == WKErrorCodeDemuxerEndOfFile) {
        self->_finishedTracks = self->_tracks.copy;
    }
    return error;
}

@end
