//
//  WKCapacity.h
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKTime.h"

typedef struct WKCapacity {
    int size;
    int count;
    CMTime duration;
} WKCapacity;

WKCapacity WKCapacityCreate(void);
WKCapacity WKCapacityAdd(WKCapacity c1, WKCapacity c2);
WKCapacity WKCapacityMinimum(WKCapacity c1, WKCapacity c2);
WKCapacity WKCapacityMaximum(WKCapacity c1, WKCapacity c2);

BOOL WKCapacityIsEqual(WKCapacity c1, WKCapacity c2);
BOOL WKCapacityIsEnough(WKCapacity c1);
BOOL WKCapacityIsEmpty(WKCapacity c1);
