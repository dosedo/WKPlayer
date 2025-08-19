//
//  WKRenderTimer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKRenderTimer.h"

@interface WKRenderTimer ()

@property (nonatomic, copy) dispatch_block_t handler;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation WKRenderTimer

- (instancetype)initWithHandler:(dispatch_block_t)handler
{
    if (self = [super init]) {
        self.handler = handler;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)timerHandler
{
    if (self.handler) {
        self.handler();
    }
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval
{
    if (self->_timeInterval != timeInterval) {
        self->_timeInterval = timeInterval;
        [self start];
    }
}

- (void)setPaused:(BOOL)paused
{
    if (self->_paused != paused) {
        self->_paused = paused;
        [self fire];
    }
}

- (void)start
{
    [self stop];
    self->_timer = [NSTimer timerWithTimeInterval:self->_timeInterval
                                           target:self
                                         selector:@selector(timerHandler)
                                         userInfo:nil
                                          repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self->_timer
                              forMode:NSRunLoopCommonModes];
    [self fire];
}

- (void)stop
{
    [self->_timer invalidate];
    self->_timer = nil;
}

- (void)fire
{
    self->_timer.fireDate =
    self->_paused ?
    [NSDate distantFuture] :
    [NSDate distantPast];
}

@end
