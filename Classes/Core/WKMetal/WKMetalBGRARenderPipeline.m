//
//  WKMetalBGRARenderPipeline.m
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalBGRARenderPipeline.h"

@implementation WKMetalBGRARenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library
{
    if (self = [super initWithDevice:device library:library]) {
        self.descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        self.descriptor.vertexFunction = [self.library newFunctionWithName:@"vertexShader"];
        self.descriptor.fragmentFunction = [self.library newFunctionWithName:@"fragmentShaderBGRA"];
        self.descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.state = [self.device newRenderPipelineStateWithDescriptor:self.descriptor error:nil];
    }
    return self;
}

@end
