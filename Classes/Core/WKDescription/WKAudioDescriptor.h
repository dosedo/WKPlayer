//
//  WKAudioDescriptor.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKAudioDescriptor : NSObject <NSCopying>

/*!
 @property format
 @abstract
    Indicates the audio format.
 
 @discussion
    The value corresponds to AVSampleFormat.
 */
@property (nonatomic) int format;

/*!
 @property sampleRate
 @abstract
    Indicates the sample rate.
 */
@property (nonatomic) int sampleRate;

/*!
 @property numberOfChannels
 @abstract
    Indicates the channel count.
 */
@property (nonatomic) int numberOfChannels;

/*!
 @method isPlanar
 @abstract
    Get whether the sample format is planar.
 */
- (BOOL)isPlanar;

/*!
 @method bytesPerSample
 @abstract
    Get the bytes per sample.
 */
- (int)bytesPerSample;

/*!
 @method numberOfPlanes
 @abstract
    Get the number of planes.
 */
- (int)numberOfPlanes;

/*!
 @method linesize:
 @abstract
    Get the linesize of the number of samples.
 */
- (int)linesize:(int)numberOfSamples;

/*!
 @method isEqualToDescriptor:
 @abstract
    Check if the descriptor is equal to another.
 */
- (BOOL)isEqualToDescriptor:(WKAudioDescriptor *)descriptor;

@end
