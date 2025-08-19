//
//  WKVRViewport.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKVRViewport.h"

@implementation WKVRViewport

- (instancetype)init
{
    if (self = [super init]) {
        self.degress = 60;
        self.x = 0;
        self.y = 0;
        self.flipX = NO;
        self.flipY = NO;
        self.sensorEnable = YES;
    }
    return self;
}

@end
