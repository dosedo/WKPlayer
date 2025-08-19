//
//  WKMetalViewport.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Metal/Metal.h>

typedef NS_ENUM(NSUInteger, WKMetalViewportMode) {
    WKMetalViewportModeResize           = 0,
    WKMetalViewportModeResizeAspect     = 1,
    WKMetalViewportModeResizeAspectFill = 2,
};

@interface WKMetalViewport : NSObject

+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForLeft:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForRight:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize textureSize:(MTLSize)textureSize mode:(WKMetalViewportMode)mode;


@end
