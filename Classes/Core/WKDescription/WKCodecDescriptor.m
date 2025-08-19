//
//  WKCodecDescriptor.m
//  WKPlayer
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKCodecDescriptor.h"

//wk add
#import "libavutil/display.h"

@interface WKCodecDescriptor ()

@property (nonatomic, copy, readonly) NSArray<WKTimeLayout *> *timeLayouts;

@end

@implementation WKCodecDescriptor

- (id)copyWithZone:(NSZone *)zone
{
    WKCodecDescriptor *obj = [[WKCodecDescriptor alloc] init];
    [self fillToDescriptor:obj];
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self->_scale = CMTimeMake(1, 1);
        self->_timebase = AV_TIME_BASE_Q;
        self->_timeRange = CMTimeRangeMake(kCMTimeNegativeInfinity, kCMTimePositiveInfinity);
    }
    return self;
}

- (void)appendTimeLayout:(WKTimeLayout *)timeLayout
{
    NSMutableArray *timeLayouts = [NSMutableArray arrayWithArray:self->_timeLayouts];
    [timeLayouts addObject:timeLayout];
    CMTime scale = CMTimeMake(1, 1);
    for (WKTimeLayout *obj in timeLayouts) {
        if (CMTIME_IS_NUMERIC(obj.scale)) {
            scale = WKCMTimeMultiply(scale, obj.scale);
        }
    }
    self->_scale = scale;
    self->_timeLayouts = timeLayouts;
    self->_timeRange = CMTimeRangeMake([timeLayout convertTimeStamp:self->_timeRange.start],
                                       [timeLayout convertDuration:self->_timeRange.duration]);
}

- (void)appendTimeRange:(CMTimeRange)timeRange
{
    for (WKTimeLayout *obj in self->_timeLayouts) {
        timeRange = CMTimeRangeMake([obj convertTimeStamp:timeRange.start],
                                    [obj convertDuration:timeRange.duration]);
    }
    self->_timeRange = WKCMTimeRangeGetIntersection(self->_timeRange, timeRange);
}
- (CMTime)convertDuration:(CMTime)duration
{
    for (WKTimeLayout *obj in self->_timeLayouts) {
        duration = [obj convertDuration:duration];
    }
    return duration;
}

- (CMTime)convertTimeStamp:(CMTime)timeStamp
{
    for (WKTimeLayout *obj in self->_timeLayouts) {
        timeStamp = [obj convertTimeStamp:timeStamp];
    }
    return timeStamp;
}

- (void)fillToDescriptor:(WKCodecDescriptor *)descriptor
{
    descriptor->_track = self->_track;
    descriptor->_scale = self->_scale;
    descriptor->_metadata = self->_metadata;
    descriptor->_timebase = self->_timebase;
    descriptor->_codecpar = self->_codecpar;
    descriptor->_timeRange = self->_timeRange;
    descriptor->_timeLayouts = [self->_timeLayouts copy];
}

- (BOOL)isEqualToDescriptor:(WKCodecDescriptor *)descriptor
{
    if (![self isEqualCodecContextToDescriptor:descriptor]) {
        return NO;
    }
    if (!CMTimeRangeEqual(descriptor->_timeRange, self->_timeRange)) {
        return NO;
    }
    if (descriptor->_timeLayouts.count != self->_timeLayouts.count) {
        return NO;
    }
    for (int i = 0; i < descriptor->_timeLayouts.count; i++) {
        WKTimeLayout *t1 = [descriptor->_timeLayouts objectAtIndex:i];
        WKTimeLayout *t2 = [self->_timeLayouts objectAtIndex:i];
        if (![t1 isEqualToTimeLayout:t2]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqualCodecContextToDescriptor:(WKCodecDescriptor *)descriptor
{
    if (!descriptor) {
        return NO;
    }
    if (descriptor->_track != self->_track) {
        return NO;
    }
    if (descriptor->_codecpar != self->_codecpar) {
        return NO;
    }
    if (av_cmp_q(descriptor->_timebase, self->_timebase) != 0) {
        return NO;
    }
    return YES;
}

#pragma mark - wk add 解决视频旋转问题,mov视频方向不对问题
-(void)setCodecpar:(AVCodecParameters *)codecpar{
    _codecpar = codecpar;
    
    [self setupRotation];
}

- (void)setMetadata:(NSDictionary *)metadata{
    _metadata = metadata;
    
    [self setupRotation];
}

- (void)setupRotation{
    
    if( _metadata == nil || _codecpar == nil ) {
        return;
    }
    
    AVPacketSideData *sideDatas = _codecpar->coded_side_data;
    int nums = _codecpar->nb_coded_side_data;
    for( int i=0; i<nums; i++ ) {
        AVPacketSideData sd = sideDatas[i];
        if( sd.type == AV_PKT_DATA_DISPLAYMATRIX ) {
            NSLog(@"display 矩阵");
            
            // 处理显示矩阵和旋转信息
            const int32_t *matrix = (const int32_t *)sd.data;
            
            // 计算旋转角度 (使用FFmpeg的av_display_rotation_get函数)
            double rotationDegrees = -av_display_rotation_get(matrix);
            
            // 规范化角度到 [0, 360) 范围
            rotationDegrees = fmod(rotationDegrees, 360.0);
            if (rotationDegrees < 0) {
                rotationDegrees += 360.0;
            }
            
            // 转换为整数并存储
            int rotation = (int16_t)rotationDegrees;
            NSLog(@"旋转角度: %d",rotation);
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_metadata];
            dic[@"rotate"] = @(rotation);
            _metadata = dic;
        }
        else if(sd.type == AV_PKT_DATA_DOVI_CONF ) {
            NSLog(@"display 设置");
        }
    }
}


@end
