//
//  WKAudioFormatter.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioFormatter.h"
#import "WKFrame+Internal.h"
#import "WKSWResample.h"

@interface WKAudioFormatter ()

@property (nonatomic, readonly) WKTrack *track;
@property (nonatomic, readonly) CMTime nextTimeStamp;
@property (nonatomic, strong, readonly) WKSWResample *context;

@end

@implementation WKAudioFormatter

- (instancetype)init
{
    if (self = [super init]) {
        [self flush];
    }
    return self;
}

- (WKAudioFrame *)format:(WKAudioFrame *)frame
{
    if (![frame isKindOfClass:[WKAudioFrame class]]) {
        [frame unlock];
        return nil;
    }
    if (![self->_context.inputDescriptor isEqualToDescriptor:frame.descriptor] ||
        ![self->_context.outputDescriptor isEqualToDescriptor:self->_descriptor]) {
        [self flush];
        WKSWResample *context = [[WKSWResample alloc] init];
        context.inputDescriptor = frame.descriptor;
        context.outputDescriptor = self->_descriptor;
        if ([context open]) {
            self->_context = context;
        }
    }
    if (!self->_context) {
        [frame unlock];
        return nil;
    }
    self->_track = frame.track;
    int nb_samples = [self->_context write:frame.data nb_samples:frame.numberOfSamples];
    WKAudioFrame *ret = [self frameWithStart:frame.timeStamp nb_samples:nb_samples];
    self->_nextTimeStamp = CMTimeAdd(ret.timeStamp, ret.duration);
    [frame unlock];
    return ret;
}

- (WKAudioFrame *)finish
{
    if (!self->_track || !self->_context || CMTIME_IS_INVALID(self->_nextTimeStamp)) {
        return nil;
    }
    int nb_samples = [self->_context write:NULL nb_samples:0];
    if (nb_samples <= 0) {
        return nil;
    }
    WKAudioFrame *frame = [self frameWithStart:self->_nextTimeStamp nb_samples:nb_samples];
    return frame;
}

- (WKAudioFrame *)frameWithStart:(CMTime)start nb_samples:(int)nb_samples
{
    WKAudioFrame *frame = [WKAudioFrame frameWithDescriptor:self->_descriptor numberOfSamples:nb_samples];
    uint8_t nb_planes = self->_descriptor.numberOfPlanes;
    uint8_t *data[WKFramePlaneCount] = {NULL};
    for (int i = 0; i < nb_planes; i++) {
        data[i] = frame.core->data[i];
    }
    [self->_context read:data nb_samples:nb_samples];
    WKCodecDescriptor *cd = [[WKCodecDescriptor alloc] init];
    cd.track = self->_track;
    [frame setCodecDescriptor:cd];
    [frame fillWithTimeStamp:start decodeTimeStamp:start duration:CMTimeMake(nb_samples, self->_descriptor.sampleRate)];
    return frame;
}

- (void)flush
{
    self->_track = nil;
    self->_context = nil;
    self->_nextTimeStamp = kCMTimeInvalid;
}

@end
