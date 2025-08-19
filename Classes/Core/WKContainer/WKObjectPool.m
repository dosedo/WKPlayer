//
//  WKObjectPool.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKObjectPool.h"

@interface WKObjectPool ()

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSMutableSet<id<WKData>> *> *pool;

@end

@implementation WKObjectPool

+ (instancetype)sharedPool
{
    static WKObjectPool *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[WKObjectPool alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_pool = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id<WKData>)objectWithClass:(Class)class reuseName:(NSString *)reuseName
{
    [self->_lock lock];
    NSMutableSet <id<WKData>> *set = [self->_pool objectForKey:reuseName];
    if (!set) {
        set = [NSMutableSet set];
        [self->_pool setObject:set forKey:reuseName];
    }
    id<WKData> object = set.anyObject;
    if (object) {
        [set removeObject:object];
    } else {
        object = [[class alloc] init];
    }
    [object lock];
    object.reuseName = reuseName;
    [self->_lock unlock];
    return object;
}

- (void)comeback:(id<WKData>)object
{
    [self->_lock lock];
    NSMutableSet <id<WKData>> *set = [self->_pool objectForKey:object.reuseName];
    if (![set containsObject:object]) {
        [set addObject:object];
        [object clear];
    }
    [self->_lock unlock];
}

- (void)flush
{
    [self->_lock lock];
    [self->_pool removeAllObjects];
    [self->_lock unlock];
}

@end
