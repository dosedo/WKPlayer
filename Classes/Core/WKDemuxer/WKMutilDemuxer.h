//
//  WKMutilDemuxer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDemuxable.h"

@interface WKMutilDemuxer : NSObject <WKDemuxable>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDemuxables:(NSArray<id<WKDemuxable>> *)demuxables;

@end
