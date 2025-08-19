//
//  WKURLDemuxer.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDemuxable.h"

@interface WKURLDemuxer : NSObject <WKDemuxable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithURL:
 @abstract
    Initializes an WKURLDemuxer with an NSURL.
 */
- (instancetype)initWithURL:(NSURL *)URL;

/*!
 @property URL
 @abstract
    Indicates the URL of the demuxer.
 */
@property (nonatomic, copy, readonly) NSURL *URL;

@end
