//
//  GQVideoPlayerView.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/11.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQVideoPlayerView.h"

@interface GQVideoPlayerView() {
    UIView * _loadingView;
}

@property (strong, nonatomic, readwrite) GQPlayer * player;
@property (strong, nonatomic, readwrite) AVPlayerLayer * playerLayer;

@end

////////////////////////////////////////////////////////////
// IMPLEMENTATION
/////////////////////

@implementation GQVideoPlayerView

- (id) init {
    self = [super init];
    
    if (self) {
        _loadingView = nil;
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit {
    self.player = [GQPlayer videoPlayer];
    self.player.delegate = self;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.playerLayer];
    
    UIView * theLoadingView = [[UIView alloc] init];
    theLoadingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    
    UIActivityIndicatorView * theIndicatorView = [[UIActivityIndicatorView alloc] init];
    [theIndicatorView startAnimating];
    theIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [theLoadingView addSubview:theIndicatorView];
    
    self.loadingView = theLoadingView;
    self.loadingView.hidden = NO;
    self.clipsToBounds = YES;
}

- (void) awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}

- (void)player:(GQPlayer *)videoPlayer didStartLoadingAtItemTime:(CMTime)itemTime {
    self.loadingView.hidden = NO;
}

- (void)player:(GQPlayer *)videoPlayer didEndLoadingAtItemTime:(CMTime)itemTime {
    self.loadingView.hidden = YES;
}

- (void)player:(GQPlayer *)videoPlayer didPlay:(Float64)secondsElapsed secondsTotal:(Float64)secondsTotal {
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
    self.loadingView.frame = self.bounds;
}

- (void) setLoadingView:(UIView *)loadingView {
    if (_loadingView != nil) {
        [_loadingView removeFromSuperview];
    }
    
    _loadingView = loadingView;
    
    if (_loadingView != nil) {
        [self addSubview:_loadingView];
    }
}

@end

