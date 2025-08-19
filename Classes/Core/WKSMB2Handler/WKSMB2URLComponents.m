//
//  NSURLComponents+smb2.m
//  WKPlayer-ios
//
//  Created by wkun on 2025/8/12.
//  Copyright © 2025 wkun. All rights reserved.
//

#import "WKSMB2URLComponents.h"

@implementation SMB2URLComponents

@synthesize user = _user;
@synthesize password = _password;
@synthesize host = _host;
@synthesize path = _path;

+ (id)componentsWithSmbURL:(NSURL *)url{
    
    SMB2URLComponents *components = [SMB2URLComponents new];
    
//    [super componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSURLComponents *uc = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    [components setUser:[uc.user copy]];
    NSLog(@"testing uc");
    [components setPassword: uc.password.copy];
    [components setHost:uc.host.copy ];
    [components setPath: uc.path.copy ];
    
//    NSString *urlString = @"smb://wkun:wk1212@192.168.0.222/DataSync/Video/我/游泳健身/游泳/1205/Action5pro/DJI_20241205120307_0009_D.MP4";
    
    /*
    // 提取用户名和密码
    NSString *username = components.user;
    NSString *password = components.password;
    // 提取IP地址（host部分）
    NSString *ipAddress = components.host;
    */
    
    // 提取完整路径并分割
    NSString *fullPath = components.path;
    NSArray<NSString *> *pathComponents = [fullPath componentsSeparatedByString:@"/"];
    
    // 验证路径有效性
    if (pathComponents.count < 3) {
        NSLog(@"无效的路径格式");
        return components;
    }
    
    // 提取共享名称（路径的第一个有效部分）
    NSString *shareName = pathComponents[1];
    
    
    // 提取剩余路径（共享名称之后的部分）
    NSString *remainingPath = [fullPath substringFromIndex:shareName.length + 2];
    
    components.share = shareName;
    components.filePath = remainingPath;
    // 输出结果
//    NSLog(@"用户名: %@", username);      // wkun
//    NSLog(@"密码: %@", password);        // wk1212
//    NSLog(@"IP地址: %@", ipAddress);     // 192.168.0.222
//    NSLog(@"共享名称: %@", shareName);    // DataSync
//    NSLog(@"剩余路径: %@", remainingPath); // Video/我/游泳健身/游泳/1205/Action5pro/DJI_20241205120307_0009_D.MP4
    
    return components;
}


@end
