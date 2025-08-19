//
//  BLPlayerViewController.m
//  WKPlayer
//
//  Created by wkun on 2025/8/19.
//

#import "BLPlayerViewController.h"
#import "WKPlayer.h"

@interface BLPlayerViewController ()

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *timeL;
@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, strong) WKPlayer *player;
@property (nonatomic, assign) BOOL seeking;

@end

@implementation BLPlayerViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.player = [[WKPlayer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoChanged:) name:WKPlayerDidChangeInfosNotification object:self.player];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.blackColor;
    
    [self setupUI];
    
    self.player.playView = self.view;
    [self replay];
}

- (void)replay{
    if( !self.url ) return;

    WKAsset *asset = [WKAsset assetWithURL:self.url];
    [self.player replaceWithAsset:asset];
    [self.player play];
}

#pragma mark - Events

- (void)play:(UIButton*)btn
{
    WKStateInfo state = [self.player sstateInfo];
    if (state.playback & WKPlaybackStateFinished) {
        [self replay];
    } else if (state.playback & WKPlaybackStatePlaying) {
        [self.player pause];
    } else {
        [self.player play];
    }
}

- (void)progressTouchUp:(UISlider*)slider
{
    CMTime time = CMTimeMultiplyByFloat64(self.player.currentItem.duration, self.slider.value);
    if (!CMTIME_IS_NUMERIC(time)) {
        time = kCMTimeZero;
    }
    self.seeking = YES;
    [self.player seekToTime:time result:^(CMTime time, NSError *error) {
        self.seeking = NO;
    }];
}


#pragma mark - SGPlayer Notifications

- (void)infoChanged:(NSNotification *)notification
{
    WKTimeInfo time = [WKPlayer timeInfoFromUserInfo:notification.userInfo];
    WKStateInfo state = [WKPlayer stateInfoFromUserInfo:notification.userInfo];
    WKInfoAction action = [WKPlayer infoActionFromUserInfo:notification.userInfo];
    if (action & WKInfoActionTime) {
        if (action & WKInfoActionTimePlayback && !(state.playback & WKPlaybackStateSeeking) && !self.seeking && !self.slider.isTracking) {
            self.slider.value = CMTimeGetSeconds(time.playback) / CMTimeGetSeconds(time.duration);
            self.timeL.text = [self timeStringFromSeconds:CMTimeGetSeconds(time.playback)];
        }
        if (action & WKInfoActionTimeDuration) {
            NSLog(@"视频时长：%@", [self timeStringFromSeconds:CMTimeGetSeconds(time.duration)]);
        }
    }
    
    if (action & WKInfoActionState) {
        self.playBtn.selected = NO;
        if (state.playback & WKPlaybackStateFinished) {
            
        } else if (state.playback & WKPlaybackStatePlaying) {
            self.playBtn.selected = YES;
        } else {
            
        }
    }
}


#pragma mark - SetupUI
- (void)setupUI{
    
    _timeL = [UILabel new];
    _timeL.font = [UIFont systemFontOfSize:14];
    _timeL.textColor = [UIColor whiteColor];
    _timeL.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:_timeL];

    _slider = [UISlider new];
    _slider.thumbTintColor = UIColor.whiteColor;
    _slider.minimumValue = 0.0;
    _slider.maximumValue = 1.0;
    [_slider setMinimumTrackTintColor:UIColor.whiteColor];
    [_slider setMaximumTrackTintColor:[UIColor colorWithWhite:1.0 alpha:0.2]];
    [_slider addTarget:self action:@selector(progressTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_slider];
    
    _playBtn = [BLPlayButton new];
    [_playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playBtn];
    
    
    
    _timeL.translatesAutoresizingMaskIntoConstraints = NO;
    _slider.translatesAutoresizingMaskIntoConstraints = NO;
    _playBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint constraintWithItem:_playBtn attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0].active = YES;
    [NSLayoutConstraint constraintWithItem:_playBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10.0].active = YES;
    // 关键约束：高50、宽80
    [NSLayoutConstraint constraintWithItem:_playBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50].active = YES;
    [NSLayoutConstraint constraintWithItem:_playBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80].active = YES;
    
    
    ///timeL 约束
    [NSLayoutConstraint constraintWithItem:_timeL attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1.0 constant:-20.0].active = YES;
    [NSLayoutConstraint constraintWithItem:_timeL attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_playBtn attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0].active = YES;
    // 关键约束：高50、宽200
    [NSLayoutConstraint constraintWithItem:_timeL attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50].active = YES;
    [NSLayoutConstraint constraintWithItem:_timeL attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200].active = YES;
    
    
    ///slider 约束
    [NSLayoutConstraint constraintWithItem:_slider attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1.0 constant:20.0].active = YES;
    [NSLayoutConstraint constraintWithItem:_slider attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1.0 constant:-20.0].active = YES;
    [NSLayoutConstraint constraintWithItem:_slider attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_playBtn attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0].active = YES;
    // 关键约束：高40
    [NSLayoutConstraint constraintWithItem:_slider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:40].active = YES;
}

#pragma mark - Tools

- (NSString *)timeStringFromSeconds:(CGFloat)seconds
{
    return [NSString stringWithFormat:@"%ld:%.2ld", (long)seconds / 60, (long)seconds % 60];
}

@end

@implementation BLPlayButton
@end
