//
//  WKMetalPlaneModel.m
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalPlaneModel.h"
#import "WKMetalTypes.h"

@implementation WKMetalPlaneModel

static const UInt32 indices[] = {
    0, 1, 3, 0, 3, 2,
};

static const WKMetalVertex vertices[] = {
    { { -1.0,  -1.0,  0.0,  1.0 }, { 0.0, 1.0 } },
    { { -1.0,   1.0,  0.0,  1.0 }, { 0.0, 0.0 } },
    { {  1.0,  -1.0,  0.0,  1.0 }, { 1.0, 1.0 } },
    { {  1.0,   1.0,  0.0,  1.0 }, { 1.0, 0.0 } },
};

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super initWithDevice:device]) {
        self.indexCount = 6;
        self.indexType = MTLIndexTypeUInt32;
        self.primitiveType = MTLPrimitiveTypeTriangle;
        self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];
        self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
    }
    return self;
}

@end
