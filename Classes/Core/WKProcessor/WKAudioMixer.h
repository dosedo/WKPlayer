//
//  WKAudioMixer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKAudioDescriptor.h"
#import "WKAudioFrame.h"
#import "WKCapacity.h"

@interface WKAudioMixer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTracks:(NSArray<WKTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<WKTrack *> *tracks;

/**
 *
 */
@property (nonatomic, copy) NSArray<NSNumber *> *weights;

/**
 *
 */
- (WKAudioFrame *)putFrame:(WKAudioFrame *)frame;

/**
 *
 */
- (WKAudioFrame *)finish;

/**
 *
 */
- (WKCapacity)capacity;

/**
 *
 */
- (void)flush;

@end
