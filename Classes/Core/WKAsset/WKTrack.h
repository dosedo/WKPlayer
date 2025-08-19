//
//  WKTrack.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDefines.h"

@interface WKTrack : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @property coreptr
 @abstract
    Indicates the pointer to the AVStream.
 */
@property (nonatomic, readonly) void *coreptr;

/*!
 @property type
 @abstract
    Indicates the track media type.
 */
@property (nonatomic, readonly) WKMediaType type;

/*!
 @property type
 @abstract
    Indicates the track index.
 */
@property (nonatomic, readonly) NSInteger index;

/*!
 @method trackWithTracks:type:
 @abstract
   Get track with media type.
*/
+ (WKTrack *)trackWithTracks:(NSArray<WKTrack *> *)tracks type:(WKMediaType)type;

/*!
 @method trackWithTracks:index:
 @abstract
   Get track with index.
*/
+ (WKTrack *)trackWithTracks:(NSArray<WKTrack *> *)tracks index:(NSInteger)index;

/*!
 @method tracksWithTracks:type:
 @abstract
   Get tracks with media types.
*/
+ (NSArray<WKTrack *> *)tracksWithTracks:(NSArray<WKTrack *> *)tracks type:(WKMediaType)type;

@end
