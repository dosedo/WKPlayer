//
//  WKMapping.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKVideoRenderer.h"
#import "WKMetalViewport.h"
#import "WKFFmpeg.h"

// WK <-> WKMetal
WKMetalViewportMode WKScaling2Viewport(WKScalingMode mode);
WKScalingMode WKViewport2Scaling(WKMetalViewportMode mode);

// FF <-> WK
WKMediaType WKMediaTypeFF2WK(enum AVMediaType mediaType);
enum AVMediaType WKMediaTypeWK2FF(WKMediaType mediaType);

// FF <-> AV
OSType WKPixelFormatFF2AV(enum AVPixelFormat format);
enum AVPixelFormat WKPixelFormatAV2FF(OSType format);

// FF <-> NS
AVDictionary * WKDictionaryNS2FF(NSDictionary *dictionary);
NSDictionary * WKDictionaryFF2NS(AVDictionary *dictionary);
