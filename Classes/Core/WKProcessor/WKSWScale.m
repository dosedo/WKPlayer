//
//  WKSWScale.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKSWScale.h"
#import "WKFFmpeg.h"

@interface WKSWScale ()

@property (nonatomic, readonly) struct SwsContext *context;

@end

@implementation WKSWScale

+ (BOOL)isSupportedInputFormat:(int)format
{
    return sws_isSupportedInput(format) > 0;
}

+ (BOOL)isSupportedOutputFormat:(int)format
{
    return sws_isSupportedOutput(format) > 0;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_flags = SWS_FAST_BILINEAR;
    }
    return self;
}

- (void)dealloc
{
    if (self->_context) {
        sws_freeContext(self->_context);
        self->_context = nil;
    }
}

- (BOOL)open
{
    if (!self->_inputDescriptor ||
        !self->_outputDescriptor) {
        return NO;
    }
    self->_context = sws_getCachedContext(self->_context,
                                          self->_inputDescriptor.width,
                                          self->_inputDescriptor.height,
                                          self->_inputDescriptor.format,
                                          self->_outputDescriptor.width,
                                          self->_outputDescriptor.height,
                                          self->_outputDescriptor.format,
                                          self->_flags,
                                          NULL, NULL, NULL);
    return self->_context ? YES : NO;
}

- (int)convert:(const uint8_t *const [])inputData inputLinesize:(const int [])inputLinesize outputData:(uint8_t *const [])outputData outputLinesize:(const int [])outputLinesize
{
    return sws_scale(self->_context,
                     inputData,
                     inputLinesize,
                     0,
                     self->_inputDescriptor.height,
                     outputData,
                     outputLinesize);
}

@end
