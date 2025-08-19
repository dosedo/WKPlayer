//
//  WKRenderer+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKClock.h"
#import "WKDefines.h"

@protocol WKClockDelegate;

@interface WKClock ()

/**
 *
 */
@property (nonatomic, weak) id<WKClockDelegate> delegate;

/**
 *
 */
@property (nonatomic) Float64 rate;

/**
 *
 */
@property (nonatomic, readonly) CMTime currentTime;

/**
 *
 */
- (void)setAudioTime:(CMTime)time running:(BOOL)running;

/**
 *
 */
- (void)setVideoTime:(CMTime)time;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

@end

@protocol WKClockDelegate <NSObject>

/**
 *
 */
- (void)clock:(WKClock *)clock didChcnageCurrentTime:(CMTime)currentTime;

@end
