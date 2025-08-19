//
//  WKPLFScreen.h
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPLFObject.h"

#if WKPLATFORM_TARGET_OS_MAC

typedef NSScreen WKPLFScreen;

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

typedef UIScreen WKPLFScreen;

#endif

CGFloat WKPLFScreenGetScale(void);
