//
//  WKPacket+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPacket.h"
#import "WKFFmpeg.h"
#import "WKAudioDescriptor.h"
#import "WKVideoDescriptor.h"

@interface WKAudioDescriptor ()

- (instancetype)initWithFrame:(AVFrame *)frame;

/*!
 @property channelLayout
 @abstract
    Indicates the channel layout.
 */
@property (nonatomic) AVChannelLayout channelLayout;

@end

@interface WKVideoDescriptor ()

- (instancetype)initWithFrame:(AVFrame *)frame;

@end
