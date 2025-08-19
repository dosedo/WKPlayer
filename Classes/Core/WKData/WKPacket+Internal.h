//
//  WKPacket+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPacket.h"
#import "WKCodecDescriptor.h"

@interface WKPacket ()

/**
 *
 */
+ (instancetype)packet;

/**
 *
 */
@property (nonatomic, readonly) AVPacket *core;

/**
 *
 */
@property (nonatomic, strong) WKCodecDescriptor *codecDescriptor;

/**
 *
 */
- (void)fill;

@end
