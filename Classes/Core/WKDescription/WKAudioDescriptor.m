//
//  WKAudioDescriptor.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioDescriptor.h"
#import "WKDescriptor+Internal.h"
#import "WKFFmpeg.h"

@implementation WKAudioDescriptor

- (id)copyWithZone:(NSZone *)zone
{
    WKAudioDescriptor *obj = [[WKAudioDescriptor alloc] init];
    obj->_format = self->_format;
    obj->_sampleRate = self->_sampleRate;
    obj->_numberOfChannels = self->_numberOfChannels;
    obj->_channelLayout = self->_channelLayout;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_format = AV_SAMPLE_FMT_FLTP;
        self->_sampleRate = 44100;
        self->_numberOfChannels = 2;
        av_channel_layout_default(&self->_channelLayout, 2);
    }
    return self;
}

- (instancetype)initWithFrame:(AVFrame *)frame
{
    if (self = [super init]) {
        self->_format = frame->format;
        self->_sampleRate = frame->sample_rate;
        self->_numberOfChannels = frame->ch_layout.nb_channels;
        self->_channelLayout = frame->ch_layout;
    }
    return self;
}

- (BOOL)isPlanar
{
    return av_sample_fmt_is_planar(self->_format);
}

- (int)bytesPerSample
{
    return av_get_bytes_per_sample(self->_format);
}

- (int)numberOfPlanes
{
    return av_sample_fmt_is_planar(self->_format) ? self->_numberOfChannels : 1;
}

- (int)linesize:(int)numberOfSamples
{
    int linesize = av_get_bytes_per_sample(self->_format) * numberOfSamples;
    linesize *= av_sample_fmt_is_planar(self->_format) ? 1 : self->_numberOfChannels;
    return linesize;
}

- (BOOL)isEqualToDescriptor:(WKAudioDescriptor *)descriptor
{
    if (!descriptor) {
        return NO;
    }
    return
    self->_format == descriptor->_format &&
    self->_sampleRate == descriptor->_sampleRate &&
    self->_numberOfChannels == descriptor->_numberOfChannels &&
    (av_channel_layout_compare(&self->_channelLayout, &descriptor->_channelLayout) == 0);
}

@end
