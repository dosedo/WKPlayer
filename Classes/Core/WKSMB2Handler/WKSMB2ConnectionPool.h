//
//  WKSMB2ConnectionPool.h
//  WKPlayer
//
//  Created by wkun on 2025/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct smb2_context;

// 单例连接池
@interface WKSMB2ConnectionPool : NSObject

+ (instancetype)sharedPool;
- (struct smb2_context *)connectionForIP:(NSString *)ip
                                  share:(NSString *)share
                               username:(NSString *)username
                               password:(NSString *)password;

- (void)releaseConnectionForIP:(NSString *)ip share:(NSString *)share;


- (struct smb2_context *)connectionForSmbURL:(NSURL*)smbURL;
- (void)releaseConnectionForSmbURL:(NSURL*)smbURL;

@end

NS_ASSUME_NONNULL_END

