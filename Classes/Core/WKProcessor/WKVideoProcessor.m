//
//  WKVideoProcessor.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKVideoProcessor.h"
#import "WKVideoFrame.h"

@interface WKVideoProcessor ()

@property (nonatomic, strong, readonly) WKTrackSelection *selection;

@end

@implementation WKVideoProcessor

- (void)setSelection:(WKTrackSelection *)selection action:(WKTrackSelectionAction)action
{
    self->_selection = [selection copy];
}

- (__kindof WKFrame *)putFrame:(__kindof WKFrame *)frame
{
    if (![frame isKindOfClass:[WKVideoFrame class]] ||
        ![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    return frame;
}

- (__kindof WKFrame *)finish
{
    return nil;
}

- (WKCapacity)capacity
{
    return WKCapacityCreate();
}

- (void)flush
{

}

- (void)close
{

}

@end
