//
//  WKMetalViewport.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMetalViewport.h"

@implementation WKMetalViewport

+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize
{
    MTLViewport viewport = {0, 0, layerSize.width, layerSize.height, 0, 0};
    return viewport;
}

+ (MTLViewport)viewportWithLayerSizeForLeft:(MTLSize)layerSize
{
    MTLViewport viewport = {0, 0, layerSize.width / 2, layerSize.height, 0, 0};
    return viewport;
}

+ (MTLViewport)viewportWithLayerSizeForRight:(MTLSize)layerSize
{
    MTLViewport viewport = {layerSize.width / 2, 0, layerSize.width / 2, layerSize.height, 0, 0};
    return viewport;
}

+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize textureSize:(MTLSize)textureSize mode:(WKMetalViewportMode)mode
{
    MTLViewport viewport = {0, 0, layerSize.width, layerSize.height, 0, 0};
    switch (mode) {
        case WKMetalViewportModeResize:
            break;
        case WKMetalViewportModeResizeAspect: {
            Float64 layerAspect = (Float64)layerSize.width / layerSize.height;
            Float64 textureAspect = (Float64)textureSize.width / textureSize.height;
            if (fabs(layerAspect - textureAspect) <= 0.0001) {
                
            } else if (layerAspect < textureAspect) {
                Float64 height = layerSize.width / textureAspect;
                viewport.originX = 0;
                viewport.originY = (layerSize.height - height) / 2;
                viewport.width = layerSize.width;
                viewport.height = height;
            } else if (layerAspect > textureAspect) {
                Float64 width = layerSize.height * textureAspect;
                viewport.originX = (layerSize.width - width) / 2;
                viewport.originY = 0;
                viewport.width = width;
                viewport.height = layerSize.height;
            }
        }
            break;
        case WKMetalViewportModeResizeAspectFill: {
            Float64 layerAspect = (Float64)layerSize.width / layerSize.height;
            Float64 textureAspect = (Float64)textureSize.width / textureSize.height;
            if (fabs(layerAspect - textureAspect) <= 0.0001) {
                
            } else if (layerAspect < textureAspect) {
                Float64 width = layerSize.height * textureAspect;
                viewport.originX = (layerSize.width - width) / 2;
                viewport.originY = 0;
                viewport.width = width;
                viewport.height = layerSize.height;
            } else if (layerAspect > textureAspect) {
                Float64 height = layerSize.width / textureAspect;
                viewport.originX = 0;
                viewport.originY = (layerSize.height - height) / 2;
                viewport.width = layerSize.width;
                viewport.height = height;
            }
        }
            break;
    }
    return viewport;
}

@end
