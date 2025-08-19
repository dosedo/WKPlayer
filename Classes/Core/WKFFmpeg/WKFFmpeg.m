//
//  WKFFmpeg.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKFFmpeg.h"

static void WKFFmpegLogCallback(void * context, int level, const char * format, va_list args)
{
//    NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
//    NSLog(@"WKFFLog : %@", message);
}

void WKFFmpegSetupIfNeeded(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_log_set_callback(WKFFmpegLogCallback);
        avformat_network_init();
    });
}
