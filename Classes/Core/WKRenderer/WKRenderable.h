//
//  WKRenderable.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKCapacity.h"
#import "WKFrame.h"

@protocol WKRenderableDelegate;

/**
 *
 */
typedef NS_ENUM(NSUInteger, WKRenderableState) {
    WKRenderableStateNone      = 0,
    WKRenderableStateRendering = 1,
    WKRenderableStatePaused    = 2,
    WKRenderableStateFinished  = 3,
    WKRenderableStateFailed    = 4,
};

@protocol WKRenderable <NSObject>

/**
 *
 */
@property (nonatomic, weak) id<WKRenderableDelegate> delegate;

/**
 *
 */
@property (nonatomic, readonly) WKRenderableState state;

/**
 *
 */
- (WKCapacity)capacity;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)finish;

@end

@protocol WKRenderableDelegate <NSObject>

/**
 *
 */
- (void)renderable:(id<WKRenderable>)renderable didChangeState:(WKRenderableState)state;

/**
 *
 */
- (void)renderable:(id<WKRenderable>)renderable didChangeCapacity:(WKCapacity)capacity;

/**
 *
 */
- (__kindof WKFrame *)renderable:(id<WKRenderable>)renderable fetchFrame:(WKTimeReader)timeReader;

@end
