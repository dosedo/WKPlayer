//
//  WKDemuxerOptions.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDemuxerOptions.h"

@implementation WKDemuxerOptions

- (id)copyWithZone:(NSZone *)zone
{
    WKDemuxerOptions *obj = [[WKDemuxerOptions alloc] init];
    obj->_options = self->_options.copy;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_options = @{@"reconnect" : @(1),
                           @"user-agent" : @"WKPlayer",
                           @"timeout" : @(20 * 1000 * 1000)};
    }
    return self;
}

@end
