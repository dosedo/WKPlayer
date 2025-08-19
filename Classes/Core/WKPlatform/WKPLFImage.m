//
//  WKPLFImage.m
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPLFImage.h"

#if WKPLATFORM_TARGET_OS_MAC

WKPLFImage * WKPLFImageWithCGImage(CGImageRef image)
{
    return [[NSImage alloc] initWithCGImage:image size:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))];
}

WKPLFImage * WKPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage *ciImage = WKPLFImageCIImageWithCVPexelBuffer(pixelBuffer);
    if (!ciImage) return nil;
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:ciImage];
    NSImage *image = [[NSImage alloc] initWithSize:imageRep.size];
    [image addRepresentation:imageRep];
    return image;
}

CIImage * WKPLFImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    if (@available(macOS 10.11, *)) {
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        return image;
    } else {
        return nil;
    }
}

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

WKPLFImage * WKPLFImageWithCGImage(CGImageRef image)
{
    return [UIImage imageWithCGImage:image];
}

WKPLFImage * WKPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage *ciImage = WKPLFImageCIImageWithCVPexelBuffer(pixelBuffer);
    if (!ciImage) return nil;
    return [UIImage imageWithCIImage:ciImage];
}

CIImage * WKPLFImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    return image;
}

#endif

CGImageRef WKPLFImageCGImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t count = CVPixelBufferGetPlaneCount(pixelBuffer);
    if (count > 1) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return nil;
    }

    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return imageRef;
}

WKPLFImage * WKPLFImageWithRGBData(uint8_t *rgb_data, int linesize, int width, int height)
{
    CGImageRef imageRef = WKPLFImageCGImageWithRGBData(rgb_data, linesize, width, height);
    if (!imageRef) return nil;
    WKPLFImage *image = WKPLFImageWithCGImage(imageRef);
    CGImageRelease(imageRef);
    return image;
}

CGImageRef WKPLFImageCGImageWithRGBData(uint8_t *rgb_data, int linesize, int width, int height)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, rgb_data, linesize * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       linesize,
                                       colorSpace,
                                       kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return imageRef;
}

