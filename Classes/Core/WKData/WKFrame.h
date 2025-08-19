//
//  WKFrame.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTrack.h"
#import "WKData.h"

static int const WKFramePlaneCount = 8;

@interface WKFrame : NSObject <WKData>

/**
 *
 */
@property (nonatomic, readonly) void *coreptr;

/**
 *
 */
@property (nonatomic, strong, readonly) WKTrack *track;

/**
 *
 */
@property (nonatomic, strong, readonly) NSDictionary *metadata;

/**
 *
 */
@property (nonatomic, readonly) CMTime duration;

/**
 *
 */
@property (nonatomic, readonly) CMTime timeStamp;

/**
 *
 */
@property (nonatomic, readonly) CMTime decodeTimeStamp;

/**
 *
 */
@property (nonatomic, readonly) int size;

@end
