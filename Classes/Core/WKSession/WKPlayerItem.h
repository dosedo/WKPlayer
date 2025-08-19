//
//  WKPlayerItem.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTrackSelection.h"
#import "WKAsset.h"
#import "WKTrack.h"

@interface WKPlayerItem : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithAsset:
 @abstract
    Initializes an WKPlayerItem with asset.
 */
- (instancetype)initWithAsset:(WKAsset *)asset;

/*!
 @property error
 @abstract
    If the loading item failed, this describes the error that caused the failure.
 */
@property (nonatomic, copy, readonly) NSError *error;

/*!
 @property tracks
 @abstract
    Provides array of WKPlayerItem tracks.
 */
@property (nonatomic, copy, readonly) NSArray<WKTrack *> *tracks;

/*!
 @property duration
 @abstract
    Indicates the metadata of the item.
 */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/*!
 @property duration
 @abstract
    Indicates the duration of the item.
 */
@property (nonatomic, readonly) CMTime duration;

/*!
 @property duration
 @abstract
    Indicates the audioSelection of the item.
 */
@property (nonatomic, copy, readonly) WKTrackSelection *audioSelection;

/*!
 @method setAudioSelection:action:
 @abstract
    Select specific audio tracks.
 */
- (void)setAudioSelection:(WKTrackSelection *)audioSelection action:(WKTrackSelectionAction)action;

/*!
 @property duration
 @abstract
    Indicates the videoSelection of the item.
 */
@property (nonatomic, copy, readonly) WKTrackSelection *videoSelection;

/*!
 @method setVideoSelection:action:
 @abstract
    Select specific video tracks.
 */
- (void)setVideoSelection:(WKTrackSelection *)videoSelection action:(WKTrackSelectionAction)action;

@end
