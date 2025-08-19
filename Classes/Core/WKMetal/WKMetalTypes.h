//
//  WKMetalTypes.h
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#ifndef WKMetalTypes_h
#define WKMetalTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float4 position;
    vector_float2 texCoord;
} WKMetalVertex;

typedef struct {
    matrix_float4x4 mvp;
} WKMetalMatrix;

#endif /* WKMetalTypes_h */
