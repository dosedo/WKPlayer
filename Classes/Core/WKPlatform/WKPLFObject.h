//
//  WKPLFObject.h
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#ifndef WKPLFObject_h
#define WKPLFObject_h

#import "WKPLFTargets.h"

#if WKPLATFORM_TARGET_OS_MAC

#import <Cocoa/Cocoa.h>

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

#import <UIKit/UIKit.h>

#endif

#endif /* WKPLFObject_h */
