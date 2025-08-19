//
//  WKDecoderOptions.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDecoderOptions.h"
#import "WKAudioRenderer.h"
#import "WKVideoRenderer.h"
#import "WKMapping.h"

@implementation WKDecoderOptions

- (id)copyWithZone:(NSZone *)zone
{
    WKDecoderOptions *obj = [[WKDecoderOptions alloc] init];
    obj->_options = self->_options.copy;
    obj->_threadsAuto = self->_threadsAuto;
    obj->_refcountedFrames = self->_refcountedFrames;
    obj->_hardwareDecodeH264 = self->_hardwareDecodeH264;
    obj->_hardwareDecodeH265 = self->_hardwareDecodeH265;
    obj->_preferredCVPixelFormat = self->_preferredCVPixelFormat;
    obj->_supportedPixelFormats = self->_supportedPixelFormats.copy;
    obj->_supportedAudioDescriptors = self->_supportedAudioDescriptors.copy;
    obj->_resetFrameRate = self->_resetFrameRate;
    obj->_preferredFrameRate = self->_preferredFrameRate;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_options = nil;
        self->_threadsAuto = YES;
        self->_refcountedFrames = YES;
        self->_hardwareDecodeH264 = YES;
        self->_hardwareDecodeH265 = YES;
        self->_preferredCVPixelFormat = WKPixelFormatFF2AV(AV_PIX_FMT_NV12);
        self->_supportedPixelFormats = [WKVideoRenderer supportedPixelFormats];
        self->_supportedAudioDescriptors = @[[WKAudioRenderer supportedAudioDescriptor]];
        self->_resetFrameRate = NO;
        self->_preferredFrameRate = CMTimeMake(1, 25);
    }
    return self;
}

@end
