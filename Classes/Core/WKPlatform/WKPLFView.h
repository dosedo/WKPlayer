//
//  WKPLFView.h
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPLFObject.h"
#import "WKPLFImage.h"
#import "WKPLFColor.h"

#if WKPLATFORM_TARGET_OS_MAC

typedef NSView WKPLFView;

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

typedef UIView WKPLFView;

#endif

void WKPLFViewSetBackgroundColor(WKPLFView *view, WKPLFColor *color);
void WKPLFViewInsertSubview(WKPLFView *superView, WKPLFView *subView, NSInteger index);

WKPLFImage * WKPLFViewGetCurrentSnapshot(WKPLFView *view);
