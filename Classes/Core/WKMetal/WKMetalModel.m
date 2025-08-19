//
//  WKMetalModel.m
//  MetalTest
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalModel.h"

@implementation WKMetalModel

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
    }
    return self;
}

@end
