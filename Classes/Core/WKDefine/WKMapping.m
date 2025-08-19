//
//  WKMapping.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKMapping.h"

WKMetalViewportMode WKScaling2Viewport(WKScalingMode mode)
{
    switch (mode) {
        case WKScalingModeResize:
            return WKMetalViewportModeResize;
        case WKScalingModeResizeAspect:
            return WKMetalViewportModeResizeAspect;
        case WKScalingModeResizeAspectFill:
            return WKMetalViewportModeResizeAspectFill;
    }
    return WKMetalViewportModeResizeAspect;
}

WKScalingMode WKViewport2Scaling(WKMetalViewportMode mode)
{
    switch (mode) {
        case WKMetalViewportModeResize:
            return WKScalingModeResize;
        case WKMetalViewportModeResizeAspect:
            return WKScalingModeResizeAspect;
        case WKMetalViewportModeResizeAspectFill:
            return WKScalingModeResizeAspectFill;
    }
    return WKScalingModeResizeAspect;
}

WKMediaType WKMediaTypeFF2WK(enum AVMediaType mediaType)
{
    switch (mediaType) {
        case AVMEDIA_TYPE_AUDIO:
            return WKMediaTypeAudio;
        case AVMEDIA_TYPE_VIDEO:
            return WKMediaTypeVideo;
        case AVMEDIA_TYPE_SUBTITLE:
            return WKMediaTypeSubtitle;
        default:
            return WKMediaTypeUnknown;
    }
}

enum AVMediaType WKMediaTypeWK2FF(WKMediaType mediaType)
{
    switch (mediaType) {
        case WKMediaTypeAudio:
            return AVMEDIA_TYPE_AUDIO;
        case WKMediaTypeVideo:
            return AVMEDIA_TYPE_VIDEO;
        case WKMediaTypeSubtitle:
            return AVMEDIA_TYPE_SUBTITLE;
        default:
            return AVMEDIA_TYPE_UNKNOWN;
    }
}

OSType WKPixelFormatFF2AV(enum AVPixelFormat format)
{
    switch (format) {
        case AV_PIX_FMT_YUV420P:
            return kCVPixelFormatType_420YpCbCr8Planar;
        case AV_PIX_FMT_UYVY422:
            return kCVPixelFormatType_422YpCbCr8;
        case AV_PIX_FMT_BGRA:
            return kCVPixelFormatType_32BGRA;
        case AV_PIX_FMT_NV12:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        default:
            return 0;
    }
    return 0;
}

enum AVPixelFormat WKPixelFormatAV2FF(OSType format)
{
    switch (format) {
        case kCVPixelFormatType_420YpCbCr8Planar:
            return AV_PIX_FMT_YUV420P;
        case kCVPixelFormatType_422YpCbCr8:
            return AV_PIX_FMT_UYVY422;
        case kCVPixelFormatType_32BGRA:
            return AV_PIX_FMT_BGRA;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return AV_PIX_FMT_NV12;
        default:
            return AV_PIX_FMT_NONE;
    }
    return AV_PIX_FMT_NONE;
}

AVDictionary * WKDictionaryNS2FF(NSDictionary *dictionary)
{
    __block AVDictionary *ret = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            av_dict_set_int(&ret, [key UTF8String], [obj integerValue], 0);
        } else if ([obj isKindOfClass:[NSString class]]) {
            av_dict_set(&ret, [key UTF8String], [obj UTF8String], 0);
        }
    }];
    return ret;
}

NSDictionary * WKDictionaryFF2NS(AVDictionary *dictionary)
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    AVDictionaryEntry *entry = NULL;
    while ((entry = av_dict_get(dictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        NSString *key = [NSString stringWithUTF8String:entry->key];
        NSString *value = [NSString stringWithUTF8String:entry->value];
        //wk add  解决部分视频标题不对崩溃问题
        if( value.length == 0 ) {
            value = @"unknown title";
        }
        [ret setObject:value forKey:key];
    }
    if (ret.count <= 0) {
        ret = nil;
    }
    return [ret copy];
}
