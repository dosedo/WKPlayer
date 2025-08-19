//
//  WKMutableAsset.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMutableAsset.h"
#import "WKAsset+Internal.h"
#import "WKTrack+Internal.h"
#import "WKTrackDemuxer.h"
#import "WKMutilDemuxer.h"

@interface WKMutableAsset ()

{
    NSMutableArray<WKMutableTrack *> *_tracks;
}

@end

@implementation WKMutableAsset

- (id)copyWithZone:(NSZone *)zone
{
    WKMutableAsset *obj = [super copyWithZone:zone];
    obj->_tracks = [self->_tracks mutableCopy];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_tracks = [NSMutableArray array];
    }
    return self;
}

- (NSArray<WKMutableTrack *> *)tracks
{
    return [self->_tracks copy];
}

- (WKMutableTrack *)addTrack:(WKMediaType)type
{
    NSInteger index = self->_tracks.count;
    WKMutableTrack *obj = [[WKMutableTrack alloc] initWithType:type index:index];
    [self->_tracks addObject:obj];
    return obj;
}

- (id<WKDemuxable>)newDemuxer
{
    NSMutableArray *demuxables = [NSMutableArray array];
    for (WKMutableTrack *obj in self->_tracks) {
        WKTrackDemuxer *demuxer = [[WKTrackDemuxer alloc] initWithTrack:obj];
        [demuxables addObject:demuxer];
    }
    return [[WKMutilDemuxer alloc] initWithDemuxables:demuxables];
}

@end
