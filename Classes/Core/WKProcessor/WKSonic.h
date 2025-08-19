//
//  WKSonic.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKAudioDescriptor.h"

@interface WKSonic : NSObject

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDescriptor:(WKAudioDescriptor *)descriptor;

/**
 *
 */
@property (nonatomic, copy, readonly) WKAudioDescriptor *descriptor;

/**
 *
 */
@property (nonatomic) float speed;

/**
 *
 */
@property (nonatomic) float pitch;

/**
 *
 */
@property (nonatomic) float rate;

/**
 *
 */
@property (nonatomic) float volume;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)flush;

/**
 *
 */
- (int)samplesInput;

/**
 *
 */
- (int)samplesAvailable;

/**
 *
 */
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 *
 */
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

@end
