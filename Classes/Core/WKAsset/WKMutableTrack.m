//
//  WKMutableTrack.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMutableTrack.h"
#import "WKTrack+Internal.h"

@interface WKMutableTrack ()

{
    NSMutableArray<WKSegment *> *_segments;
}

@end

@implementation WKMutableTrack

- (id)copyWithZone:(NSZone *)zone
{
    WKMutableTrack *obj = [super copyWithZone:zone];
    obj->_segments = [self->_segments mutableCopy];
    obj->_subTracks = [self->_subTracks copy];
    return obj;
}

- (instancetype)initWithType:(WKMediaType)type index:(NSInteger)index
{
    if (self = [super initWithType:type index:index]) {
        self->_segments = [NSMutableArray array];
    }
    return self;
}

- (void *)coreptr
{
    return [self core];
}

- (AVStream *)core
{
    void *ret = [super core];
    if (ret) {
        return ret;
    }
    for (WKTrack *obj in self->_subTracks) {
        if (obj.core) {
            ret = obj.core;
            break;
        }
    }
    return ret;
}

- (BOOL)appendSegment:(WKSegment *)segment
{
    [self->_segments addObject:segment];
    return YES;
}

@end
