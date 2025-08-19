//
//  WKTime.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

BOOL WKCMTimeIsValid(CMTime time, BOOL infinity);

CMTime WKCMTimeValidate(CMTime time, CMTime defaultTime, BOOL infinity);
CMTime WKCMTimeMakeWithSeconds(Float64 seconds);
CMTime WKCMTimeMultiply(CMTime time, CMTime multiplier);
CMTime WKCMTimeDivide(CMTime time, CMTime divisor);
CMTime WKCMTimeDivide(CMTime time, CMTime divisor);

CMTimeRange WKCMTimeRangeFitting(CMTimeRange timeRange);
CMTimeRange WKCMTimeRangeGetIntersection(CMTimeRange timeRange1, CMTimeRange timeRange2);
