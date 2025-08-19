//
//  WKProcessorOptions.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKProcessorOptions.h"
#import "WKAudioProcessor.h"
#import "WKVideoProcessor.h"

@implementation WKProcessorOptions

- (id)copyWithZone:(NSZone *)zone
{
    WKProcessorOptions *obj = [[WKProcessorOptions alloc] init];
    obj->_audioClass = self->_audioClass.copy;
    obj->_videoClass = self->_videoClass.copy;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_audioClass = [WKAudioProcessor class];
        self->_videoClass = [WKVideoProcessor class];
    }
    return self;
}

@end
