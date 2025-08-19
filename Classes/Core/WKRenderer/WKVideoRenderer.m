//
//  WKVideoRenderer.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKVideoRenderer.h"
#import "WKRenderer+Internal.h"
#import "WKVRProjection.h"
#import "WKRenderTimer.h"
#import "WKOptions.h"
#import "WKMapping.h"
#import "WKMetal.h"
#import "WKMacro.h"
#import "WKLock.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/ImageIO.h>
#import <ImageIO/CGImageProperties.h>
#import "WKSampleBufferDisplayView.h"

@interface WKVideoRenderer () <MTKViewDelegate>

{
    struct {
        WKRenderableState state;
        BOOL hasNewFrame;
        NSUInteger framesFetched;
        NSUInteger framesDisplayed;
        NSTimeInterval currentFrameEndTime;
        NSTimeInterval currentFrameBeginTime;
    } _flags;
    WKCapacity _capacity;
    
    //支持 AVSampleBufferDisplayLayer
    CMTimebaseRef _timebase;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) WKClock *clock;
@property (nonatomic, strong, readonly) WKRenderTimer *fetchTimer;
@property (nonatomic, strong, readonly) WKVideoFrame *currentFrame;
@property (nonatomic, strong, readonly) WKVRProjection *matrixMaker;

@property (nonatomic, strong, readonly) MTKView *metalView;
@property (nonatomic, strong, readonly) WKMetalModel *planeModel;
@property (nonatomic, strong, readonly) WKMetalModel *sphereModel;
@property (nonatomic, strong, readonly) WKMetalRenderer *renderer;
@property (nonatomic, strong, readonly) WKMetalProjection *projection1;
@property (nonatomic, strong, readonly) WKMetalProjection *projection2;
@property (nonatomic, strong, readonly) WKMetalRenderPipeline *pipeline;
@property (nonatomic, strong, readonly) WKMetalTextureLoader *textureLoader;
@property (nonatomic, strong, readonly) WKMetalRenderPipelinePool *pipelinePool;


//支持 AVSampleBufferDisplayLayer
@property (nonatomic, strong, readonly) WKSampleBufferDisplayView *displayView;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property (nonatomic, assign) NSInteger currentRotation;

@end

@implementation WKVideoRenderer

@synthesize rate = _rate;
@synthesize delegate = _delegate;
@synthesize displayLayer = _displayLayer;
@synthesize displayView = _displayView;

+ (NSArray<NSNumber *> *)supportedPixelFormats
{
    return @[
        @(AV_PIX_FMT_BGRA),
        @(AV_PIX_FMT_NV12),
        @(AV_PIX_FMT_YUV420P),
    ];
}

+ (BOOL)isSupportedPixelFormat:(int)format
{
    for (NSNumber *obj in [self supportedPixelFormats]) {
        if (format == obj.intValue) {
            return YES;
        }
    }
    return NO;
}

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithClock:(WKClock *)clock
{
    if (self = [super init]) {
        self->_clock = clock;
        self->_rate = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_capacity = WKCapacityCreate();
        self->_preferredFramesPerSecond = 30;
        self->_displayMode = WKDisplayModePlane;
        self->_scalingMode = WKScalingModeResizeAspect;
        self->_matrixMaker = [[WKVRProjection alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self performSelectorOnMainThread:@selector(destoryDrawingLoop)
                           withObject:nil
                        waitUntilDone:YES];
    [self->_currentFrame unlock];
    self->_currentFrame = nil;
}

#pragma mark - Setter & Getter

- (WKBlock)setState:(WKRenderableState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate renderable:self didChangeState:state];
    };
}

- (WKRenderableState)state
{
    __block WKRenderableState ret = WKRenderableStateNone;
    WKLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (WKCapacity)capacity
{
    __block WKCapacity ret;
    WKLockEXE00(self->_lock, ^{
        ret = self->_capacity;
    });
    return ret;
}

- (void)setRate:(Float64)rate
{
    WKLockEXE00(self->_lock, ^{
        self->_rate = rate;
        
        // 立即更新时间基准速率（如果正在播放）
        if( self->_displayLayer != nil ) {
            if (self->_timebase && self->_flags.state == WKRenderableStateRendering) {
                CMTimebaseSetRate(self->_timebase, rate);
            }
        }
    });
}

- (Float64)rate
{
    __block Float64 ret = 1.0;
    WKLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (WKVRViewport *)viewport
{
    return self->_matrixMaker.viewport;
}

- (WKPLFImage *)currentImage
{
    __block WKPLFImage *ret = nil;
    WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_currentFrame != nil;
    }, ^WKBlock {
        WKVideoFrame *frame = self->_currentFrame;
        [frame lock];
        return ^{
            ret = [frame image];
            [frame unlock];
        };
    }, ^BOOL(WKBlock block) {
        block();
        return YES;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == WKRenderableStateNone;
    }, ^WKBlock {
        return [self setState:WKRenderableStatePaused];
    }, ^BOOL(WKBlock block) {
        block();
        [self performSelectorOnMainThread:@selector(setupDrawingLoop)
                               withObject:nil
                            waitUntilDone:YES];
        return YES;
    });
}

- (BOOL)close
{
    return WKLockEXE11(self->_lock, ^WKBlock {
        WKBlock b1 = [self setState:WKRenderableStateNone];
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.hasNewFrame = NO;
        self->_flags.framesFetched = 0;
        self->_flags.framesDisplayed = 0;
        self->_flags.currentFrameEndTime = 0;
        self->_flags.currentFrameBeginTime = 0;
        self->_capacity = WKCapacityCreate();
        return ^{b1();};
    }, ^BOOL(WKBlock block) {
        [self performSelectorOnMainThread:@selector(destoryDrawingLoop)
                               withObject:nil
                            waitUntilDone:YES];
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == WKRenderableStateRendering ||
        self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock {
        return [self setState:WKRenderableStatePaused];
    }, ^BOOL(WKBlock block) {
        
        // 暂停时间基准
        if (self->_timebase) {
            CMTimebaseSetRate(self->_timebase, 0.0); // 速率设为0
        }
        
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)resume
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == WKRenderableStatePaused ||
        self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock {
        return [self setState:WKRenderableStateRendering];
    }, ^BOOL(WKBlock block) {
        
        // 恢复时间基准速率
        if (self->_timebase) {
            CMTimebaseSetRate(self->_timebase, self.rate);
        }
        
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)flush
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == WKRenderableStatePaused ||
        self->_flags.state == WKRenderableStateRendering ||
        self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock {
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.hasNewFrame = NO;
        self->_flags.framesFetched = 0;
        self->_flags.framesDisplayed = 0;
        self->_flags.currentFrameEndTime = 0;
        self->_flags.currentFrameBeginTime = 0;
        return nil;
    }, ^BOOL(WKBlock block) {
        
        if( self->_displayLayer != nil ){
            [self.displayLayer flush];
            [self setupTimebase];
        }
        
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

- (BOOL)finish
{
    return WKLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == WKRenderableStateRendering ||
        self->_flags.state == WKRenderableStatePaused;
    }, ^WKBlock {
        return [self setState:WKRenderableStateFinished];
    }, ^BOOL(WKBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.paused = NO;
        return YES;
    });
}

#pragma mark - Fecth

- (void)fetchTimerHandler
{
    BOOL shouldFetch = NO;
    BOOL shouldPause = NO;
    [self->_lock lock];
    if (self->_flags.state == WKRenderableStateRendering ||
        (self->_flags.state == WKRenderableStatePaused &&
         self->_flags.framesFetched == 0)) {
        shouldFetch = YES;
    } else if (self->_flags.state != WKRenderableStateRendering) {
        shouldPause = YES;
    }
    [self->_lock unlock];
    if (shouldPause) {
        self->_fetchTimer.paused = YES;
    }
    if (!shouldFetch) {
        return;
    }
    __block NSUInteger framesFetched = 0;
    __block NSTimeInterval currentMediaTime = CACurrentMediaTime();
    WKWeakify(self)
    WKVideoFrame *newFrame = [self->_delegate renderable:self fetchFrame:^BOOL(CMTime *desire, BOOL *drop) {
        WKStrongify(self)
        return WKLockCondEXE10(self->_lock, ^BOOL {
            framesFetched = self->_flags.framesFetched;
            return self->_currentFrame && framesFetched != 0;
        }, ^WKBlock {
            return ^{
                currentMediaTime = CACurrentMediaTime();
                *desire = self->_clock.currentTime;
                *drop = YES;
            };
        });
    }];
    
    if( newFrame ) {
        ///支持 AVSampleBufferDisplayLayer
        [self resetRenderView:newFrame];
        
        if( _displayLayer != nil ) {
            [self enqueueFrame:newFrame];
        }
    }
    
    WKLockCondEXE10(self->_lock, ^BOOL {
        return !newFrame || framesFetched == self->_flags.framesFetched;
    }, ^WKBlock {
        WKBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        WKCapacity capacity = WKCapacityCreate();
        if (newFrame) {
            [newFrame lock];
            CMTime time = newFrame.timeStamp;
            CMTime duration = CMTimeMultiplyByFloat64(newFrame.duration, self->_rate);
            capacity.duration = duration;
            [self->_currentFrame unlock];
            self->_currentFrame = newFrame;
            self->_flags.hasNewFrame = YES;
            self->_flags.framesFetched += 1;
            self->_flags.currentFrameBeginTime = currentMediaTime;
            self->_flags.currentFrameEndTime = currentMediaTime + CMTimeGetSeconds(duration);
            if (self->_frameOutput) {
                [newFrame lock];
                b1 = ^{
                    self->_frameOutput(newFrame);
                    [newFrame unlock];
                };
            }
            b2 = ^{
                [self->_clock setVideoTime:time];
            };
        } else if (currentMediaTime < self->_flags.currentFrameEndTime) {
            CMTime time = self->_currentFrame.timeStamp;
            time = CMTimeAdd(time, WKCMTimeMakeWithSeconds(currentMediaTime - self->_flags.currentFrameBeginTime));
            capacity.duration = WKCMTimeMakeWithSeconds(self->_flags.currentFrameEndTime - currentMediaTime);
            b2 = ^{
                [self->_clock setVideoTime:time];
            };
        }
        if (!WKCapacityIsEqual(self->_capacity, capacity)) {
            self->_capacity = capacity;
            b3 = ^{
                [self->_delegate renderable:self didChangeCapacity:capacity];
            };
        }
        return ^{b1(); b2(); b3();};
    });
    [newFrame unlock];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view
{
    if (!view.superview ||
        (view.frame.size.width <= 1 &&
         view.frame.size.height <= 1)) {
        return;
    }
    [self->_lock lock];
    WKVideoFrame *frame = self->_currentFrame;
    WKRational presentationSize = frame.descriptor.presentationSize;
    if (!frame ||
        presentationSize.num == 0 ||
        presentationSize.den == 0) {
        [self->_lock unlock];
        return;
    }
    BOOL shouldDraw = NO;
    if (self->_flags.hasNewFrame ||
        self->_flags.framesDisplayed == 0 ||
        (self->_displayMode == WKDisplayModeVR ||
         self->_displayMode == WKDisplayModeVRBox)) {
            shouldDraw = YES;
    }
    if (!shouldDraw) {
        BOOL shouldPause = self->_flags.state != WKRenderableStateRendering;
        [self->_lock unlock];
        if (shouldPause) {
            self->_metalView.paused = YES;
        }
        return;
    }
    NSUInteger framesFetched = self->_flags.framesFetched;
    [frame lock];
    [self->_lock unlock];
    WKDisplayMode displayMode = self->_displayMode;
    WKMetalModel *model = displayMode == WKDisplayModePlane ? self->_planeModel : self->_sphereModel;
    WKMetalRenderPipeline *pipeline = [self->_pipelinePool pipelineWithCVPixelFormat:frame.descriptor.cv_format];
    if (!model || !pipeline) {
        [frame unlock];
        return;
    }
    GLKMatrix4 baseMatrix = GLKMatrix4Identity;
    NSInteger rotate = [frame.metadata[@"rotate"] integerValue];
    if (rotate && (rotate % 90) == 0) {
        float radians = GLKMathDegreesToRadians(-rotate);
        baseMatrix = GLKMatrix4RotateZ(baseMatrix, radians);
        WKRational size = {
            presentationSize.num * ABS(cos(radians)) + presentationSize.den * ABS(sin(radians)),
            presentationSize.num * ABS(sin(radians)) + presentationSize.den * ABS(cos(radians)),
        };
        presentationSize = size;
    }
    NSArray<id<MTLTexture>> *textures = nil;
    if (frame.pixelBuffer) {
        textures = [self->_textureLoader texturesWithCVPixelBuffer:frame.pixelBuffer];
    } else {
        textures = [self->_textureLoader texturesWithCVPixelFormat:frame.descriptor.cv_format
                                                             width:frame.descriptor.width
                                                            height:frame.descriptor.height
                                                             bytes:(void **)frame.data
                                                       bytesPerRow:frame.linesize];
    }
    [frame unlock];
    if (!textures.count) {
        return;
    }
    MTLViewport viewports[2] = {};
    NSArray<WKMetalProjection *> *projections = nil;
    CGSize drawableSize = [self->_metalView drawableSize];
    id <CAMetalDrawable> drawable = [self->_metalView currentDrawable];
    if (drawableSize.width == 0 || drawableSize.height == 0) {
        return;
    }
    MTLSize textureSize = MTLSizeMake(presentationSize.num, presentationSize.den, 0);
    MTLSize layerSize = MTLSizeMake(drawable.texture.width, drawable.texture.height, 0);
    switch (displayMode) {
        case WKDisplayModePlane: {
            self->_projection1.matrix = baseMatrix;
            projections = @[self->_projection1];
            viewports[0] = [WKMetalViewport viewportWithLayerSize:layerSize textureSize:textureSize mode:WKScaling2Viewport(self->_scalingMode)];
        }
            break;
        case WKDisplayModeVR: {
            GLKMatrix4 matrix = GLKMatrix4Identity;
            Float64 aspect = (Float64)drawable.texture.width / drawable.texture.height;
            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&matrix]) {
                break;
            }
            self->_projection1.matrix = GLKMatrix4Multiply(baseMatrix, matrix);
            projections = @[self->_projection1];
            viewports[0] = [WKMetalViewport viewportWithLayerSize:layerSize];
        }
            break;
        case WKDisplayModeVRBox: {
            GLKMatrix4 matrix1 = GLKMatrix4Identity;
            GLKMatrix4 matrix2 = GLKMatrix4Identity;
            Float64 aspect = (Float64)drawable.texture.width / drawable.texture.height / 2.0;
            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&matrix1 matrix2:&matrix2]) {
                break;
            }
            self->_projection1.matrix = GLKMatrix4Multiply(baseMatrix, matrix1);
            self->_projection2.matrix = GLKMatrix4Multiply(baseMatrix, matrix2);
            projections = @[self->_projection1, self->_projection2];
            viewports[0] = [WKMetalViewport viewportWithLayerSizeForLeft:layerSize];
            viewports[1] = [WKMetalViewport viewportWithLayerSizeForRight:layerSize];
        }
            break;
    }
    if (projections.count) {
        id<MTLCommandBuffer> commandBuffer = [self.renderer drawModel:model
                                                            viewports:viewports
                                                             pipeline:pipeline
                                                          projections:projections
                                                        inputTextures:textures
                                                        outputTexture:drawable.texture];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [self->_lock lock];
        if (self->_flags.framesFetched == framesFetched) {
            self->_flags.framesDisplayed += 1;
            self->_flags.hasNewFrame = NO;
        }
        [self->_lock unlock];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    WKLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == WKRenderableStateRendering ||
        self->_flags.state == WKRenderableStatePaused ||
        self->_flags.state == WKRenderableStateFinished;
    }, ^WKBlock{
        self->_flags.framesDisplayed = 0;
        return ^{
            self->_metalView.paused = NO;
            self->_fetchTimer.paused = NO;
        };
    });
}

#pragma mark - Metal

- (void)setupDrawingLoop
{
//    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
//    self->_renderer = [[WKMetalRenderer alloc] initWithDevice:device];
//    self->_planeModel = [[WKMetalPlaneModel alloc] initWithDevice:device];
//    self->_projection1 = [[WKMetalProjection alloc] initWithDevice:device];
//    self->_projection2 = [[WKMetalProjection alloc] initWithDevice:device];
//    self->_sphereModel = [[WKMetalSphereModel alloc] initWithDevice:device];
//    self->_textureLoader = [[WKMetalTextureLoader alloc] initWithDevice:device];
//    self->_pipelinePool = [[WKMetalRenderPipelinePool alloc] initWithDevice:device];
//    self->_metalView = [[MTKView alloc] initWithFrame:CGRectZero device:device];
//    self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
//    self->_metalView.translatesAutoresizingMaskIntoConstraints = NO;
//    self->_metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
//    self->_metalView.delegate = self;
    WKWeakify(self)
    self->_fetchTimer = [[WKRenderTimer alloc] initWithHandler:^{
        WKStrongify(self)
        [self fetchTimerHandler];
    }];
//    [self updateMetalView];
    [self updateTimeInterval];
}

- (void)destoryDrawingLoop
{
    [self->_fetchTimer stop];
    self->_fetchTimer = nil;
    [self->_metalView removeFromSuperview];
    self->_metalView = nil;
    self->_renderer = nil;
    self->_planeModel = nil;
    self->_sphereModel = nil;
    self->_projection1 = nil;
    self->_projection2 = nil;
    self->_pipelinePool = nil;
    self->_textureLoader = nil;
    
    //支持 AVSampleBufferDisplayLayer
    [_displayView removeFromSuperview];
    _displayView = nil;
    _displayLayer = nil;
}

- (void)setView:(WKPLFView *)view
{
    if (self->_view != view) {
        self->_view = view;
//        [self updateMetalView];
//        [self updateTimeInterval];
    }
    
    if( view == nil ) {
        [self removeRenderView];
    }
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    if (self->_preferredFramesPerSecond != preferredFramesPerSecond) {
        self->_preferredFramesPerSecond = preferredFramesPerSecond;
        [self updateTimeInterval];
    }
}

- (void)setDisplayMode:(WKDisplayMode)displayMode
{
    if (self->_displayMode != displayMode) {
        self->_displayMode = displayMode;
        WKLockCondEXE10(self->_lock, ^BOOL {
            return
            self->_displayMode != WKDisplayModePlane &&
            (self->_flags.state == WKRenderableStateRendering ||
             self->_flags.state == WKRenderableStatePaused ||
             self->_flags.state == WKRenderableStateFinished);
        }, ^WKBlock{
            return ^{
                self->_metalView.paused = NO;
                self->_fetchTimer.paused = NO;
            };
        });
    }
}

- (void)updateMetalView
{
    if (self->_view &&
        self->_metalView &&
        self->_metalView.superview != self->_view) {
        WKPLFViewInsertSubview(self->_view, self->_metalView, 0);
        NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0
                                                               constant:0.0];
        [self->_view addConstraints:@[c1, c2, c3, c4]];
    } else {
        [self->_metalView removeFromSuperview];
    }
}

- (void)updateTimeInterval
{
    self->_fetchTimer.timeInterval = 0.5 / self->_preferredFramesPerSecond;
    if (self->_view &&
        self->_view == self->_metalView.superview) {
        self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
    } else {
        self->_metalView.preferredFramesPerSecond = 1;
    }
}

#pragma mark - 支持 AVSampleBufferDisplayLayer

- (void)initMetalView
{
    if( _metalView.superview != nil ) {
        return;
    }
    
    if( _metalView != nil ) {
        
        if( _metalView.superview == nil ) {
            [self updateMetalView];
        }
        
        return;
    }
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self->_renderer = [[WKMetalRenderer alloc] initWithDevice:device];
    self->_planeModel = [[WKMetalPlaneModel alloc] initWithDevice:device];
    self->_projection1 = [[WKMetalProjection alloc] initWithDevice:device];
    self->_projection2 = [[WKMetalProjection alloc] initWithDevice:device];
    self->_sphereModel = [[WKMetalSphereModel alloc] initWithDevice:device];
    self->_textureLoader = [[WKMetalTextureLoader alloc] initWithDevice:device];
    self->_pipelinePool = [[WKMetalRenderPipelinePool alloc] initWithDevice:device];
    self->_metalView = [[MTKView alloc] initWithFrame:CGRectZero device:device];
    self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
    self->_metalView.translatesAutoresizingMaskIntoConstraints = NO;
    self->_metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self->_metalView.delegate = self;
    
    [self updateMetalView];
    [self updateTimeInterval];
}

- (void)initDisplayLayer
{
    if( _displayView.superview != nil ) {
        return;
    }
    
    if( _displayView != nil ) {
        
        if( _displayView.superview == nil ){
            [self updateDisplayLayer];
        }
        
        return;
    }

    
    // 创建显示层
    self->_displayView = [[WKSampleBufferDisplayView alloc] init];
    self->_displayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self->_displayLayer = (AVSampleBufferDisplayLayer*)self->_displayView.layer;
        
    // 配置时间基准
    [self setupTimebase];
    [self updateDisplayLayer];
//    [self updateTimeInterval];
}

- (void)removeRenderView{
    [_displayView removeFromSuperview];
    [_metalView removeFromSuperview];
}

- (void)updateDisplayLayer
{
    if (self->_view &&
        self->_displayView &&
        self->_displayView.superview != self->_view) {
        WKPLFViewInsertSubview(self->_view, self->_displayView, 0);
        NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:self->_displayView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:self->_displayView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:self->_displayView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:self->_displayView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0
                                                               constant:0.0];
        [self->_view addConstraints:@[c1, c2, c3, c4]];
        
        
        // 设置视频填充模式
        switch (self.scalingMode) {
            case WKScalingModeResize:
                self.displayLayer.videoGravity = AVLayerVideoGravityResize;
                break;
            case WKScalingModeResizeAspect:
                self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                break;
            case WKScalingModeResizeAspectFill:
                self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                break;
        }
        
    } else {
        [self->_displayView removeFromSuperview];
    }
}

- (void)setupTimebase
{
    if (_timebase) {
        CFRelease(_timebase);
        _timebase = NULL;
    }
    
    // 创建主时间基准
    CMTimebaseCreateWithSourceClock(
        kCFAllocatorDefault,
        CMClockGetHostTimeClock(),
        &_timebase
    );
    
    // 设置初始速率
    CMTimebaseSetRate(_timebase, self.rate);
    
    // 关联到显示层
    self.displayLayer.controlTimebase = _timebase;
    
    // 设置当前时间为0
    CMTimebaseSetTime(_timebase, kCMTimeZero);
}

///根据帧来判断是否硬解，以选择使用的MetalView或AVSampleBufferDisplayLayer
- (void)resetRenderView:(WKVideoFrame*)frame{
    
    if (!_view.superview || !_view ) {
        return;
    }
    
    if( _metalView.superview != nil || _displayView.superview != nil ) {
        return;
    }
    
    [self->_lock lock];
    WKRational presentationSize = frame.descriptor.presentationSize;
    if (!frame ||
        presentationSize.num == 0 ||
        presentationSize.den == 0) {
        [self->_lock unlock];
        return;
    }
    [self->_lock unlock];
    WKDisplayMode displayMode = self->_displayMode;
    
    BOOL isHardDecoding = frame.pixelBuffer != nil;
        
    if( isHardDecoding && displayMode == WKDisplayModePlane) {
        [self initDisplayLayer];
    }else{
        [self initMetalView];
    }
}
#pragma mark - 支持 AVSampleBufferDisplayLayer enqueueSampleBuffer

// 修改帧提交方法
- (void)enqueueFrame:(WKVideoFrame *)frame
{
    if (!frame.pixelBuffer) {
        return;
    }
    
    // 应用旋转变换
    NSInteger rotate = [frame.metadata[@"rotate"] integerValue];
    if (rotate != self.currentRotation) {
        self.currentRotation = rotate;
//        [self applyRotationTransform:rotate];
        [self updateDisplayLayerTransformWithRotation:rotate];
    }
    
    // 应用色彩属性
    [self applyColorPropertiesToPixelBuffer:(CVPixelBufferRef)frame.pixelBuffer];
    
    // 创建视频格式描述
    CMVideoFormatDescriptionRef formatDescription = NULL;
    OSStatus status = CMVideoFormatDescriptionCreateForImageBuffer(
        kCFAllocatorDefault,
        (CVImageBufferRef)frame.pixelBuffer,
        &formatDescription
    );
    
    if (status != noErr || !formatDescription) {
        return;
    }
    
    // ===== 关键修复：正确计算时间信息 =====
    CMTime presentationTime = frame.timeStamp;
    
    // 获取当前时间基准时间
    if (_timebase) {
        CMTime baseTime = CMTimebaseGetTime(_timebase);
        
        // 如果新帧时间早于当前时间，调整到当前时间之后
        if (CMTimeCompare(presentationTime, baseTime) < 0) {
            presentationTime = CMTimeAdd(baseTime, frame.duration);
        }
    }
    
    CMSampleTimingInfo timingInfo = {
        .duration = frame.duration,
        .presentationTimeStamp = presentationTime, // 使用调整后的时间
        .decodeTimeStamp = kCMTimeInvalid
    };
    // ===== 时间修复结束 =====
    
    // 创建样本缓冲区
    CMSampleBufferRef sampleBuffer = NULL;
    status = CMSampleBufferCreateReadyWithImageBuffer(
        kCFAllocatorDefault,
        (CVImageBufferRef)frame.pixelBuffer,
        formatDescription,
        &timingInfo,
        &sampleBuffer
    );
    
    if (status != noErr || !sampleBuffer) {
        CFRelease(formatDescription);
        return;
    }
    
    // 提交给显示层
    if ([self.displayLayer isReadyForMoreMediaData]) {
        [self.displayLayer enqueueSampleBuffer:sampleBuffer];
    } else {
        [self.displayLayer flush];
        [self.displayLayer enqueueSampleBuffer:sampleBuffer];
    }
    
    // 更新时间基准（重要！）
    if (_timebase) {
        // 设置下一个预期时间
        CMTime nextTime = CMTimeAdd(presentationTime, frame.duration);
        CMTimebaseSetTime(_timebase, nextTime);
    }
    
    // 释放资源
    CFRelease(sampleBuffer);
    CFRelease(formatDescription);
}


// 为像素缓冲区设置正确的色彩属性
- (void)applyColorPropertiesToPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    // 1. 确定视频特性（HDR或SDR）
    BOOL isHDR = [self isHDRVideoFrame:pixelBuffer];
    
    // 2. 准备色彩属性字典
    NSMutableDictionary *colorProperties = [NSMutableDictionary dictionary];
    
    if (isHDR) {
        // HLG HDR 配置
        colorProperties[(NSString *)kCVImageBufferColorPrimariesKey] = (NSString *)kCVImageBufferColorPrimaries_ITU_R_2020;
        colorProperties[(NSString *)kCVImageBufferTransferFunctionKey] = (NSString *)kCVImageBufferTransferFunction_ITU_R_2100_HLG;
        colorProperties[(NSString *)kCVImageBufferYCbCrMatrixKey] = (NSString *)kCVImageBufferYCbCrMatrix_ITU_R_2020;
    } else {
        // SDR 配置
        colorProperties[(NSString *)kCVImageBufferColorPrimariesKey] = (NSString *)kCVImageBufferColorPrimaries_ITU_R_709_2;
        colorProperties[(NSString *)kCVImageBufferTransferFunctionKey] = (NSString *)kCVImageBufferTransferFunction_ITU_R_709_2;
        colorProperties[(NSString *)kCVImageBufferYCbCrMatrixKey] = (NSString *)kCVImageBufferYCbCrMatrix_ITU_R_709_2;
    }
    
    // 3. 应用色彩属性
    CVBufferSetAttachments(
        pixelBuffer,
        (__bridge CFDictionaryRef)colorProperties,
        kCVAttachmentMode_ShouldPropagate
    );
}

// 检测是否为HDR视频帧
- (BOOL)isHDRVideoFrame:(CVPixelBufferRef)pixelBuffer
{
    // 方法1：检查像素格式
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (pixelFormat == kCVPixelFormatType_420YpCbCr10BiPlanarFullRange ||
        pixelFormat == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange) {
        return YES; // 10-bit 通常是 HDR
    }
    
    // 方法2：检查现有属性
    CFTypeRef attachments = CVBufferGetAttachments(pixelBuffer, kCVAttachmentMode_ShouldPropagate);
    NSDictionary *existingProps = (__bridge NSDictionary *)attachments;
    
    if (existingProps[(NSString *)kCVImageBufferTransferFunctionKey]) {
        NSString *tf = existingProps[(NSString *)kCVImageBufferTransferFunctionKey];
        return [tf isEqualToString:(NSString *)kCVImageBufferTransferFunction_ITU_R_2100_HLG] ||
               [tf isEqualToString:(NSString *)kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ];
    }
    
    return NO;
    // 方法3：根据内容类型判断（您可能需要扩展 WKVideoFrame 来存储这个信息）
//    return self->_currentFrame.isHDR;
}

- (void)updateDisplayLayerTransformWithRotation:(NSInteger)rotation
{
    // 重置transform
    self.displayLayer.affineTransform = CGAffineTransformIdentity;
    // 计算旋转后的bounds
    CGRect bounds = self.view.bounds;
    CGFloat radians = 0;
    if (rotation == 90 || rotation == 270) {
        // 宽高交换
        bounds = CGRectMake(0, 0, CGRectGetHeight(bounds), CGRectGetWidth(bounds));
    }
    // 设置旋转
    switch (rotation) {
        case 90:
            radians = M_PI_2;
            break;
        case 180:
            radians = M_PI;
            break;
        case 270:
            radians = -M_PI_2;
            break;
        default:
            radians = 0;
            break;
    }
    // 设置transform
    if (radians != 0) {
        self.displayLayer.affineTransform = CGAffineTransformMakeRotation(radians);
    }
    // 更新显示层的frame
//    self.displayLayer.frame = bounds;
}

@end
