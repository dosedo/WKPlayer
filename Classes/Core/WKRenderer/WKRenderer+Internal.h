//
//  WKRenderer+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKRenderable.h"
#import "WKAudioDescriptor.h"
#import "WKAudioRenderer.h"
#import "WKVideoRenderer.h"
#import "WKClock+Internal.h"

@class WKAudioFormatter;

@interface WKAudioRenderer () <WKRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithClock:(WKClock *)clock;

/**
 *
 */
@property (nonatomic) Float64 rate;

/**
 *
 */
@property (nonatomic, copy, readonly) WKAudioDescriptor *descriptor;

@end

@interface WKVideoRenderer () <WKRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithClock:(WKClock *)clock;

/**
 *
 */
@property (nonatomic) Float64 rate;

@end
