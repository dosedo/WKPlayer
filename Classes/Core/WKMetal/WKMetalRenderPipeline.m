//
//  WKMetalRenderPipeline.m
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalRenderPipeline.h"

@implementation WKMetalRenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library
{
    if (self = [super init]) {
        self.device = device;
        self.library = library;
    }
    return self;
}

@end

