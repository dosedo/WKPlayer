//
//  WKDemuxable.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 *
 */
typedef NS_OPTIONS(NSUInteger, WKDataFlags) {
    WKDataFlagPadding = 1 << 0,
};

@protocol WKData <NSObject>

/**
 *
 */
@property (nonatomic) WKDataFlags flags;

/**
 *
 */
@property (nonatomic, copy) NSString *reuseName;

/**
 *
 */
- (void)lock;

/**
 *
 */
- (void)unlock;

/**
 *
 */
- (void)clear;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (CMTime)timeStamp;

/**
 *
 */
- (int)size;

@end
