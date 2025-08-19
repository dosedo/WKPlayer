//
//  WKAudioFrame.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioFrame.h"
#import "WKFrame+Internal.h"
#import "WKDescriptor+Internal.h"
#import "WKObjectPool.h"

@interface WKAudioFrame ()

{
    int _linesize[WKFramePlaneCount];
    uint8_t *_data[WKFramePlaneCount];
}

@end

@implementation WKAudioFrame

+ (instancetype)frame
{
    static NSString *name = @"WKAudioFrame";
    return [[WKObjectPool sharedPool] objectWithClass:[self class] reuseName:name];
}

+ (instancetype)frameWithDescriptor:(WKAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples
{
    WKAudioFrame *frame = [WKAudioFrame frame];
    frame.core->format = descriptor.format;
    frame.core->nb_samples = numberOfSamples;
    frame.core->sample_rate = descriptor.sampleRate;
    frame.core->ch_layout = descriptor.channelLayout;
    int linesize = [descriptor linesize:numberOfSamples];
    for (int i = 0; i < descriptor.numberOfPlanes; i++) {
        uint8_t *data = av_mallocz(linesize);
        memset(data, 0, linesize);
        AVBufferRef *buffer = av_buffer_create(data, linesize, NULL, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = (int)buffer->size;
    }
    return frame;
}

#pragma mark - Setter & Getter

- (WKMediaType)type
{
    return WKMediaTypeAudio;
}

- (int *)linesize
{
    return self->_linesize;
}

- (uint8_t **)data
{
    return self->_data;
}

#pragma mark - Data

- (void)clear
{
    [super clear];
    self->_numberOfSamples = 0;
    for (int i = 0; i < WKFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
    self->_descriptor = nil;
}

#pragma mark - Control

- (void)fill
{
    AVFrame *frame = self.core;
    AVRational timebase = self.codecDescriptor.timebase;
    WKCodecDescriptor *cd = self.codecDescriptor;
    CMTime duration = CMTimeMake(frame->nb_samples, frame->sample_rate);
    CMTime timeStamp = CMTimeMake(frame->best_effort_timestamp * timebase.num, timebase.den);
    CMTime decodeTimeStamp = CMTimeMake(frame->pkt_dts * timebase.num, timebase.den);
    duration = [cd convertDuration:duration];
    timeStamp = [cd convertTimeStamp:timeStamp];
    decodeTimeStamp = [cd convertTimeStamp:decodeTimeStamp];
    [self fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
}

- (void)fillWithFrame:(WKFrame *)frame
{
    [super fillWithFrame:frame];
    WKAudioFrame *audioFrame = (WKAudioFrame *)frame;
    self->_numberOfSamples = audioFrame->_numberOfSamples;
    self->_descriptor = audioFrame->_descriptor.copy;
    for (int i = 0; i < WKFramePlaneCount; i++) {
        self->_data[i] = audioFrame->_data[i];
        self->_linesize[i] = audioFrame->_linesize[i];
    }
}

- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration
{
    [super fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
    AVFrame *frame = self.core;
    self->_numberOfSamples = frame->nb_samples;
    self->_descriptor = [[WKAudioDescriptor alloc] initWithFrame:frame];
    for (int i = 0; i < WKFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
