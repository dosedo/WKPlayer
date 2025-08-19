//
//  WKMetalRenderer.h
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <simd/simd.h>
#import <Metal/Metal.h>
#import "WKMetalModel.h"
#import "WKMetalProjection.h"
#import "WKMetalRenderPipeline.h"

@interface WKMetalRenderer : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (id<MTLCommandBuffer>)drawModel:(WKMetalModel *)model
                        viewports:(MTLViewport[])viewports
                         pipeline:(WKMetalRenderPipeline *)pipeline
                      projections:(NSArray<WKMetalProjection *> *)projections
                    inputTextures:(NSArray<id<MTLTexture>> *)inputTextures
                    outputTexture:(id<MTLTexture>)outputTexture;

@end
