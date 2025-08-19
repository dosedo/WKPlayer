//
//  WKMetalRenderPipelinePool.h
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKMetalRenderPipeline.h"
#import <CoreVideo/CoreVideo.h>

@interface WKMetalRenderPipelinePool : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (WKMetalRenderPipeline *)pipelineWithCVPixelFormat:(OSType)pixpelFormat;
- (WKMetalRenderPipeline *)pipelineWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
