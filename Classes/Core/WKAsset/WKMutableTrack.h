//
//  WKMutableTrack.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKSegment.h"
#import "WKTrack.h"

@interface WKMutableTrack : WKTrack

/*!
 @property subTracks
 @abstract
    Indicates the sub tracks.
 */
@property (nonatomic, copy, readonly) NSArray<WKTrack *> *subTracks;

/*!
 @property segments
 @abstract
    Provides array of WKMutableTrack segments.
 */
@property (nonatomic, copy, readonly) NSArray<WKSegment *> *segments;

/*!
 @method appendSegment:
 @abstract
    Append a segment to the track.
 */
- (BOOL)appendSegment:(WKSegment *)segment;

@end
