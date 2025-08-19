//
//  WKDemuxerOptions.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKDemuxerOptions : NSObject <NSCopying>

/*!
 @property options
 @abstract
    The options for avformat_open_input.
    Default:
        @{@"reconnect" : @(1),
          @"user-agent" : @"WKPlayer",
          @"timeout" : @(20 * 1000 * 1000)}
 */
@property (nonatomic, copy) NSDictionary *options;

@end
