//
//  WKError.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WKErrorCode) {
    WKErrorCodeUnknown = 0,
    WKErrorImmediateExitRequested,
    WKErrorCodeNoValidFormat,
    WKErrorCodeFormatNotSeekable,
    WKErrorCodePacketOutputCancelSeek,
    WKErrorCodeDemuxerEndOfFile,
    WKErrorCodeInvlidTime,
};

typedef NS_ENUM(NSUInteger, WKActionCode) {
    WKActionCodeUnknown = 0,
    WKActionCodeFormatCreate,
    WKActionCodeFormatOpenInput,
    WKActionCodeFormatFindStreamInfo,
    WKActionCodeFormatSeekFrame,
    WKActionCodeFormatReadFrame,
    WKActionCodeFormatGetSeekable,
    WKActionCodeCodecSetParametersToContext,
    WKActionCodeCodecOpen2,
    WKActionCodePacketOutputSeek,
    WKActionCodeURLDemuxerFunnelNext,
    WKActionCodeMutilDemuxerNext,
    WKActionCodeSegmentDemuxerNext,
    WKActionCodeNextFrame,
};

NSError * WKGetFFError(int result, WKActionCode operation);
NSError * WKCreateError(NSUInteger code, WKActionCode operation);
