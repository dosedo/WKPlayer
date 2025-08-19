//
//  WKMetalTextureLoader.h
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>

@interface WKMetalTextureLoader : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (NSArray<id<MTLTexture>> *)texturesWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (NSArray<id<MTLTexture>> *)texturesWithCVPixelFormat:(OSType)pixelFormat
                                                 width:(NSUInteger)width
                                                height:(NSUInteger)height
                                                 bytes:(void **)bytes
                                           bytesPerRow:(int *)bytesPerRow;

- (id<MTLTexture>)textureWithPixelFormat:(MTLPixelFormat)pixelFormat
                                   width:(NSUInteger)width
                                  height:(NSUInteger)height
                                   bytes:(void *)bytes
                             bytesPerRow:(NSUInteger)bytesPerRow;

@end
