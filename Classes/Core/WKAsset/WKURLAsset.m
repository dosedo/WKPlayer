//
//  WKURLAsset.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKURLAsset.h"
#import "WKAsset+Internal.h"
#import "WKURLDemuxer.h"

@implementation WKURLAsset

- (id)copyWithZone:(NSZone *)zone
{
    WKURLAsset *obj = [super copyWithZone:zone];
    obj->_URL = [self->_URL copy];
    return obj;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self->_URL = [URL copy];
    }
    return self;
}

- (id<WKDemuxable>)newDemuxer
{
    return [[WKURLDemuxer alloc] initWithURL:self->_URL];
}

@end
