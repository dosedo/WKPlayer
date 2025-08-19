//
//  WKDecodeContext.m
//  KTVMediaKitDemo
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKDecodeContext.h"
#import "WKPacket+Internal.h"
#import "WKObjectQueue.h"
#import "WKDecodable.h"

static WKPacket *kFlushPacket = nil;
static WKPacket *kFinishPacket = nil;
static NSInteger kMaxPredecoderCount = 2;

@interface WKDecodeContextUnit : NSObject

@property (nonatomic, strong) NSArray *frames;
@property (nonatomic, strong) id<WKDecodable> decoder;
@property (nonatomic, strong) WKObjectQueue *packetQueue;
@property (nonatomic, strong) WKCodecDescriptor *codecDescriptor;

@end

@implementation WKDecodeContextUnit

- (void)dealloc
{
    for (WKFrame *obj in self->_frames) {
        [obj unlock];
    }
    self->_frames = nil;
}

@end

@interface WKDecodeContext ()

@property (nonatomic, readonly) BOOL needsFlush;
@property (nonatomic, readonly) NSInteger decodeIndex;
@property (nonatomic, readonly) NSInteger predecodeIndex;
@property (nonatomic, strong, readonly) Class decoderClass;
@property (nonatomic, strong, readonly) NSMutableArray<id<WKDecodable>> *decoders;
@property (nonatomic, strong, readonly) NSMutableArray<WKDecodeContextUnit *> *units;

@end

@implementation WKDecodeContext

- (instancetype)initWithDecoderClass:(Class)decoderClass
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            kFlushPacket = [[WKPacket alloc] init];
            kFinishPacket = [[WKPacket alloc] init];
            [kFlushPacket lock];
            [kFinishPacket lock];
        });
        self->_needsFlush = NO;
        self->_decodeIndex = 0;
        self->_predecodeIndex = 0;
        self->_decoderClass = decoderClass;
        self->_decodeTimeStamp = kCMTimeInvalid;
        self->_units = [NSMutableArray array];
        self->_decoders = [NSMutableArray array];
    }
    return self;
}

- (WKCapacity)capacity
{
    WKCapacity capacity = WKCapacityCreate();
    for (WKDecodeContextUnit *obj in self->_units) {
        capacity = WKCapacityAdd(capacity, obj.packetQueue.capacity);
    }
    return capacity;
}

- (void)putPacket:(WKPacket *)packet
{
    WKDecodeContextUnit *unit = self->_units.lastObject;
    if (![unit.codecDescriptor isEqualToDescriptor:packet.codecDescriptor]) {
        unit = [[WKDecodeContextUnit alloc] init];
        unit.packetQueue = [[WKObjectQueue alloc] init];
        unit.codecDescriptor = packet.codecDescriptor.copy;
        [self->_units addObject:unit];
    }
    [unit.packetQueue putObjectSync:packet];
}

- (BOOL)needsPredecode
{
    NSInteger count = 0;
    for (NSInteger i = self->_decodeIndex + 1; i < self->_units.count; i++) {
        if (count >= kMaxPredecoderCount) {
            return NO;
        }
        WKDecodeContextUnit *unit = self->_units[i];
        WKCodecDescriptor *cd = unit.codecDescriptor;
        if (cd.codecpar &&
            cd.codecpar->codec_type == AVMEDIA_TYPE_VIDEO &&
            (cd.codecpar->codec_id == AV_CODEC_ID_H264 ||
             cd.codecpar->codec_id == AV_CODEC_ID_H265)) {
            count += 1;
            if (unit.frames.count > 0) {
                continue;
            }
            self->_predecodeIndex = i;
            return unit.packetQueue.capacity.count > 0;
        }
    }
    return NO;
}

- (void)predecode:(WKBlock)lock unlock:(WKBlock)unlock
{
    WKPacket *packet = nil;
    WKDecodeContextUnit *unit = self->_units[self->_predecodeIndex];
    if ([unit.packetQueue getObjectAsync:&packet]) {
        [self setDecoderIfNeeded:unit];
        id<WKDecodable> decoder = unit.decoder;
        unlock();
        NSArray *frames = [decoder decode:packet];
        lock();
        unit.frames = frames;
        [packet unlock];
    }
}

- (NSArray<WKFrame *> *)decode:(WKBlock)lock unlock:(WKBlock)unlock
{
    NSMutableArray *frames = [NSMutableArray array];
    NSInteger index = 0;
    WKPacket *packet = nil;
    WKDecodeContextUnit *unit = nil;
    for (NSInteger i = 0; i < self->_units.count; i++) {
        WKDecodeContextUnit *obj = self->_units[i];
        if ([obj.packetQueue getObjectAsync:&packet]) {
            index = i;
            unit = obj;
            break;
        }
    }
    NSAssert(packet, @"Invalid Packet.");
    if (packet == kFlushPacket) {
        self->_needsFlush = NO;
        self->_decodeIndex = 0;
        self->_predecodeIndex = 0;
        self->_decodeTimeStamp = kCMTimeInvalid;
        [self->_units removeObjectAtIndex:0];
    } else if (packet == kFinishPacket) {
        [self->_units removeLastObject];
        for (NSInteger i = self->_decodeIndex; i < self->_units.count; i++) {
            WKDecodeContextUnit *obj = self->_units[i];
            [frames addObjectsFromArray:obj.frames];
            [frames addObjectsFromArray:[obj.decoder finish]];
            [self removeDecoderIfNeeded:obj];
        }
        [self->_units removeAllObjects];
    } else {
        self->_decodeTimeStamp = packet.decodeTimeStamp;
        if (self->_decodeIndex < index) {
            for (NSInteger i = self->_decodeIndex; i < MIN(index, self->_units.count); i++) {
                WKDecodeContextUnit *obj = self->_units[i];
                [frames addObjectsFromArray:obj.frames];
                [frames addObjectsFromArray:[obj.decoder finish]];
                [self removeDecoderIfNeeded:obj];
            }
            [frames addObjectsFromArray:unit.frames];
            unit.frames = nil;
            self->_decodeIndex = index;
        }
        [self setDecoderIfNeeded:unit];
        id<WKDecodable> decoder = unit.decoder;
        unlock();
        [frames addObjectsFromArray:[decoder decode:packet]];
        lock();
        [packet unlock];
    }
    if (self->_needsFlush) {
        for (WKFrame *obj in frames) {
            [obj unlock];
        }
        [frames removeAllObjects];
    }
    return frames.count ? frames.copy : nil;
}

- (void)setNeedsFlush
{
    self->_needsFlush = YES;
    for (WKDecodeContextUnit *obj in self->_units) {
        [self removeDecoderIfNeeded:obj];
    }
    [self->_units removeAllObjects];
    WKDecodeContextUnit *unit = [[WKDecodeContextUnit alloc] init];
    unit.packetQueue = [[WKObjectQueue alloc] init];
    unit.codecDescriptor = [[WKCodecDescriptor alloc] init];
    [unit.packetQueue putObjectSync:kFlushPacket];
    [self->_units addObject:unit];
}

- (void)markAsFinished
{
    WKDecodeContextUnit *unit = [[WKDecodeContextUnit alloc] init];
    unit.packetQueue = [[WKObjectQueue alloc] init];
    unit.codecDescriptor = [[WKCodecDescriptor alloc] init];
    [unit.packetQueue putObjectSync:kFinishPacket];
    [self->_units addObject:unit];
}

- (void)destory
{
    [self->_units removeAllObjects];
}

- (void)setDecoderIfNeeded:(WKDecodeContextUnit *)unit
{
    if (!unit.decoder) {
        if (self->_decoders.count) {
            unit.decoder = self->_decoders.lastObject;
            [unit.decoder flush];
            [self->_decoders removeLastObject];
        } else {
            unit.decoder = [[self->_decoderClass alloc] init];
            unit.decoder.options = self->_options;
        }
    }
}

- (void)removeDecoderIfNeeded:(WKDecodeContextUnit *)unit
{
    if (unit.decoder) {
        [self->_decoders addObject:unit.decoder];
        unit.decoder = nil;
    }
}

@end
