//
//  WKURLAsset.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAsset.h"

@interface WKURLAsset : WKAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithURL:
 @abstract
    Initializes an WKURLAsset with the given URL.
 */
- (instancetype)initWithURL:(NSURL *)URL;

/*!
 @property URL
 @abstract
    Indicates the URL of the asset.
 */
@property (nonatomic, copy, readonly) NSURL *URL;

@end
