//
//  WKPlayerActivity.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKActivity.h"

@interface WKActivity ()

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSMutableSet *targets;

@end

@implementation WKActivity

+ (void)addTarget:(id)target
{
    [[WKActivity activity] addTarget:target];
}

+ (void)removeTarget:(id)target
{
    [[WKActivity activity] removeTarget:target];
}

+ (instancetype)activity
{
    static WKActivity *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[WKActivity alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_targets = [NSMutableSet set];
    }
    return self;
}

- (void)addTarget:(id)target
{
    if (!target) {
        return;
    }
    [self->_lock lock];
    if (![self->_targets containsObject:[self token:target]]) {
        [self->_targets addObject:[self token:target]];
    }
    [self reload];
    [self->_lock unlock];
}

- (void)removeTarget:(id)target
{
    if (!target) {
        return;
    }
    [self->_lock lock];
    if ([self->_targets containsObject:[self token:target]]) {
        [self->_targets removeObject:[self token:target]];
    }
    [self reload];
    [self->_lock unlock];
}

- (void)reload
{
#if WKPLATFORM_TARGET_OS_IPHONE_OR_TV
    BOOL disable = self.objects.count <= 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].idleTimerDisabled = disable;
    });
#endif
}

- (id)token:(id)target
{
    return [NSString stringWithFormat:@"%p", target];
}

@end
