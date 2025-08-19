//
//  WKTrackSelection.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTrack.h"

typedef NS_OPTIONS(NSUInteger, WKTrackSelectionAction) {
    WKTrackSelectionActionTracks  = 1 << 0,
    WKTrackSelectionActionWeights = 1 << 1,
};

@interface WKTrackSelection : NSObject <NSCopying>

/*!
 @property tracks
 @abstract
    Provides array of WKTrackSelection tracks.
 */
@property (nonatomic, copy) NSArray<WKTrack *> *tracks;

/*!
 @property weights
 @abstract
    Provides array of WKTrackSelection weights.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *weights;

@end
