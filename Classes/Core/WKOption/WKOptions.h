//
//  WKOptions.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKProcessorOptions.h"
#import "WKDecoderOptions.h"
#import "WKDemuxerOptions.h"

@interface WKOptions : NSObject <NSCopying>

/*!
 @method sharedOptions
 @abstract
    Globally shared configuration options.
 */
+ (instancetype)sharedOptions;

/*!
 @property demuxer
 @abstract
    The options for demuxer.
 */
@property (nonatomic, strong) WKDemuxerOptions *demuxer;

/*!
 @property decoder
 @abstract
    The options for decoder.
 */
@property (nonatomic, strong) WKDecoderOptions *decoder;

/*!
 @property processor
 @abstract
    The options for processor.
 */
@property (nonatomic, strong) WKProcessorOptions *processor;

@end
