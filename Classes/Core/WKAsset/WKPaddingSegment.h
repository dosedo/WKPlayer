//
//  WKPaddingSegment.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKSegment.h"

@interface WKPaddingSegment : WKSegment

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDuration:(CMTime)duration;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

@end
