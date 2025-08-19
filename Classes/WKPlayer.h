//
//  WKPlayer.h
//  WKPlayer
//
//  Created by Kidsmiless on 08/01/2025.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPlayerHeader.h"

#pragma mark - WKPlayer

@interface WKPlayer : NSObject

/*!
 @property playView
 @abstract
    Indicates the view that displays content.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, strong) UIView *playView;

/*!
 @property options
 @abstract
    The options for an WKPlayer.
 
 @discussion
    When a player is Created, a copy of the shared options is made.
    After modifying the options, call -replaceWithXXX: to apply the new options.
 */
@property (nonatomic, strong) WKOptions *options;

/*!
 @method error
 @abstract
    Get player error information.
 */
- (NSError *)error;

/*!
 @method timeInfo
 @abstract
    Get player time information.
 */
- (WKTimeInfo)timeInfo;

/*!
 @method sstateInfo
 @abstract
    Get player state information.
 */
- (WKStateInfo)sstateInfo;

/*!
 @method stateInfo:timeInfo:error:
 @abstract
    Get player state and time information.
 @result
    Returns YES if the information was fill to the params.
 
 @discussion
    Use this method to get synchronized state and time information.
 */
- (BOOL)stateInfo:(WKStateInfo *)stateInfo timeInfo:(WKTimeInfo *)timeInfo error:(NSError **)error;

@end

#pragma mark - Item

@interface WKPlayer ()

/*!
 @method currentItem
 @abstract
    Indicates the current item of the Player.
 @result
    Returns nil if the player is idle.
 */
- (WKPlayerItem *)currentItem;

/*!
 @property readyHandler
 @abstract
    The handler will be called when the player gets ready.
 
 @discussion
    This handler will be executed in an unknown thread. Do not perform complex opertaionts in this method.
    For example, do some basic configuration of the current item.
 */
@property (nonatomic, copy) WKHandler readyHandler;

/*!
 @method replaceWithURL:
 @abstract
    Equivalent:
        WKAsset *asset = [[WKURLAsset alloc] initWithURL:URL];
        [self replaceWithAsset:asset];
 */
- (BOOL)replaceWithURL:(NSURL *)URL;

/*!
 @method replaceWithAsset:
 @abstract
    Equivalent:
        WKPlayerItem *item = [[WKPlayerItem alloc] initWithAsset:asset];
        [self replaceWithPlayerItem:item];
 */
- (BOOL)replaceWithAsset:(WKAsset *)asset;

/*!
 @method replaceWithPlayerItem:
 @abstract
    Replaces the player's current item with the specified player item.
 
 @discussion
    After calling this method, the player will be reset and automatically start loading new item.
 */
- (BOOL)replaceWithPlayerItem:(WKPlayerItem *)item;

@end

#pragma mark - Playback

@interface WKPlayer ()

/*!
 @property rate
 @abstract
    Indicates the desired rate of playback.
 
 @discussion
    This is different from AVPlayer's rate. It only indicates the desired rate of playback and does not trigger playback action.
 */
@property (nonatomic) Float64 rate;

/*!
 @property wantsToPlay
 @abstract
    Indicates whether the player is currently paused or played.
 
 @discussion
    After calling -play, the value will change to YES.
    After calling -pause, the value will change to NO.
 */
@property (nonatomic, readonly) BOOL wantsToPlay;

#if WKPLATFORM_TARGET_OS_IPHONE_OR_TV
/*!
 @property pausesWhenInterrupted
 @abstract
    Indicates whether to automatically pause when audio session is interrupted.
    Default is YES.
 */
@property (nonatomic) BOOL pausesWhenInterrupted;

/*!
 @property pausesWhenEnteredBackground
 @abstract
    Indicates whether to automatically pause when application did enter background.
    Default is NO.
 */
@property (nonatomic) BOOL pausesWhenEnteredBackground;

/*!
 @property pausesWhenEnteredBackgroundIfNoAudioTrack
 @abstract
    Indicates whether to automatically pause when application did enter background if no audio track.
    Default is YES.
 */
@property (nonatomic) BOOL pausesWhenEnteredBackgroundIfNoAudioTrack;
#endif

/*!
 @method play
 @abstract
    Signals the desire to begin playback at the current rate.
 */
- (BOOL)play;

/*!
 @method pause
 @abstract
    Signals the desire to pause playback.
 */
- (BOOL)pause;

/*!
 @method seekable
 @abstract
    Indicates whether it is possible to seek.
 */
- (BOOL)seekable;

/*!
 @method seekToTime:
 @abstract
    Equivalent:
        [self seekToTime:time result:nil];
 */
- (BOOL)seekToTime:(CMTime)time;

/*!
 @method seekToTime:result:
 @abstract
    Equivalent:
        [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
 */
- (BOOL)seekToTime:(CMTime)time result:(WKSeekResult)result;

/*!
 @method seekToTime:toleranceBefor:toleranceAfter:result:
 @abstract
    Moves the playback cursor.

 @discussion
    Use this method to seek to a specified time for the current player item and to be notified when the seek operation is complete. The result handler for any prior seek request that is still in process will be invoked immediately with the error parameter. If the new request completes without being interrupted by another seek request or by any other operation the specified result handler will be invoked without error.
 */
- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(WKSeekResult)result;

@end

#pragma mark - Renderer

@interface WKPlayer ()

/*!
 @property audioRenderer
 @abstract
    The renderer for audio frame.
 
 @discussion
    The life cycle is consistent with the player. The settings for the renderer will always take effect.
 */
- (WKAudioRenderer *)audioRenderer;

/*!
 @property videoRenderer
 @abstract
    The renderer for video frame.
 
 @discussion
    The life cycle is consistent with the player. The settings for the renderer will always take effect.
 */
- (WKVideoRenderer *)videoRenderer;

@end

#pragma mark - Notification

/*!
 @constant WKPlayerDidChangeInfosNotification
 @abstract
    A notification that fires whenever information changes.
 
 @discussion
    This notification will be triggered by a change in playback state or playback time.
 */
WKPLAYER_EXTERN NSNotificationName const WKPlayerDidChangeInfosNotification;

/*!
 @constant WKPlayerTimeInfoUserInfoKey
 @abstract
    The user info key to get the time info.
 */
WKPLAYER_EXTERN NSString * const WKPlayerTimeInfoUserInfoKey;

/*!
 @constant WKPlayerStateInfoUserInfoKey
 @abstract
    The user info key to get the state info.
 */
WKPLAYER_EXTERN NSString * const WKPlayerStateInfoUserInfoKey;

/*!
 @constant WKPlayerInfoActionUserInfoKey
 @abstract
    The user info key to get the actions that triggers the notification.
 */
WKPLAYER_EXTERN NSString * const WKPlayerInfoActionUserInfoKey;

@interface WKPlayer ()

/*!
 @method timeInfoFromUserInfo:
 @abstract
    To get the time info from user info.
 */
+ (WKTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo;

/*!
 @method timeInfoFromUserInfo:
 @abstract
    To get the state info from user info.
 */
+ (WKStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo;

/*!
 @method timeInfoFromUserInfo:
 @abstract
    To get the info action from user info.
 */
+ (WKInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo;

/*!
 @property actionMask
 @abstract
    Block unwanted actions.
 */
@property (nonatomic) WKInfoAction actionMask;

/*!
 @property minimumTimeInfoInterval
 @abstract
    Indicates the minimum interval at which the time info change triggers the notification.
    Default is 1.0f.
 */
@property (nonatomic) NSTimeInterval minimumTimeInfoInterval;

/*!
 @property notificationQueue
 @abstract
    Indicates in which queue the notification will be executed.
    Default is main queue.
 */
@property (nonatomic, strong) NSOperationQueue *notificationQueue;

@end
