//
//  WKMutableAsset.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKAsset.h"
#import "WKDefines.h"
#import "WKMutableTrack.h"

@interface WKMutableAsset : WKAsset

/*!
 @property tracks
 @abstract
    Provides array of mutable asset tracks.
*/
@property (nonatomic, copy, readonly) NSArray<WKMutableTrack *> *tracks;

/*!
 @method addTrack:
 @abstract
    Add a track to the asset.
 
 @discussion
    Returns a initialized mutable track of the given type.
 */
- (WKMutableTrack *)addTrack:(WKMediaType)type;

@end
