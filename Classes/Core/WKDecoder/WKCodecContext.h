//
//  WKCodecContext.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKCodecDescriptor.h"
#import "WKDecoderOptions.h"
#import "WKPacket.h"
#import "WKFrame.h"

@interface WKCodecContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTimebase:(AVRational)timebase
                        codecpar:(AVCodecParameters *)codecpar
                  frameGenerator:(__kindof WKFrame *(^)(void))frameGenerator;

/**
 *
 */
@property (nonatomic, strong) WKDecoderOptions *options;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (void)close;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (NSArray<__kindof WKFrame *> *)decode:(WKPacket *)packet;

@end
