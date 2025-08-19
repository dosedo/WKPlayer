//
//  WKPLFImage.h
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPLFObject.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>

#if WKPLATFORM_TARGET_OS_MAC

typedef NSImage WKPLFImage;

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

typedef UIImage WKPLFImage;

#endif

WKPLFImage * WKPLFImageWithCGImage(CGImageRef image);

// CVPixelBufferRef
WKPLFImage * WKPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer);
CIImage * WKPLFImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer);
CGImageRef WKPLFImageCGImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer);

// RGB data buffer
WKPLFImage * WKPLFImageWithRGBData(uint8_t *rgb_data, int linesize, int width, int height);
CGImageRef WKPLFImageCGImageWithRGBData(uint8_t *rgb_data, int linesize, int width, int height);
