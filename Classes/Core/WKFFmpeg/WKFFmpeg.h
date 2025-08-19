//
//  WKFFmpeg.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "avformat.h"
#import "imgutils.h"
#import "swresample.h"
#import "swscale.h"
#import "avcodec.h"
#pragma clang diagnostic pop

void WKFFmpegSetupIfNeeded(void);
