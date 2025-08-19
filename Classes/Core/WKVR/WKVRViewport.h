//
//  WKVRViewport.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKVRViewport : NSObject

@property (nonatomic) Float64 degress;       // Default value is 60.
@property (nonatomic) Float64 x;             // Default value is 0, range is (-360, 360).
@property (nonatomic) Float64 y;             // Default value is 0, range is (-360, 360).
@property (nonatomic) BOOL flipX;            // Default value is NO.
@property (nonatomic) BOOL flipY;            // Default value is NO.
@property (nonatomic) BOOL sensorEnable;     // Default value is YES.

@end
