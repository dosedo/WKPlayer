//
//  WKTrack+Internal.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKTrack.h"
#import "WKFFmpeg.h"
#import "WKMutableTrack.h"

@interface WKTrack ()

/*!
 @method initWithType:index:
 @abstract
    Initializes an WKTrack.
 */
- (instancetype)initWithType:(WKMediaType)type index:(NSInteger)index;

/*!
 @property core
 @abstract
    Indicates the pointer to the AVStream.
*/
@property (nonatomic) AVStream *core;

@end

@interface WKMutableTrack ()

/*!
 @property subTracks
 @abstract
    Indicates the sub tracks.
 */
@property (nonatomic, copy) NSArray<WKTrack *> *subTracks;

@end
