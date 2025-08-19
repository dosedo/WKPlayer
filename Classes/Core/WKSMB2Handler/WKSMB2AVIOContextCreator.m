//
//  WKSMB2AVIOContextCreator.m
//  WKPlayer
//
//  Created by wkun on 2025/8/18.
//

#import "WKSMB2AVIOContextCreator.h"
#import "WKSMB2ConnectionPool.h"
#import "WKSMB2URLComponents.h"

// 只有在启用 SMB2 时才编译相关代码
#define ENABLE_SMB2_SUPPORT 1
#ifdef ENABLE_SMB2_SUPPORT
#import <smb2/libsmb2.h>

// SMB2 处理器的内部实现
@interface SMB2Handler : NSObject

@property (nonatomic, readonly) struct smb2_context *smb2;
@property (nonatomic, readonly) struct smb2fh *file;
@property (nonatomic, readonly) int64_t fileSize;

- (instancetype)initWithURL:(NSURL *)url;
- (BOOL)openFile;
- (void)closeFile;
- (int)read:(uint8_t *)buf size:(int)bufSize;
- (int64_t)seek:(int64_t)offset whence:(int)whence;

@end

@implementation SMB2Handler {
    NSURL *_url;
    BOOL _isOpen;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _url = [url copy];
        _isOpen = NO;
    }
    return self;
}

- (BOOL)openFile {
    if (_isOpen) return YES;
    
    _smb2 = [WKSMB2ConnectionPool.sharedPool connectionForSmbURL:_url];
    if (!_smb2) {
        NSLog(@"[SMB2] Failed to get shared SMB2 context");
        return NO;
    }

    SMB2URLComponents *com = [SMB2URLComponents componentsWithSmbURL:_url];
    const char *filepath = com.filePath.UTF8String;
    _file = smb2_open(_smb2, filepath, O_RDONLY);
    if (!_file) {
        [WKSMB2ConnectionPool.sharedPool releaseConnectionForSmbURL:_url];
        _smb2 = NULL;
        NSLog(@"[SMB2] Failed to open file");
        return NO;
    }

    struct smb2_stat_64 st;
    smb2_fstat(_smb2, _file, &st);
    _fileSize = st.smb2_size;
    
    _isOpen = YES;
    return YES;
}

- (void)closeFile {
    if (!_isOpen) return;
    
    if (_file) {
        smb2_close(_smb2, _file);
        _file = NULL;
    }
    
    if (_smb2) {
        [WKSMB2ConnectionPool.sharedPool releaseConnectionForSmbURL:_url];
        _smb2 = NULL;
    }
    
    _isOpen = NO;
}

- (int)read:(uint8_t *)buf size:(int)bufSize {
    if (!_isOpen) return AVERROR_EOF;
    int bytesRead = smb2_read(_smb2, _file, buf, bufSize);
    return bytesRead > 0 ? bytesRead : AVERROR_EOF;
}

- (int64_t)seek:(int64_t)offset whence:(int)whence {
    if (!_isOpen) return -1;
    if (whence == AVSEEK_SIZE) return _fileSize;
    return smb2_lseek(_smb2, _file, offset, whence, NULL);
}

- (void)dealloc {
    [self closeFile];
}

@end

// AVIOContext 回调函数
static int smb2_read_packet(void *opaque, uint8_t *buf, int buf_size) {
    SMB2Handler *handler = (__bridge SMB2Handler *)opaque;
    return [handler read:buf size:buf_size];
}

static int64_t smb2_seek(void *opaque, int64_t offset, int whence) {
    SMB2Handler *handler = (__bridge SMB2Handler *)opaque;
    return [handler seek:offset whence:whence];
}

#endif

@implementation WKSMB2AVIOContextCreator

+ (BOOL)isSMBURL:(NSURL *)url {
    return [url.absoluteString hasPrefix:@"smb2:"];
}

+ (AVIOContext *)createAVIOContextForSMBURL:(NSURL *)url bufferSize:(int)bufferSize {
#ifdef ENABLE_SMB2_SUPPORT
    if (![self isSMBURL:url]) {
        return NULL;
    }
    
    @try {
        // 创建 SMB2 处理器
        SMB2Handler *handler = [[SMB2Handler alloc] initWithURL:url];
        if (![handler openFile]) {
            return NULL;
        }
        
        // 创建 AVIOContext
        unsigned char *io_buffer = av_malloc(bufferSize);
        AVIOContext *avio_ctx = avio_alloc_context(
            io_buffer, bufferSize,
            0, (__bridge_retained void *)handler,
            &smb2_read_packet, NULL, &smb2_seek
        );
        
        return avio_ctx;
    } @catch (NSException *exception) {
        NSLog(@"[SMB2] Error creating AVIOContext: %@", exception);
        return NULL;
    }
#else
    return NULL;
#endif
}

@end
