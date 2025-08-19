//
//  WKAsset.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class WKAsset
 @abstract
    Abstract class for assets.
 
 @discussion
    Use WKURLAsset or WKMutableAsset.
 */
@interface WKAsset : NSObject <NSCopying>

/*!
 @method assetWithURL:
 @abstract
    Returns an instance of WKAsset for inspection of a media resource.
 @result
    An instance of WKAsset.
 
 @discussion
    Returns a newly allocated instance of a subclass of WKAsset initialized with the specified URL.
 */
+ (instancetype)assetWithURL:(NSURL *)URL;

@end
