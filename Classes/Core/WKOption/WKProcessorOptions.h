//
//  WKProcessorOptions.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKProcessorOptions : NSObject <NSCopying>

/*!
 @property audioClass
 @abstract
    The audio frame processor class.
    Default is WKAudioProcessor.
 */
@property (nonatomic, copy) Class audioClass;

/*!
 @property videoClass
 @abstract
    The video frame processor class.
    Default is WKVideoProcessor.
 */
@property (nonatomic, copy) Class videoClass;

@end
