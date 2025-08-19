//
//  WKPLFScreen.m
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPLFScreen.h"

#if WKPLATFORM_TARGET_OS_MAC

CGFloat WKPLFScreenGetScale(void)
{
    return [NSScreen mainScreen].backingScaleFactor;
}

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

CGFloat WKPLFScreenGetScale(void)
{
    return [UIScreen mainScreen].scale;
}

#endif
