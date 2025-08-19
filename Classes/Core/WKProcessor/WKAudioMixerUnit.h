//
//  WKAudioMixerUnit.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKAudioFrame.h"
#import "WKCapacity.h"

@interface WKAudioMixerUnit : NSObject

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
- (BOOL)putFrame:(WKAudioFrame *)frame;

/**
 *
 */
- (NSArray<WKAudioFrame *> *)framesToEndTime:(CMTime)endTime;

/**
 *
 */
- (WKCapacity)capacity;

/**
 *
 */
- (void)flush;

@end
