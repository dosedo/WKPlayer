//
//  WKFrame+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKFrame.h"
#import "WKAudioFrame.h"
#import "WKVideoFrame.h"
#import "WKCodecDescriptor.h"

@interface WKFrame ()

/**
 *
 */
+ (instancetype)frame;

/**
 *
 */
@property (nonatomic, readonly) AVFrame *core;

/**
 *
 */
@property (nonatomic, strong) WKCodecDescriptor *codecDescriptor;

/**
 *
 */
- (void)fill;

/**
 *
 */
- (void)fillWithFrame:(WKFrame *)frame;

/**
 *
 */
- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration;

@end

@interface WKAudioFrame ()

/**
 *
 */
+ (instancetype)frameWithDescriptor:(WKAudioDescriptor *)descriptor numberOfSamples:(int)numberOfSamples;

@end

@interface WKVideoFrame ()

/**
 *
 */
+ (instancetype)frameWithDescriptor:(WKVideoDescriptor *)descriptor;

@end
