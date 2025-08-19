//
//  WKMetalRenderPipelinePool.m
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalRenderPipelinePool.h"
#import "WKMetalYUVRenderPipeline.h"
#import "WKMetalNV12RenderPipeline.h"
#import "WKMetalBGRARenderPipeline.h"

#import "WKPLFTargets.h"
#if WKPLATFORM_TARGET_OS_IPHONE
#import "WKMetalShader_iOS.h"
#elif WKPLATFORM_TARGET_OS_TV
#import "WKMetalShader_tvOS.h"
#elif WKPLATFORM_TARGET_OS_MAC
#import "WKMetalShader_macOS.h"
#endif

@interface WKMetalRenderPipelinePool ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) WKMetalRenderPipeline *yuv;
@property (nonatomic, strong) WKMetalRenderPipeline *nv12;
@property (nonatomic, strong) WKMetalRenderPipeline *bgra;

@end

@implementation WKMetalRenderPipelinePool

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
        self.library = [device newLibraryWithData:dispatch_data_create(metallib, sizeof(metallib), dispatch_get_global_queue(0, 0), ^{}) error:NULL];
    }
    return self;
}

- (WKMetalRenderPipeline *)pipelineWithCVPixelFormat:(OSType)pixpelFormat
{
    if (pixpelFormat == kCVPixelFormatType_420YpCbCr8Planar) {
        return self.yuv;
    } else if (pixpelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        return self.nv12;
    } else if (pixpelFormat == kCVPixelFormatType_32BGRA) {
        return self.bgra;
    }
    return nil;
}

- (WKMetalRenderPipeline *)pipelineWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return [self pipelineWithCVPixelFormat:CVPixelBufferGetPixelFormatType(pixelBuffer)];
}

- (WKMetalRenderPipeline *)yuv
{
    if (_yuv == nil) {
        _yuv = [[WKMetalYUVRenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _yuv;
}

- (WKMetalRenderPipeline *)nv12
{
    if (_nv12 == nil) {
        _nv12 = [[WKMetalNV12RenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _nv12;
}

- (WKMetalRenderPipeline *)bgra
{
    if (_bgra == nil) {
        _bgra = [[WKMetalBGRARenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _bgra;
}

@end
