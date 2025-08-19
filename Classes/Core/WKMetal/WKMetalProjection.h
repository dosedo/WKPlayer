//
//  WKMetalProjection.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Metal/Metal.h>
#import <GLKit/GLKit.h>

@interface WKMetalProjection : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@property (nonatomic) GLKMatrix4 matrix;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLBuffer> matrixBuffer;

@end
