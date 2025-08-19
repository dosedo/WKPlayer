//
//  WKMetalProjection.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalProjection.h"
#import "WKMetalTypes.h"

@implementation WKMetalProjection

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
        self.matrixBuffer = [device newBufferWithLength:sizeof(WKMetalMatrix) options:MTLResourceStorageModeShared];
    }
    return self;
}

- (void)setMatrix:(GLKMatrix4)matrix
{
    self->_matrix = matrix;
    ((WKMetalMatrix *)self.matrixBuffer.contents)->mvp = WKMatrixFloat4x4FromGLKMatrix4(matrix);
}

static matrix_float4x4 WKMatrixFloat4x4FromGLKMatrix4(GLKMatrix4 matrix)
{
    return (matrix_float4x4){{
        {matrix.m00, matrix.m01, matrix.m02, matrix.m03},
        {matrix.m10, matrix.m11, matrix.m12, matrix.m13},
        {matrix.m20, matrix.m21, matrix.m22, matrix.m23},
        {matrix.m30, matrix.m31, matrix.m32, matrix.m33}}};
}

@end
