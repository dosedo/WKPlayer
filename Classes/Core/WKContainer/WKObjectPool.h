//
//  WKObjectPool.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKData.h"

@interface WKObjectPool : NSObject

+ (instancetype)sharedPool;

/**
 *
 */
- (__kindof id<WKData>)objectWithClass:(Class)class reuseName:(NSString *)reuseName;

/**
 *
 */
- (void)comeback:(id<WKData>)object;

/**
 *
 */
- (void)flush;

@end
