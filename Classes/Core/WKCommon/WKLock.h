//
//  WKLock.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDefines.h"

BOOL WKLockEXE00(id<NSLocking> locking, void (^run)(void));
BOOL WKLockEXE10(id<NSLocking> locking, WKBlock (^run)(void));
BOOL WKLockEXE11(id<NSLocking> locking, WKBlock (^run)(void), BOOL (^finish)(WKBlock block));

BOOL WKLockCondEXE00(id<NSLocking> locking, BOOL (^verify)(void), void (^run)(void));
BOOL WKLockCondEXE10(id<NSLocking> locking, BOOL (^verify)(void), WKBlock (^run)(void));
BOOL WKLockCondEXE11(id<NSLocking> locking, BOOL (^verify)(void), WKBlock (^run)(void), BOOL (^finish)(WKBlock block));
