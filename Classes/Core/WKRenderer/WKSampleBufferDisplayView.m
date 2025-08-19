//
//  WKSampleBufferDisplayView.m
//  WKPlayer
//
//  Created by wkun on 2025/8/19.
//

#import "WKSampleBufferDisplayView.h"

@implementation WKSampleBufferDisplayView

+ (Class)layerClass{
    return [AVSampleBufferDisplayLayer class];
}

@end
