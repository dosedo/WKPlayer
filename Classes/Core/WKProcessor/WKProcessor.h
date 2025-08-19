//
//  WKProcessor.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTrackSelection.h"
#import "WKCapacity.h"
#import "WKFrame.h"

@protocol WKProcessor <NSObject>

/**
 *
 */
- (void)setSelection:(WKTrackSelection *)selection action:(WKTrackSelectionAction)action;

/**
 *
 */
- (__kindof WKFrame *)putFrame:(__kindof WKFrame *)frame;

/**
 *
 */
- (__kindof WKFrame *)finish;

/**
 *
 */
- (WKCapacity)capacity;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (void)close;

@end
