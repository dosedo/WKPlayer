//
//  BLInputCtrl.m
//  demo-ios
//
//  Created by wkun on 2025/7/26.
//  Copyright © 2025 kidsmiless. All rights reserved.
//

#import "BLInputCtrl.h"
#import "BLPlayerViewController.h"

@interface BLInputCtrl ()<UIDocumentPickerDelegate>
@property (nonatomic, strong) UITextView *textView;
@end

@implementation BLInputCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    CGFloat w = self.view.frame.size.width;
    _textView = [UITextView new];
    _textView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _textView.frame = CGRectMake(15.0, 90.0, w-30.0, 120.0);
    _textView.textColor = UIColor.blackColor;
    [self.view addSubview:_textView];
    
    _textView.text = @"smb://wkun:wk1212@192.168.0.222/DataSync/Video/我/游泳健身/游泳/1205/Action5pro/DJI_20241205120307_0009_D.MP4";
    _textView.text = @"smb://wkun:1212@192.168.0.103/share/1y.mp4";
    _textView.text = @"http://192.168.0.103/1y.mp4";
    [_textView becomeFirstResponder];
    
    
    CGRect fr = CGRectMake(self.view.center.x-60.0, CGRectGetMaxY(_textView.frame)+30.0, 120.0, 50.0);
    
    CGRect fr1 = fr;
    fr1.origin.y = CGRectGetMinY(self.textView.frame) - fr.size.height - 10.0;
    [self getBtn:@"打开" fr:fr1 tag:40];
    
    [self getBtn:@"确定" fr:fr tag:20];
    
    fr.origin.x = CGRectGetMinX(fr) - fr.size.width - 30;
    [self getBtn:@"返回" fr:fr tag:10];
    
    fr.origin.x = self.view.center.x + 0.5*fr.size.width + 30;
    [self getBtn:@"粘贴" fr:fr tag:30];
}

- (void)getBtn:(NSString*)title fr:(CGRect)fr tag:(NSInteger)tag{
    UIButton *sureBtn = [UIButton new];
    [sureBtn setTitle:title forState:UIControlStateNormal];
    [sureBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    sureBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    sureBtn.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    sureBtn.frame = fr;
    sureBtn.tag = tag;
    [self.view addSubview:sureBtn];
    
    [sureBtn addTarget:self action:@selector(handleBtn:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)handleBtn:(UIButton*)btn{
    NSURL *smburl = [NSURL URLWithString:self.textView.text];
    if( btn.tag == 10 ){
//        [SMB2ConnectionPool.sharedPool releaseConnectionForSmbURL:smburl];
        //返回
//        [self.navigationController popViewControllerAnimated:YES];
        return;
    }else if(btn.tag == 30){
        //粘贴
        self.textView.text = [UIPasteboard generalPasteboard].string;
        return;
    }else if(btn.tag == 40 ){
        [self openFile];
        return;
    }
    
    NSString *text = self.textView.text;
    if( text.length < 10 ){
        NSLog(@"输入的地址不正确");
        return;
    }
    
    NSURL *url = [NSURL URLWithString:text];
    
    if( [text hasPrefix:@"http"] || [text hasPrefix:@"smb"] ){
        
    }else{
        url = [NSURL fileURLWithPath:text];
    }
    
    [self playWithUrl:url];
}

- (void)playWithUrl:(NSURL*)url{
    
    NSLog(@"播放url: %@",url.absoluteString);
    
    BLPlayerViewController *pvc = [BLPlayerViewController new];
    pvc.url = url;
    [self.navigationController pushViewController:pvc animated:YES];
}

- (void)openFile{
    
    UIDocumentPickerViewController *controller = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.content"] inMode:UIDocumentPickerModeOpen];
    controller.delegate = self;
    controller.allowsMultipleSelection = false;

    [self presentViewController:controller animated:true completion:^{
    }];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls{
    
    NSURL *furl = [urls firstObject];
    BOOL isSecuredURL = [furl startAccessingSecurityScopedResource];
    
    
    [self playWithUrl:furl];
        
    // 保存这个URL，以便后续使用（注意：需要安全作用域访问）
    // 注意：当不再需要访问时，必须调用stopAccessingSecurityScopedResource()
    // 例如，可以将url存储起来，并在使用完毕后停止访问
    // 重要：不要长时间保留访问权限，使用完毕后立即停止
}
@end


