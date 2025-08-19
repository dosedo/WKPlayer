//
//  WKAudioFormatter.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKAudioDescriptor.h"
#import "WKAudioFrame.h"

@interface WKAudioFormatter : NSObject

/**
 *
 */
@property (nonatomic, copy) WKAudioDescriptor *descriptor;

/**
 *
 */
- (WKAudioFrame *)format:(WKAudioFrame *)frame;

/**
 *
 */
- (WKAudioFrame *)finish;

/**
 *
 */
- (void)flush;

@end
