//
//  WKSMB2ConnectionPool.m
//  WKPlayer
//
//  Created by wkun on 2025/8/18.
//

#import <Foundation/Foundation.h>
#import "WKSMB2ConnectionPool.h"
#import "WKSMB2URLComponents.h"
#import "smb2/libsmb2.h"

// 连接唯一标识键（内部使用）
@interface SMB2ConnectionKey : NSObject <NSCopying>
@property (nonatomic, copy) NSString *ip;
@property (nonatomic, copy) NSString *share;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end

@implementation SMB2ConnectionKey

- (instancetype)initWithIP:(NSString *)ip
                    share:(NSString *)share
                 username:(NSString *)username
                 password:(NSString *)password {
    if (self = [super init]) {
        _ip = [ip copy];
        _share = [share copy];
        _username = [username copy];
        _password = [password copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[SMB2ConnectionKey alloc] initWithIP:_ip share:_share username:_username password:_password];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[SMB2ConnectionKey class]]) return NO;
    
    SMB2ConnectionKey *other = (SMB2ConnectionKey *)object;
    return [self.ip isEqualToString:other.ip] &&
           [self.share isEqualToString:other.share] &&
           [self.username isEqualToString:other.username] &&
           [self.password isEqualToString:other.password];
}

- (NSUInteger)hash {
    return self.ip.hash ^ self.share.hash ^ self.username.hash ^ self.password.hash;
}

@end

// 连接包装器（管理引用计数）
@interface SMB2ConnectionWrapper : NSObject
@property (nonatomic, assign) struct smb2_context *smb2Context;
@property (nonatomic, assign) NSInteger refCount;
@property (nonatomic, strong) SMB2ConnectionKey *key;
@end

@implementation SMB2ConnectionWrapper

- (instancetype)initWithSMB2Context:(struct smb2_context *)ctx key:(SMB2ConnectionKey *)key {
    if (self = [super init]) {
        _smb2Context = ctx;
        _key = key;
        _refCount = 1;
    }
    return self;
}

- (void)dealloc {
    if (_smb2Context) {
        smb2_disconnect_share(_smb2Context);
        smb2_destroy_context(_smb2Context);
    }
}

@end



@implementation WKSMB2ConnectionPool {
    NSMutableDictionary<SMB2ConnectionKey *, SMB2ConnectionWrapper *> *_connections;
    dispatch_queue_t _syncQueue;
}

+ (instancetype)sharedPool {
    static WKSMB2ConnectionPool *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _connections = [NSMutableDictionary dictionary];
        _syncQueue = dispatch_queue_create("com.example.SMB2PoolQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (struct smb2_context *)connectionForIP:(NSString *)ip
                                  share:(NSString *)share
                               username:(NSString *)username
                               password:(NSString *)password {
    BOOL isValid = [self valid:ip] && [self valid:share] && [self valid:username] && [self valid:password];
    if( !isValid ) {
        NSLog(@"connectionForIP SMB2ConnectionPool参数错误");
        return NULL;
    }
    
    SMB2ConnectionKey *key = [[SMB2ConnectionKey alloc] initWithIP:ip
                                                           share:share
                                                        username:username
                                                        password:password];
    
    __block SMB2ConnectionWrapper *wrapper = nil;
    
    // 线程安全访问
    dispatch_sync(_syncQueue, ^{
        wrapper = _connections[key];
        
        if (!wrapper) {
            // 创建新连接
            struct smb2_context *ctx = smb2_init_context();
            if (!ctx) return;
            
            // 配置连接参数
            smb2_set_user(ctx, username.UTF8String);
            smb2_set_password(ctx, password.UTF8String);
            
            int ret = smb2_connect_share(ctx, ip.UTF8String, share.UTF8String, username.UTF8String);
            
            ///链接成功
            if( ret == 0 ) {
                // 创建包装器
                wrapper = [[SMB2ConnectionWrapper alloc] initWithSMB2Context:ctx key:key];
                _connections[key] = wrapper;
            }
            else{
                smb2_destroy_context(ctx);
                NSLog(@"链接smb失败：%d",ret);
            }
            
            
        } else {
            // 增加现有连接的引用计数
            wrapper.refCount++;
        }
    });
    
    return wrapper ? wrapper.smb2Context : NULL;
}

- (void)releaseConnectionForIP:(NSString *)ip share:(NSString *)share {
    
    BOOL isValid = [self valid:ip] && [self valid:share];
    if( !isValid ) {
        NSLog(@"releaseConnectionForIP SMB2ConnectionPool参数错误");
        return;
    }
    
    dispatch_sync(_syncQueue, ^{
        // 查找匹配的连接
        SMB2ConnectionKey *targetKey = nil;
        for (SMB2ConnectionKey *key in _connections.allKeys) {
            if ([key.ip isEqualToString:ip] && [key.share isEqualToString:share]) {
                targetKey = key;
                break;
            }
        }
        
        if (!targetKey) return;
        
        SMB2ConnectionWrapper *wrapper = _connections[targetKey];
        wrapper.refCount--;
        
        // 引用计数归零时移除连接
        if (wrapper.refCount <= 0) {
            [_connections removeObjectForKey:targetKey];
        }
    });
}

- (struct smb2_context *)connectionForSmbURL:(NSURL *)smbURL{
    SMB2URLComponents *com = [SMB2URLComponents componentsWithSmbURL:smbURL];
    
    return [self connectionForIP:com.host share:com.share username:com.user password:com.password];
}

- (void)releaseConnectionForSmbURL:(NSURL *)smbURL{
    SMB2URLComponents *com = [SMB2URLComponents componentsWithSmbURL:smbURL];
    
    [self releaseConnectionForIP:com.host share:com.share];
}

- (BOOL)valid:(NSString*)str{
    
    if( str == nil ){
        return NO;
    }
    
    if( [str isKindOfClass:[NSNull class]] ){
        return NO;
    }

    if( [str isKindOfClass:[NSString class]] == NO ) {
        return NO;
    }
    
    if( str.length == 0 ) {
        return NO;
    }
    
    return YES;
}

@end
