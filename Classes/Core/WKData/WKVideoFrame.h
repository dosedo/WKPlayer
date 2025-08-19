//
//  WKVideoFrame.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKFrame.h"
#import "WKPLFImage.h"
#import "WKVideoDescriptor.h"

@interface WKVideoFrame : WKFrame

/**
 *
 */
@property (nonatomic, strong, readonly) WKVideoDescriptor *descriptor;

/**
 *
 */
- (int *)linesize;

/**
 *
 */
- (uint8_t **)data;

/**
 *
 */
- (CVPixelBufferRef)pixelBuffer;

/**
 *
 */
- (WKPLFImage *)image;

@end
