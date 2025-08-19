//
//  WKSWResample.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKAudioDescriptor.h"

@interface WKSWResample : NSObject

/**
 *
 */
@property (nonatomic, copy) WKAudioDescriptor *inputDescriptor;
@property (nonatomic, copy) WKAudioDescriptor *outputDescriptor;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 *
 */
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 *
 */
- (int)delay;

@end
