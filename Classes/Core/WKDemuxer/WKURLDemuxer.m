//
//  WKURLDemuxer.m
//  WKPlayer iOS
//
//  Created by Kidsmiless on 2025/08/18.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "WKURLDemuxer.h"
#import "WKPacket+Internal.h"
#import "WKTrack+Internal.h"
#import "WKOptions.h"
#import "WKMapping.h"
#import "WKFFmpeg.h"
#import "WKError.h"

#import "WKSMB2AVIOContextCreator.h"

@interface WKURLDemuxer ()

@property (nonatomic, readonly) CMTime basetime;
@property (nonatomic, readonly) CMTime seektime;
@property (nonatomic, readonly) CMTime seektimeMinimum;
@property (nonatomic, readonly) AVFormatContext *context;

@end

@implementation WKURLDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize metadata = _metadata;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self->_URL = [URL copy];
        self->_duration = kCMTimeInvalid;
        self->_basetime = kCMTimeInvalid;
        self->_seektime = kCMTimeInvalid;
        self->_seektimeMinimum = kCMTimeInvalid;
        self->_options = [WKOptions sharedOptions].demuxer.copy;
    }
    return self;
}

- (void)dealloc
{
    NSAssert(!self->_context, @"AVFormatContext is not released.");
}

#pragma mark - Control

- (id<WKDemuxable>)sharedDemuxer
{
    return self;
}

- (NSError *)open
{
    if (self->_context) {
        return nil;
    }
    WKFFmpegSetupIfNeeded();
    NSError *error = WKCreateFormatContext(&self->_context, self->_URL, self->_options.options, (__bridge void *)self, WKURLDemuxerInterruptHandler);
    if (error) {
        return error;
    }
    if (self->_context->duration > 0) {
        self->_duration = CMTimeMake(self->_context->duration, AV_TIME_BASE);
    }
    if (self->_context->metadata) {
        self->_metadata = WKDictionaryFF2NS(self->_context->metadata);
    }
    NSMutableArray<WKTrack *> *tracks = [NSMutableArray array];
    for (int i = 0; i < self->_context->nb_streams; i++) {
        AVStream *stream = self->_context->streams[i];
        WKMediaType type = WKMediaTypeFF2WK(stream->codecpar->codec_type);
        if (type == WKMediaTypeVideo && stream->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            type = WKMediaTypeUnknown;
        }
        WKTrack *obj = [[WKTrack alloc] initWithType:type index:i];
        obj.core = stream;
        [tracks addObject:obj];
    }
    self->_tracks = [tracks copy];
    return nil;
}

- (NSError *)close
{
    if (self->_context) {
        
        //wk add SMB2的支持
        if( [WKSMB2AVIOContextCreator isSMBURL:self.URL] ) {
            AVIOContext *ioCxt = (self->_context)->pb;
            ///必须手动释放缓存空间
            if( ioCxt->buffer ) {
                av_freep(&ioCxt->buffer);
            }
            
            if( ioCxt ){
                avio_context_free(&ioCxt);
            }
            
            avio_context_free(&ioCxt);
        }
        
        avformat_close_input(&self->_context);
        self->_context = NULL;
    }
    return nil;
}

- (NSError *)seekable
{
    if (self->_context) {
        if (self->_context->pb && self->_context->pb->seekable > 0) {
            return nil;
        }
        return WKCreateError(WKErrorCodeFormatNotSeekable, WKActionCodeFormatGetSeekable);
    }
    return WKCreateError(WKErrorCodeNoValidFormat, WKActionCodeFormatGetSeekable);
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    
    NSLog(@"TOOOOOO seek时间：%f",CMTimeGetSeconds(time));
    
    if (!CMTIME_IS_NUMERIC(time)) {
        return WKCreateError(WKErrorCodeInvlidTime, WKActionCodeFormatSeekFrame);
    }
    NSError *error = [self seekable];
    if (error) {
        return error;
    }
    if (self->_context) {
        int64_t timeStamp = CMTimeConvertScale(time, AV_TIME_BASE, kCMTimeRoundingMethod_RoundTowardZero).value;
        int ret = avformat_seek_file(self->_context, -1, INT64_MIN, timeStamp, INT64_MAX, AVSEEK_FLAG_BACKWARD);
        if (ret >= 0) {
            self->_seektime = time;
            self->_basetime = kCMTimeInvalid;
            if (CMTIME_IS_NUMERIC(toleranceBefor)) {
                self->_seektimeMinimum = CMTimeSubtract(time, CMTimeMaximum(toleranceBefor, kCMTimeZero));
            } else {
                self->_seektimeMinimum = kCMTimeInvalid;
            }
            self->_finishedTracks = nil;
        }
        return WKGetFFError(ret, WKActionCodeFormatSeekFrame);
    }
    return WKCreateError(WKErrorCodeNoValidFormat, WKActionCodeFormatSeekFrame);
}

- (NSError *)nextPacket:(WKPacket **)packet
{
    if (self->_context) {
        WKPacket *pkt = [WKPacket packet];
        int ret = av_read_frame(self->_context, pkt.core);
        if (ret < 0) {
            [pkt unlock];
        } else {
            AVStream *stream = self->_context->streams[pkt.core->stream_index];
            
            ///wk add
            {
                if (CMTIME_IS_INVALID(self->_basetime)) {
                    
                    ///若是视频，则需判断seek后是否是视频包，解决seek问题
                    BOOL isVideoFile = NO;
                    for( int i=0; i<self->_context->nb_streams; i++ ) {
                        WKMediaType streamType = WKMediaTypeFF2WK(self->_context->streams[i]->codecpar->codec_type);
                        if( streamType == WKMediaTypeVideo ) {
                            isVideoFile = YES;
                            break;
                        }
                    }
                    
                    ///以下代码解决(部分文件)seek后失败，从0播放的问题
                    WKMediaType streamType = WKMediaTypeFF2WK(stream->codecpar->codec_type);
                    // 如果basetime还没有设置，并且这个包不是视频流，则跳过这个包
                    if ( streamType != WKMediaTypeVideo && isVideoFile) {
                        NSLog(@"seek后跳过首包不是视频的包");
                        [pkt unlock];
                        return nil;
                    }
                    
                    // wk add HEVC seek失败 特殊处理
                    BOOL isHEVC = stream->codecpar->codec_id == AV_CODEC_ID_MJPEG;//AV_CODEC_ID_HEVC;
                    
                    // wk add HEVC 参数集包跳过
                    if (isHEVC && (pkt.core->flags & AV_PKT_FLAG_KEY) == 0) {
                        NSLog(@"跳过 HEVC 非关键帧参数包");
                        [pkt unlock];
                        return nil;
                    }
                      
                    // wk add
                    if (isHEVC && (pkt.core->flags & AV_PKT_FLAG_KEY) && pkt.core->pts == 0) {
                        NSLog(@"跳过HEVC视频流中pts为0的关键帧包");
                        [pkt unlock];
                        return nil;
                    }
                }
            }
            
            if (CMTIME_IS_INVALID(self->_basetime)) {
                if (pkt.core->pts == AV_NOPTS_VALUE) {
                    self->_basetime = kCMTimeZero;
                } else {
                    self->_basetime = CMTimeMake(pkt.core->pts * stream->time_base.num, stream->time_base.den);
                }
            }
            
            
            //wk add,解决时间值不正确的问题, 导致崩溃
            //这是只有self->_basetime.value不对
            if(self->_basetime.value == LLONG_MIN) {
                NSLog(@"无效的basetime");
                
                self->_basetime = CMTimeMake(pkt.core->pts * stream->time_base.num, stream->time_base.den);
            }
            
            
            /*
            CMTime start = self->_basetime;
            if (CMTIME_IS_NUMERIC(self->_seektime)) {
                start = CMTimeMinimum(start, self->_seektime);
            }
            if (CMTIME_IS_NUMERIC(self->_seektimeMinimum)) {
                start = CMTimeMaximum(start, self->_seektimeMinimum);
            }*/
            // 修改后的 start 赋值逻辑
            CMTime start;
            if (CMTIME_IS_NUMERIC(self->_seektime)) {
                // 当处于 seek 状态时，start 的值应该等于 self->_seektime
                start = self->_seektime;
                
                // 确保 start 不小于 seektimeMinimum（如果有设置）
                if (CMTIME_IS_NUMERIC(self->_seektimeMinimum)) {
                    start = CMTimeMaximum(start, self->_seektimeMinimum);
                }
            } else {
                // 非 seek 状态时，使用 basetime
                start = self->_basetime;
                
                // 确保 start 不小于 seektimeMinimum（如果有设置）
                if (CMTIME_IS_NUMERIC(self->_seektimeMinimum)) {
                    start = CMTimeMaximum(start, self->_seektimeMinimum);
                }
            }
            
            
            NSLog(@"开始时间：%f,seek时间：%f,min时间：%f", CMTimeGetSeconds(start), CMTimeGetSeconds(self->_seektime), CMTimeGetSeconds(self->_seektimeMinimum));
            
            WKCodecDescriptor *cd = [[WKCodecDescriptor alloc] init];
            cd.track = [self->_tracks objectAtIndex:pkt.core->stream_index];
            cd.metadata = WKDictionaryFF2NS(stream->metadata);
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            [cd appendTimeRange:CMTimeRangeMake(start, kCMTimePositiveInfinity)];
            [pkt setCodecDescriptor:cd];
            [pkt fill];
            *packet = pkt;
        }
        NSError *error = WKGetFFError(ret, WKActionCodeFormatReadFrame);
        if (error.code == WKErrorCodeDemuxerEndOfFile) {
            self->_finishedTracks = self->_tracks.copy;
        }
        return error;
    }
    return WKCreateError(WKErrorCodeNoValidFormat, WKActionCodeFormatReadFrame);
}

#pragma mark - AVFormatContext

static NSError * WKCreateFormatContext(AVFormatContext **formatContext, NSURL *URL, NSDictionary *options, void *opaque, int (*callback)(void *))
{
    AVFormatContext *ctx = avformat_alloc_context();
    if (!ctx) {
        return WKCreateError(WKErrorCodeNoValidFormat, WKActionCodeFormatCreate);
    }
    ctx->interrupt_callback.callback = callback;
    ctx->interrupt_callback.opaque = opaque;
    NSString *URLString = URL.isFileURL ? URL.path : URL.absoluteString;
    
    ///wk add 添加libsmb2库的支持
    const char *utf8URL = URLString.UTF8String;
    if( [WKSMB2AVIOContextCreator isSMBURL:URL] ){
        int bufferSize = 100*1024*1024;  //100M缓冲
        AVIOContext *io_ctx = [WKSMB2AVIOContextCreator createAVIOContextForSMBURL:URL bufferSize:bufferSize];
        if (io_ctx) {
            ctx->pb = io_ctx;
            
            utf8URL = NULL; // 不再传递 URL 字符串
        }else {
            // 错误处理
            if (ctx) {
                avformat_free_context(ctx);
            }
            NSError *error = [NSError errorWithDomain:@"URL Demuxer Domain" code:-1 userInfo:@{@"message":@"Failed to create AVIOContext"}];
            return error;
        }
    }
    
    AVDictionary *opts = WKDictionaryNS2FF(options);
    if ([URLString.lowercaseString hasPrefix:@"rtmp"] ||
        [URLString.lowercaseString hasPrefix:@"rtsp"]) {
        av_dict_set(&opts, "timeout", NULL, 0);
    }
    int success = avformat_open_input(&ctx, utf8URL, NULL, &opts);
    if (opts) {
        av_dict_free(&opts);
    }
    NSError *error = WKGetFFError(success, WKActionCodeFormatOpenInput);
    if (error) {
        if (ctx) {
            avformat_free_context(ctx);
        }
        return error;
    }
    success = avformat_find_stream_info(ctx, NULL);
    error = WKGetFFError(success, WKActionCodeFormatFindStreamInfo);
    if (error) {
        if (ctx) {
            avformat_close_input(&ctx);
            avformat_free_context(ctx);
        }
        return error;
    }
    *formatContext = ctx;
    return nil;
}

static int WKURLDemuxerInterruptHandler(void *demuxer)
{
    WKURLDemuxer *self = (__bridge WKURLDemuxer *)demuxer;
    if ([self->_delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        BOOL ret = [self->_delegate demuxableShouldAbortBlockingFunctions:self];
        return ret ? 1 : 0;
    }
    return 0;
}

@end
