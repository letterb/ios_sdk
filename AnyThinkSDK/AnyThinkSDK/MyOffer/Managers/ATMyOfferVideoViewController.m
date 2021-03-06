//
//  ATMyOfferVideoViewController.m
//  AnyThinkSDK
//
//  Created by Topon on 2019/9/26.
//  Copyright © 2019 Martin Lau. All rights reserved.
//

#import "ATMyOfferVideoViewController.h"
#import "ATMyOfferProgressView.h"
#import "ATMyOfferOfferModel.h"
#import "ATMyOfferResourceManager.h"
#import "ATMyOfferOfferManager.h"
#import "Utilities.h"
#import "ATMyOfferVideoBannerView.h"
#import <AVFoundation/AVFoundation.h>

#define videoWidth self.view.bounds.size.width
#define videoHeight self.view.bounds.size.height
@interface ATMyOfferVideoViewController ()
@property (nonatomic , strong)AVPlayer *player;
@property (nonatomic , strong)AVPlayerItem *playerItem;
@property (nonatomic , strong)UIView *backView;
@property (nonatomic , strong)UIView *endCardBackView;
@property (nonatomic , strong)UIImageView *endCardImage;
@property (nonatomic , strong)id playerObserver;

@property (nonatomic , strong)UIButton *closeBtn;
@property (nonatomic , strong)UIButton *voiceBtn;
@property (nonatomic , assign)BOOL isEndCard;
@property (nonatomic , strong)ATMyOfferVideoBannerView *bannerView;

@property (nonatomic , assign)CGFloat totalTime;
@property (nonatomic , strong)ATMyOfferProgressView *progressview;
@property (nonatomic , readonly)UIInterfaceOrientation orientation;

@property (nonatomic , strong)ATMyOfferOfferModel *offerModel;
@property (nonatomic) ATMyOfferSetting *setting;
@end

@implementation ATMyOfferVideoViewController

- (instancetype)initWithMyOfferModel:(ATMyOfferOfferModel*)offerModel rewardedVideoSetting:(ATMyOfferSetting *)setting {
    self = [super init];
    if (self) {
        _offerModel = offerModel;
        _setting = setting;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    self.view.backgroundColor = [UIColor blackColor];
    [self layoutAVPlayer];
    [self layoutTopView];
    [self timeObserver];
    
}

-(void)layoutAVPlayer {
    CGRect playerFrame = CGRectMake(0, 0, videoWidth, videoHeight);
    NSString * path = [[ATMyOfferResourceManager sharedManager]resourcePathForOfferModel:self.offerModel resourceURL:self.offerModel.videoURL];
    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    self.totalTime = (asset.duration.value * 1.0 / asset.duration.timescale * 1.0);
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    
    AVPlayerLayer *playerlayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerlayer.frame = playerFrame;
    playerlayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerlayer];
    
    [self.player setMuted:!_setting.mute];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player play];
    
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
}

-(void)layoutTopView {
    self.backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, videoWidth, videoHeight)];
    [self.view addSubview:self.backView];
    if (_setting.videoAreaInteractionEnabled) {
        UITapGestureRecognizer *tapsVideo = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapVideo)];
        tapsVideo.numberOfTapsRequired = 1;
        [self.backView addGestureRecognizer:tapsVideo];
    }
    [self.view addSubview:self.progressview];
    [self.view addSubview:self.voiceBtn];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if(object == self.playerItem){
        if([keyPath isEqualToString:@"status"]){
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerStatusUnknown:
                    {
                        NSLog(@"未知错误:%@", self.playerItem.error);
                        
                    }
                    break;
                case AVPlayerStatusReadyToPlay:
                    {
                        NSLog(@"准备播放");
                        [self.player setVolume:[AVAudioSession sharedInstance].outputVolume];
                    }
                    break;
                case AVPlayerStatusFailed:
                    {
                        NSLog(@"播放失败:%@", self.playerItem.error);
                        
                    }
                    break;
                default:
                    break;
            }
        }
    }
}

//监听视频播放进度
-(void)timeObserver {
    CGFloat persentFlag25 = (1.0 / 4.0) * self.totalTime;
    CGFloat persentFlag50 = (1.0 / 2.0) * self.totalTime;
    CGFloat persentFlag75 = (3.0 / 4.0) * self.totalTime;
    CGFloat persentFlag100 = 1.0 * self.totalTime;
    __block BOOL isFlagStart = NO;
    __block BOOL isFlag25 = NO;
    __block BOOL isFlag50 = NO;
    __block BOOL isFlag75 = NO;
    __block BOOL isFlag100 = NO;
    __block BOOL isBannerShowFlag = NO;
    __block BOOL isCloseShowFlag = NO;
    if (_setting.bannerAppearanceInterval == 0) {
        [self.view addSubview:self.bannerView];
        isBannerShowFlag = YES;
    }else if (_setting.bannerAppearanceInterval < 0){
        isBannerShowFlag = YES;
    }
    if(_setting.closeButtonAppearanceInterval == -1){
        isCloseShowFlag = YES;
    }
    __weak typeof(self) weakself = self;
    _playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(50, 1000) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentime = (time.value * 1.00) / (time.timescale * 1.00) ;
        [weakself.progressview upDateCircleProgress:currentime];
        if(currentime == 0 && isFlagStart == NO){
            isFlagStart = YES;
            if([weakself.delegate respondsToSelector:@selector(myOfferVideoStartPlayWithOfferModel:extra:)]){
                [weakself.delegate myOfferVideoStartPlayWithOfferModel:weakself.offerModel extra:nil];
            }
        }
        if (currentime >= persentFlag25 && isFlag25 == NO) {
            isFlag25 = YES;
            if ([weakself.delegate respondsToSelector:@selector(myOfferVideoPlay25PercentWithOfferModel:extra:)]) {
                [weakself.delegate myOfferVideoPlay25PercentWithOfferModel:weakself.offerModel extra:nil];
            }
        }else if(currentime >= persentFlag50 && isFlag50 == NO){
            isFlag50 = YES;
            if ([weakself.delegate respondsToSelector:@selector(myOfferVideoPlay50PercentWithOfferModel:extra:)]) {
                [weakself.delegate myOfferVideoPlay50PercentWithOfferModel:weakself.offerModel extra:nil];
            }
        }else if(currentime >= persentFlag75 && isFlag75 == NO){
            isFlag75 = YES;
            if ([weakself.delegate respondsToSelector:@selector(myOfferVideoPlay75PercentWithOfferModel:extra:)]) {
                [weakself.delegate myOfferVideoPlay75PercentWithOfferModel:weakself.offerModel extra:nil];
            }
        }else if(currentime >= persentFlag100 && isFlag100 == NO){
            isFlag100 = YES;
            if ([weakself.delegate respondsToSelector:@selector(myOfferVideoDidEndPlayWithOfferModel:extra:)]) {
                [weakself.delegate myOfferVideoDidEndPlayWithOfferModel:weakself.offerModel extra:nil];
            }
            [weakself endCard];
        }
        if (currentime >= weakself.setting.bannerAppearanceInterval && isBannerShowFlag == NO) {
            isBannerShowFlag = YES;
            [UIView transitionWithView:weakself.view duration:1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [weakself.view addSubview:weakself.bannerView];
            } completion:nil];
        }
        if (currentime >= weakself.setting.closeButtonAppearanceInterval && isCloseShowFlag == NO) {
            isCloseShowFlag = YES;
            [weakself.view addSubview:weakself.closeBtn];
        }
    }];
}

UIEdgeInsets SafeAreaInsets_ATMyOfferVideoVC() {
    return ([[UIApplication sharedApplication].keyWindow respondsToSelector:@selector(safeAreaInsets)] ? [UIApplication sharedApplication].keyWindow.safeAreaInsets : UIEdgeInsetsZero);
}

-(void)endCard {
    if ([self.delegate respondsToSelector:@selector(myOfferVideoEndCardDidShowWithOfferModel:extra:)]) {
        [self.delegate myOfferVideoEndCardDidShowWithOfferModel:self.offerModel extra:nil];
    }
    self.isEndCard = YES;
    NSString * path = [[ATMyOfferResourceManager sharedManager]resourcePathForOfferModel:self.offerModel resourceURL:self.offerModel.fullScreenImageURL];
    NSData *imageData = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage imageWithData:imageData];
    self.endCardImage = [[UIImageView alloc]initWithFrame:self.view.frame];
    [self.endCardImage setImage:image];
    UIImageView *fuzzyImage = [[UIImageView alloc]initWithImage:image];
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:effect];
    effectView.frame = self.view.frame;
    self.endCardImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.endCardBackView];
    [self.endCardBackView addSubview:fuzzyImage];
    [fuzzyImage addSubview:effectView];
    [self.endCardBackView addSubview:self.endCardImage];
    [self.endCardBackView addSubview:self.closeBtn];
    [self.endCardBackView addSubview:self.bannerView];
    if (_setting.endCardClickable == ATMyOfferEndCardClickableFullscreen) {
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickMyOfferBanner)];
        gest.numberOfTapsRequired = 1;
        [_endCardBackView addGestureRecognizer:gest];
    }
}

-(void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.player removeTimeObserver:_playerObserver];
    NSLog(@"ATMyOfferVideoViewController dealloc");
}

-(void)applicationWillResignActive:(NSNotification *)notification {
    [self.player pause];
}

-(void)applicationWillBecomeActive:(NSNotification *)notification {
    [self.player play];
}

-(void)tapVideo {
    if (_setting.bannerAppearanceInterval == -1 && [ATMyOfferVideoBannerView bannerForView:self.view] == nil) {
        [self.view addSubview:self.bannerView];
    }
    if (_setting.videoAreaInteractionEnabled) {
        if ([self.delegate respondsToSelector:@selector(myOfferVideoDidClickVideoWithOfferModel:extra:)] && _setting.videoAreaInteractionEnabled) {
            [self.delegate myOfferVideoDidClickVideoWithOfferModel:self.offerModel extra:nil];
        }
    }
}

-(void)clickMyOfferCloseVideo {
    if (self.isEndCard) {
        if ([self.delegate respondsToSelector:@selector(myOfferVideoEndCardDidCloseWithOfferModel:extra:)]) {
            [self.delegate myOfferVideoEndCardDidCloseWithOfferModel:self.offerModel extra:nil];
        }
        if ([self.delegate respondsToSelector:@selector(myOfferVideoDidCloseWithOfferModel:extra:)]) {
            [self.delegate myOfferVideoDidCloseWithOfferModel:self.offerModel extra:nil];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self.player pause];
        self.player = nil;
        [self endCard];
    }
}

-(void)clickMyOfferVoiceBtn {
    [self.player setMuted:!self.player.isMuted];
    if(self.player.isMuted){
        [_voiceBtn setImage:[UIImage anythink_imageWithName:@"MyOfferVoice_notMuted"] forState:UIControlStateNormal];
    }else{
        [_voiceBtn setImage:[UIImage anythink_imageWithName:@"MyOfferVoice_Muted"] forState:UIControlStateNormal];
    }
}


-(void)clickMyOfferBanner {
    if ([self.delegate respondsToSelector:@selector(myOfferVideoDidClickVideoWithOfferModel:extra:)]) {
        [self.delegate myOfferVideoDidClickVideoWithOfferModel:self.offerModel extra:nil];
    }
}
//不可切换横竖屏
-(BOOL)shouldAutorotate {
    return NO;
}
//状态栏隐藏
-(BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - 懒加载
-(ATMyOfferProgressView *)progressview {
    if(!_progressview){
        _progressview = [[ATMyOfferProgressView alloc]initWithFrame:CGRectMake(20, SafeAreaInsets_ATMyOfferVideoVC().top + 10, 30, 30)];
        self.progressview.alpha = 0.6;
        self.progressview.signProgress = self.totalTime;
    }
    return _progressview;
}

-(UIView *)endCardBackView {
    if (!_endCardBackView) {
        _endCardBackView = [[UIView alloc]initWithFrame:self.view.frame];
        _endCardBackView.backgroundColor = [UIColor blackColor];
    }
    return _endCardBackView;
}

-(UIButton *)closeBtn {
    if(!_closeBtn){
        _closeBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 65, SafeAreaInsets_ATMyOfferVideoVC().top + 5, 40, 40)];
        _closeBtn.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [_closeBtn setImage:[UIImage anythink_imageWithName:@"MyOfferVideo_Close"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(clickMyOfferCloseVideo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

-(UIButton *)voiceBtn {
    if(!_voiceBtn){
        _voiceBtn = [[UIButton alloc]initWithFrame:CGRectMake(70, SafeAreaInsets_ATMyOfferVideoVC().top + 10, 30, 30)];
        if (_setting.mute) {
            [_voiceBtn setImage:[UIImage anythink_imageWithName:@"MyOfferVoice_Muted"] forState:UIControlStateNormal];
        }else{
            [_voiceBtn setImage:[UIImage anythink_imageWithName:@"MyOfferVoice_notMuted"] forState:UIControlStateNormal];
        }
        [_voiceBtn addTarget:self action:@selector(clickMyOfferVoiceBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _voiceBtn;
}

-(ATMyOfferVideoBannerView *)bannerView {
    if (!_bannerView) {
        CGFloat height = 80.0;
        _bannerView = [[ATMyOfferVideoBannerView alloc]initWithFrame:CGRectMake(10, videoHeight - SafeAreaInsets_ATMyOfferVideoVC().bottom - height - 8, videoWidth - 20, height)];
        NSString * path = [[ATMyOfferResourceManager sharedManager]resourcePathForOfferModel:self.offerModel resourceURL:self.offerModel.iconURL];
        [_bannerView.iconImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfFile:path]]];
        _bannerView.title.text = self.offerModel.title;
        [_bannerView.desc setText:self.offerModel.text];
        [_bannerView.ctaButton setTitle:self.offerModel.CTA forState:UIControlStateNormal];
        [_bannerView.ctaButton addTarget:self action:@selector(clickMyOfferBanner) forControlEvents:UIControlEventTouchUpInside];
        NSString * logoPath = [[ATMyOfferResourceManager sharedManager]resourcePathForOfferModel:self.offerModel resourceURL:self.offerModel.logoURL];
        if(logoPath != nil){
            NSData *imageData = [NSData dataWithContentsOfFile:logoPath];
            [_bannerView.logoImage setImage:[UIImage imageWithData:imageData]];
        }
        if (_setting.endCardClickable != ATMyOfferEndCardClickableCTA) {
            UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickMyOfferBanner)];
            gest.numberOfTapsRequired = 1;
            [_bannerView addGestureRecognizer:gest];
        }
    }
    return _bannerView;
}

@end
