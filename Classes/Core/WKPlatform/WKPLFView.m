//
//  WKPLFView.m
//  WKPlatform
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKPLFView.h"
#import "WKPLFScreen.h"

#if WKPLATFORM_TARGET_OS_MAC

void WKPLFViewSetBackgroundColor(WKPLFView *view, WKPLFColor *color)
{
    view.wantsLayer = YES;
    view.layer.backgroundColor = color.CGColor;
}

void WKPLFViewInsertSubview(WKPLFView *superView, WKPLFView *subView, NSInteger index)
{
    if (superView.subviews.count > index) {
        NSView *obj = [superView.subviews objectAtIndex:index];
        [superView addSubview:subView positioned:NSWindowBelow relativeTo:obj];
    } else {
        [superView addSubview:subView];
    }
}

WKPLFImage *WKPLFViewGetCurrentSnapshot(WKPLFView *view)
{
    CGSize size = CGSizeMake(view.bounds.size.width * WKPLFScreenGetScale(),
                             view.bounds.size.height * WKPLFScreenGetScale());
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil,
                                                 size.width,
                                                 size.height,
                                                 8,
                                                 size.width * 4,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    [view.layer renderInContext:context];
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:size];
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    return image;
}

#elif WKPLATFORM_TARGET_OS_IPHONE_OR_TV

void WKPLFViewSetBackgroundColor(WKPLFView *view, WKPLFColor *color)
{
    view.backgroundColor = color;
}

void WKPLFViewInsertSubview(WKPLFView *superView, WKPLFView *subView, NSInteger index)
{
    [superView insertSubview:subView atIndex:index];
}

WKPLFImage * WKPLFViewGetCurrentSnapshot(WKPLFView *view)
{
    CGSize size = CGSizeMake(view.bounds.size.width * WKPLFScreenGetScale(),
                             view.bounds.size.height * WKPLFScreenGetScale());
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [view drawViewHierarchyInRect:rect afterScreenUpdates:YES];
    WKPLFImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#endif
