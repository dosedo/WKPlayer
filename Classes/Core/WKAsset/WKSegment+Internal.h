//
//  WKSegment+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKSegment.h"
#import "WKDemuxable.h"

@interface WKSegment ()

/**
 *
 */
- (NSString *)sharedDemuxerKey;

/**
 *
 */
- (id<WKDemuxable>)newDemuxer;

/**
 *
 */
- (id<WKDemuxable>)newDemuxerWithSharedDemuxer:(id<WKDemuxable>)demuxer;

@end
