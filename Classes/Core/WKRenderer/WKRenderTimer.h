//
//  WKRenderTimer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKRenderTimer : NSObject

- (instancetype)initWithHandler:(dispatch_block_t)handler;

@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic) BOOL paused;

- (void)start;
- (void)stop;

@end
