//
//  WKAsset.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAsset.h"
#import "WKAsset+Internal.h"
#import "WKURLAsset.h"

@implementation WKAsset

+ (instancetype)assetWithURL:(NSURL *)URL
{
    return [[WKURLAsset alloc] initWithURL:URL];
}

- (id)copyWithZone:(NSZone *)zone
{
    WKAsset *obj = [[self.class alloc] init];
    return obj;
}

- (id<WKDemuxable>)newDemuxer
{
    NSAssert(NO, @"Subclass only.");
    return nil;
}

@end
