//
//  WKMetalRenderer.m
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalRenderer.h"
#import "WKMetalTypes.h"

@interface WKMetalRenderer ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;

@end

@implementation WKMetalRenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
        self.commandQueue = [self.device newCommandQueue];
        self.renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
        self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        self.renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
    return self;
}

- (id<MTLCommandBuffer>)drawModel:(WKMetalModel *)model
                        viewports:(MTLViewport[])viewports
                         pipeline:(WKMetalRenderPipeline *)pipeline
                      projections:(NSArray<WKMetalProjection *> *)projections
                    inputTextures:(NSArray<id<MTLTexture>> *)inputTextures
                    outputTexture:(id<MTLTexture>)outputTexture
{
    self.renderPassDescriptor.colorAttachments[0].texture = outputTexture;
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
    [encoder setCullMode:MTLCullModeNone];
    [encoder setRenderPipelineState:pipeline.state];
    [encoder setVertexBuffer:model.vertexBuffer offset:0 atIndex:0];
    for (NSUInteger i = 0; i < inputTextures.count; i++) {
        [encoder setFragmentTexture:inputTextures[i] atIndex:i];
    }
    for (NSUInteger i = 0; i < projections.count; i++) {
        [encoder setViewport:viewports[i]];
        [encoder setVertexBuffer:projections[i].matrixBuffer offset:0 atIndex:1];
        [encoder drawIndexedPrimitives:model.primitiveType
                            indexCount:model.indexCount
                             indexType:model.indexType
                           indexBuffer:model.indexBuffer
                     indexBufferOffset:0];
    }
    [encoder endEncoding];
    return commandBuffer;
}

@end
