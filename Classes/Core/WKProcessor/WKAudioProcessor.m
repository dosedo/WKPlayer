//
//  WKAudioProcessor.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAudioProcessor.h"
#import "WKAudioMixer.h"

@interface WKAudioProcessor ()

@property (nonatomic, strong, readonly) WKAudioMixer *mixer;
@property (nonatomic, strong, readonly) WKTrackSelection *selection;

@end

@implementation WKAudioProcessor

- (void)setSelection:(WKTrackSelection *)selection action:(WKTrackSelectionAction)action
{
    self->_selection = [selection copy];
    if (action & WKTrackSelectionActionTracks) {
        self->_mixer = [[WKAudioMixer alloc] initWithTracks:selection.tracks weights:selection.weights];
    } else if (action & WKTrackSelectionActionWeights) {
        self->_mixer.weights = selection.weights;
    }
}

- (__kindof WKFrame *)putFrame:(__kindof WKFrame *)frame
{
    if (![frame isKindOfClass:[WKAudioFrame class]] ||
        ![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    return [self->_mixer putFrame:frame];
}

- (WKAudioFrame *)finish
{
    return [self->_mixer finish];
}

- (WKCapacity)capacity
{
    return [self->_mixer capacity];
}

- (void)flush
{
    [self->_mixer flush];
}

- (void)close
{
    self->_mixer = nil;
}

@end
