//
//  WKObjectQueue.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKCapacity.h"
#import "WKDefines.h"
#import "WKData.h"

@interface WKObjectQueue : NSObject

/**
 *
 */
- (instancetype)initWithMaxCount:(uint64_t)maxCount;

/**
 *
 */
@property (nonatomic) BOOL shouldSortObjects;

/**
 *
 */
- (WKCapacity)capacity;

/**
 *
 */
- (BOOL)putObjectSync:(id<WKData>)object;
- (BOOL)putObjectSync:(id<WKData>)object before:(WKBlock)before after:(WKBlock)after;

/**
 *
 */
- (BOOL)putObjectAsync:(id<WKData>)object;

/**
 *
 */
- (BOOL)getObjectSync:(id<WKData> *)object;
- (BOOL)getObjectSync:(id<WKData> *)object before:(WKBlock)before after:(WKBlock)after;

/**
 *
 */
- (BOOL)getObjectAsync:(id<WKData> *)object;
- (BOOL)getObjectAsync:(id<WKData> *)object timeReader:(WKTimeReader)timeReader discarded:(uint64_t *)discarded;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)destroy;

@end
