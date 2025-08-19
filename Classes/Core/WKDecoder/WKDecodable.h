//
//  WKDecodable.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDecoderOptions.h"
#import "WKPacket.h"
#import "WKFrame.h"

@protocol WKDecodable <NSObject>

/**
 *
 */
@property (nonatomic, strong) WKDecoderOptions *options;

/**
 *
 */
- (NSArray<__kindof WKFrame *> *)decode:(WKPacket *)packet;

/**
 *
 */
- (NSArray<__kindof WKFrame *> *)finish;

/**
 *
 */
- (void)flush;

@end
