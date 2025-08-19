//
//  NSURLComponents+smb2.h
//  WKPlayer-ios
//
//  Created by wkun on 2025/8/12.
//  Copyright © 2025 wkun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///获取: user  password host share filePath 
@interface SMB2URLComponents: NSURLComponents
@property (nonatomic, strong) NSString *share;
@property (nonatomic, strong) NSString *filePath;
+ (id)componentsWithSmbURL:(NSURL*)url;
@end

NS_ASSUME_NONNULL_END
