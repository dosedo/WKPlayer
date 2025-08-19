//
//  WKAudioPlayer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class WKAudioPlayer;

@protocol WKAudioPlayerDelegate <NSObject>

/**
 *
 */
- (void)audioPlayer:(WKAudioPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data numberOfFrames:(UInt32)numberOfFrames;

@optional
/**
 *
 */
- (void)audioPlayer:(WKAudioPlayer *)player willRender:(const AudioTimeStamp *)timestamp;

/**
 *
 */
- (void)audioPlayer:(WKAudioPlayer *)player didRender:(const AudioTimeStamp *)timestamp;

@end

@interface WKAudioPlayer : NSObject

/**
 *  Delegate.
 */
@property (nonatomic, weak) id<WKAudioPlayerDelegate> delegate;

/**
 *  Rate.
 */
@property (nonatomic) float rate;

/**
 *  Pitch.
 */
@property (nonatomic) float pitch;

/**
 *  Volume.
 */
@property (nonatomic) float volume;

/**
 *  ASBD.
 */
@property (nonatomic) AudioStreamBasicDescription asbd;

/**
 *  Playback.
 */
- (BOOL)isPlaying;

/**
 *  Play.
 */
- (void)play;

/**
 *  Pause.
 */
- (void)pause;

/**
 *  Flush.
 */
- (void)flush;

@end
