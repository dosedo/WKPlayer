//
//  WKAudioFrame.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKFrame.h"
#import "WKAudioDescriptor.h"

@interface WKAudioFrame : WKFrame

/**
 *
 */
@property (nonatomic, strong, readonly) WKAudioDescriptor *descriptor;

/**
 *
 */
@property (nonatomic, readonly) int numberOfSamples;

/**
 *
 */
- (int *)linesize;

/**
 *
 */
- (uint8_t **)data;

@end
