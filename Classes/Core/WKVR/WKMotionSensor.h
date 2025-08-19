//
//  WKMotionSensor.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface WKMotionSensor : NSObject

@property (nonatomic, readonly) BOOL ready;
@property (nonatomic, readonly) GLKMatrix4 matrix;

- (void)start;
- (void)stop;

@end
