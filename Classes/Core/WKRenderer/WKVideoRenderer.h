//
//  WKVideoRenderer.h
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKVideoFrame.h"
#import "WKVRViewport.h"
#import "WKPLFImage.h"
#import "WKPLFView.h"

typedef NS_ENUM(NSUInteger, WKDisplayMode) {
    WKDisplayModePlane = 0,
    WKDisplayModeVR    = 1,
    WKDisplayModeVRBox = 2,
};

typedef NS_ENUM(NSUInteger, WKScalingMode) {
    WKScalingModeResize           = 0,
    WKScalingModeResizeAspect     = 1,
    WKScalingModeResizeAspectFill = 2,
};

@interface WKVideoRenderer : NSObject

/*!
 @method supportedPixelFormats
 @abstract
    Indicates all supported pixel formats.
*/
+ (NSArray<NSNumber *> *)supportedPixelFormats;

/*!
 @method isSupportedInputFormat:
 @abstract
    Indicates whether the input format is supported.
*/
+ (BOOL)isSupportedPixelFormat:(int)format;

/*!
 @property view
 @abstract
    Indicates the view that displays content.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, strong) WKPLFView *view;

/*!
 @property viewport
 @abstract
    Indicates the current vr viewport.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, strong, readonly) WKVRViewport *viewport;

/*!
 @property frameOutput
 @abstract
    Capture the video frame that will be rendered.
 
 @discussion
    Main thread only.
 */
@property (nonatomic, copy) void (^frameOutput)(WKVideoFrame *frame);

/*!
 @property preferredFramesPerSecond
 @abstract
    Indicates how many frames are rendered in one second.
    Default is 30.
 
 @discussion
    Main thread only.
 */
@property (nonatomic) NSInteger preferredFramesPerSecond;

/*!
 @property scalingMode
 @abstract
    Indicates current scaling mode.
 
 @discussion
    Main thread only.
 */
@property (nonatomic) WKScalingMode scalingMode;

/*!
 @property displayMode
 @abstract
    Indicates current display mode.
 
 @discussion
    Main thread only.
 */
@property (nonatomic) WKDisplayMode displayMode;

/*!
 @method currentImage
 @abstract
    Generate a screenshot of the current view.
 
 @discussion
    Main thread only.
 */
- (WKPLFImage *)currentImage;

@end
