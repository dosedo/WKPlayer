//
//  WKError.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKError.h"
#import "WKFFmpeg.h"

static NSString * const WKErrorUserInfoKeyOperation = @"WKErrorUserInfoKeyOperation";

NSError * WKGetFFError(int result, WKActionCode operation)
{
    if (result >= 0) {
        return nil;
    }
    char *data = malloc(256);
    av_strerror(result, data, 256);
    NSString *domain = [NSString stringWithFormat:@"WKPlayer-Error-FFmpeg code : %d, msg : %s", result, data];
    free(data);
    if (result == AVERROR_EXIT) {
        result = WKErrorImmediateExitRequested;
    } else if (result == AVERROR_EOF) {
        result = WKErrorCodeDemuxerEndOfFile;
    }
    return [NSError errorWithDomain:domain code:result userInfo:@{WKErrorUserInfoKeyOperation : @(operation)}];
}

NSError * WKCreateError(NSUInteger code, WKActionCode operation)
{
    return [NSError errorWithDomain:@"WKPlayer-Error-WKErrorCode" code:(NSInteger)code userInfo:@{WKErrorUserInfoKeyOperation : @(operation)}];
}
