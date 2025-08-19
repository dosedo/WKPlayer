//
//  WKVRProjection.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "WKVRViewport.h"

@interface WKVRProjection : NSObject

@property (nonatomic, strong) WKVRViewport * viewport;

- (BOOL)ready;
- (BOOL)matrixWithAspect:(Float64)aspect matrix1:(GLKMatrix4 *)matrix1;
- (BOOL)matrixWithAspect:(Float64)aspect matrix1:(GLKMatrix4 *)matrix1 matrix2:(GLKMatrix4 *)matrix2;

@end

