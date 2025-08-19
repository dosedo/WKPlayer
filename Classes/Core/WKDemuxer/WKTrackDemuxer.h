//
//  WKTrackDemuxer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDemuxable.h"
#import "WKMutableTrack.h"

@interface WKTrackDemuxer : NSObject <WKDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTrack:(WKMutableTrack *)track;

@end
