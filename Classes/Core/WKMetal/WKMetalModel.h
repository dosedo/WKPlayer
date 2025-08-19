//
//  WKMetalModel.h
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Metal/Metal.h>

@interface WKMetalModel : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@property (nonatomic) NSUInteger indexCount;
@property (nonatomic) MTLIndexType indexType;
@property (nonatomic) MTLPrimitiveType primitiveType;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end
