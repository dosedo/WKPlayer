//
//  WKPlayerHeader.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#ifndef WKPlayerHeader_h
#define WKPlayerHeader_h

#import <Foundation/Foundation.h>

#if __has_include(<WKPlayer/WKPlayer.h>)

FOUNDATION_EXPORT double WKPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char WKPlayerVersionString[];

#import <WKPlayer/WKTime.h>
#import <WKPlayer/WKError.h>
#import <WKPlayer/WKDefines.h>

#import <WKPlayer/WKOptions.h>
#import <WKPlayer/WKDemuxerOptions.h>
#import <WKPlayer/WKDecoderOptions.h>
#import <WKPlayer/WKProcessorOptions.h>

#import <WKPlayer/WKAudioDescriptor.h>
#import <WKPlayer/WKVideoDescriptor.h>

#import <WKPlayer/WKAsset.h>
#import <WKPlayer/WKURLAsset.h>
#import <WKPlayer/WKMutableAsset.h>

#import <WKPlayer/WKTrack.h>
#import <WKPlayer/WKMutableTrack.h>
#import <WKPlayer/WKTrackSelection.h>

#import <WKPlayer/WKSegment.h>
#import <WKPlayer/WKURLSegment.h>
#import <WKPlayer/WKPaddingSegment.h>

#import <WKPlayer/WKDemuxable.h>
#import <WKPlayer/WKURLDemuxer.h>

#import <WKPlayer/WKPlayerItem.h>
#import <WKPlayer/WKFrameReader.h>
#import <WKPlayer/WKFrameOutput.h>
#import <WKPlayer/WKPacketOutput.h>

#import <WKPlayer/WKClock.h>
#import <WKPlayer/WKVRViewport.h>
#import <WKPlayer/WKAudioRenderer.h>
#import <WKPlayer/WKVideoRenderer.h>

#import <WKPlayer/WKData.h>
#import <WKPlayer/WKFrame.h>
#import <WKPlayer/WKCapacity.h>
#import <WKPlayer/WKAudioFrame.h>
#import <WKPlayer/WKVideoFrame.h>

#import <WKPlayer/WKProcessor.h>
#import <WKPlayer/WKAudioProcessor.h>
#import <WKPlayer/WKVideoProcessor.h>

#import <WKPlayer/WKSonic.h>
#import <WKPlayer/WKSWScale.h>
#import <WKPlayer/WKSWResample.h>
#import <WKPlayer/WKAudioMixer.h>
#import <WKPlayer/WKAudioMixerUnit.h>
#import <WKPlayer/WKAudioFormatter.h>

#import <WKPlayer/WKPLFView.h>
#import <WKPlayer/WKPLFImage.h>
#import <WKPlayer/WKPLFColor.h>
#import <WKPlayer/WKPLFObject.h>
#import <WKPlayer/WKPLFScreen.h>
#import <WKPlayer/WKPLFTargets.h>

#else

#import "WKTime.h"
#import "WKError.h"
#import "WKDefines.h"

#import "WKOptions.h"
#import "WKDemuxerOptions.h"
#import "WKDecoderOptions.h"
#import "WKProcessorOptions.h"

#import "WKAudioDescriptor.h"
#import "WKVideoDescriptor.h"

#import "WKAsset.h"
#import "WKURLAsset.h"
#import "WKMutableAsset.h"

#import "WKTrack.h"
#import "WKMutableTrack.h"
#import "WKTrackSelection.h"

#import "WKSegment.h"
#import "WKURLSegment.h"
#import "WKPaddingSegment.h"

#import "WKDemuxable.h"
#import "WKURLDemuxer.h"

#import "WKPlayerItem.h"
#import "WKFrameReader.h"
#import "WKFrameOutput.h"
#import "WKPacketOutput.h"

#import "WKClock.h"
#import "WKVRViewport.h"
#import "WKAudioRenderer.h"
#import "WKVideoRenderer.h"

#import "WKData.h"
#import "WKFrame.h"
#import "WKCapacity.h"
#import "WKAudioFrame.h"
#import "WKVideoFrame.h"

#import "WKProcessor.h"
#import "WKAudioProcessor.h"
#import "WKVideoProcessor.h"

#import "WKSonic.h"
#import "WKSWScale.h"
#import "WKSWResample.h"
#import "WKAudioMixer.h"
#import "WKAudioMixerUnit.h"
#import "WKAudioFormatter.h"

#import "WKPLFView.h"
#import "WKPLFImage.h"
#import "WKPLFColor.h"
#import "WKPLFObject.h"
#import "WKPLFScreen.h"
#import "WKPLFTargets.h"

#endif

#endif /* WKPlayerHeader_h */
