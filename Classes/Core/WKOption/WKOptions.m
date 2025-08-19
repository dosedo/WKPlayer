//
//  WKOptions.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKOptions.h"

@implementation WKOptions

+ (instancetype)sharedOptions
{
    static WKOptions *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[WKOptions alloc] init];
    });
    return obj;
}

- (id)copyWithZone:(NSZone *)zone
{
    WKOptions *obj = [[WKOptions alloc] init];
    obj->_demuxer = self->_demuxer.copy;
    obj->_decoder = self->_decoder.copy;
    obj->_processor = self->_processor.copy;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_demuxer = [[WKDemuxerOptions alloc] init];
        self->_decoder = [[WKDecoderOptions alloc] init];
        self->_processor = [[WKProcessorOptions alloc] init];
    }
    return self;
}

@end
