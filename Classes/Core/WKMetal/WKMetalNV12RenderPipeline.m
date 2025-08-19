//
//  WKMetalNV12RenderPipeline.m
//  Metal
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalNV12RenderPipeline.h"

@implementation WKMetalNV12RenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library
{
    if (self = [super initWithDevice:device library:library]) {
        self.descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        self.descriptor.vertexFunction = [self.library newFunctionWithName:@"vertexShader"];
        self.descriptor.fragmentFunction = [self.library newFunctionWithName:@"fragmentShaderNV12"];
        self.descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.state = [self.device newRenderPipelineStateWithDescriptor:self.descriptor error:nil];
    }
    return self;
}

@end
