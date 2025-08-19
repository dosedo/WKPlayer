//
//  WKSWScale.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKVideoDescriptor.h"

@interface WKSWScale : NSObject

/**
 *
 */
+ (BOOL)isSupportedInputFormat:(int)format;

/**
 *
 */
+ (BOOL)isSupportedOutputFormat:(int)format;

/**
 *
 */
@property (nonatomic, copy) WKVideoDescriptor *inputDescriptor;

/**
 *
 */
@property (nonatomic, copy) WKVideoDescriptor *outputDescriptor;

/**
 *
 */
@property (nonatomic) int flags;          // SWS_FAST_BILINEAR

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)convert:(const uint8_t * const [])inputData inputLinesize:(const int[])inputLinesize outputData:(uint8_t * const [])outputData outputLinesize:(const int[])outputLinesize;

@end
