//
//  WKTrack.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKTrack.h"
#import "WKTrack+Internal.h"

@implementation WKTrack

- (id)copyWithZone:(NSZone *)zone
{
    WKTrack *obj = [[self.class alloc] init];
    obj->_type = self->_type;
    obj->_index = self->_index;
    obj->_core = self->_core;
    return obj;
}

- (instancetype)initWithType:(WKMediaType)type index:(NSInteger)index
{
    if (self = [super init]) {
        self->_type = type;
        self->_index = index;
    }
    return self;
}

- (void *)coreptr
{
    return self->_core;
}

+ (WKTrack *)trackWithTracks:(NSArray<WKTrack *> *)tracks type:(WKMediaType)type
{
    for (WKTrack *obj in tracks) {
        if (obj.type == type) {
            return obj;
        }
    }
    return nil;
}

+ (WKTrack *)trackWithTracks:(NSArray<WKTrack *> *)tracks index:(NSInteger)index
{
    for (WKTrack *obj in tracks) {
        if (obj.index == index) {
            return obj;
        }
    }
    return nil;
}

+ (NSArray<WKTrack *> *)tracksWithTracks:(NSArray<WKTrack *> *)tracks type:(WKMediaType)type
{
    NSMutableArray *array = [NSMutableArray array];
    for (WKTrack *obj in tracks) {
        if (obj.type == type) {
            [array addObject:obj];
        }
    }
    return array.count ? [array copy] : nil;
}

@end
