//
//  WKAsset+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAsset.h"
#import "WKDemuxable.h"

@interface WKAsset ()

/*!
 @method newDemuxer
 @abstract
    Create a new demuxer.
 */
- (id<WKDemuxable>)newDemuxer;

@end
