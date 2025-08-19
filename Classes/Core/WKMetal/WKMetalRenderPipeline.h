//
//  WKMetalRenderPipeline.h
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Metal/Metal.h>

@interface WKMetalRenderPipeline : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLRenderPipelineState> state;
@property (nonatomic, strong) MTLRenderPipelineDescriptor *descriptor;

@end
