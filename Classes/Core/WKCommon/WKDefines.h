//
//  WKDefines.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#if defined(__cplusplus)
#define WKPLAYER_EXTERN extern "C"
#else
#define WKPLAYER_EXTERN extern
#endif

typedef NS_ENUM(NSUInteger, WKMediaType) {
    WKMediaTypeUnknown  = 0,
    WKMediaTypeAudio    = 1,
    WKMediaTypeVideo    = 2,
    WKMediaTypeSubtitle = 3,
};

typedef NS_ENUM(NSUInteger, WKPlayerState) {
    WKPlayerStateNone      = 0,
    WKPlayerStatePreparing = 1,
    WKPlayerStateReady     = 2,
    WKPlayerStateFailed    = 3,
};

typedef NS_OPTIONS(NSUInteger, WKPlaybackState) {
    WKPlaybackStateNone     = 0,
    WKPlaybackStatePlaying  = 1 << 0,
    WKPlaybackStateSeeking  = 1 << 1,
    WKPlaybackStateFinished = 1 << 2,
};

typedef NS_ENUM(NSUInteger, WKLoadingState) {
    WKLoadingStateNone     = 0,
    WKLoadingStatePlaybale = 1,
    WKLoadingStateStalled  = 2,
    WKLoadingStateFinished = 3,
};

typedef NS_OPTIONS(NSUInteger, WKInfoAction) {
    WKInfoActionNone          = 0,
    WKInfoActionTimeCached    = 1 << 1,
    WKInfoActionTimePlayback  = 1 << 2,
    WKInfoActionTimeDuration  = 1 << 3,
    WKInfoActionTime          = WKInfoActionTimeCached | WKInfoActionTimePlayback | WKInfoActionTimeDuration,
    WKInfoActionStatePlayer   = 1 << 4,
    WKInfoActionStateLoading  = 1 << 5,
    WKInfoActionStatePlayback = 1 << 6,
    WKInfoActionState         = WKInfoActionStatePlayer | WKInfoActionStateLoading | WKInfoActionStatePlayback,
};

typedef struct {
    int num;
    int den;
} WKRational;

typedef struct {
    CMTime cached;
    CMTime playback;
    CMTime duration;
} WKTimeInfo;

typedef struct {
    WKPlayerState player;
    WKLoadingState loading;
    WKPlaybackState playback;
} WKStateInfo;

@class WKPlayer;

typedef void (^WKBlock)(void);
typedef void (^WKHandler)(WKPlayer *player);
typedef BOOL (^WKTimeReader)(CMTime *desire, BOOL *drop);
typedef void (^WKSeekResult)(CMTime time, NSError *error);
