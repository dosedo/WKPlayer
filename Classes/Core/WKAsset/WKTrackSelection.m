//
//  WKTrackSelection.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKTrackSelection.h"

@implementation WKTrackSelection

- (id)copyWithZone:(NSZone *)zone
{
    WKTrackSelection *obj = [[WKTrackSelection alloc] init];
    obj->_tracks = self->_tracks;
    obj->_weights = self->_weights;
    return obj;
}

@end
