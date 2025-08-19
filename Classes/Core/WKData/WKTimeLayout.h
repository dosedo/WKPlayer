//
//  WKTimeLayout.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTime.h"

@interface WKTimeLayout : NSObject <NSCopying>

/**
 *
 */
- (instancetype)initWithScale:(CMTime)scale;

/**
 *
 */
- (instancetype)initWithOffset:(CMTime)offset;

/**
 *
 */
@property (nonatomic, readonly) CMTime scale;

/**
 *
 */
@property (nonatomic, readonly) CMTime offset;

/**
 *
 */
- (CMTime)convertDuration:(CMTime)duration;

/**
 *
 */
- (CMTime)convertTimeStamp:(CMTime)timeStamp;

/**
 *
 */
- (CMTime)reconvertTimeStamp:(CMTime)timeStamp;

/**
 *
 */
- (BOOL)isEqualToTimeLayout:(WKTimeLayout *)timeLayout;

@end
