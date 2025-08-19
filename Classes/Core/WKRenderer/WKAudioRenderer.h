//
//  WKAudioRenderer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKAudioDescriptor.h"

@interface WKAudioRenderer : NSObject

/*!
 @method supportedAudioDescriptor
 @abstract
    Indicates all supported audio descriptor.
*/
+ (WKAudioDescriptor *)supportedAudioDescriptor;

/*!
 @property pitch
 @abstract
    Indicates the current pitch.
 */
@property (nonatomic) Float64 pitch;

/*!
 @property volume
 @abstract
    Indicates the current volume.
 */
@property (nonatomic) Float64 volume;

@end
