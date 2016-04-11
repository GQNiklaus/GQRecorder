//
//  GQPlayer.h
//  GQRecorder
//
//  Created by 郭琪 on 16/4/11.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class GQPlayer;

@protocol GQPlayerDelegate <NSObject>

@optional

- (void)player:(GQPlayer *)player didPlay:(Float64)secondsElapsed secondsTotal:(Float64)secondsTotal;
- (void)player:(GQPlayer *)player didStartLoadingAtItemTime:(CMTime)itemTime;
- (void)player:(GQPlayer *)player didEndLoadingAtItemTime:(CMTime)itemTime;

@end

@interface GQPlayer : AVPlayer

+ (GQPlayer*) videoPlayer;
+ (void) pauseCurrentPlayer;
+ (GQPlayer*) currentPlayer;

- (void) setItemByStringPath:(NSString*)stringPath;
- (void) setItemByUrl:(NSURL*)url;
- (void) setItemByAsset:(AVAsset*)asset;
- (void) setItem:(AVPlayerItem*)item;

- (Float64) playableDuration;
- (BOOL) isPlaying;
- (BOOL) isLoading;

@property (weak, nonatomic, readwrite) id<GQPlayerDelegate> delegate;
@property (assign, nonatomic, readwrite) Float64 minimumBufferedTimeBeforePlaying;
@property (assign, nonatomic, readwrite) BOOL shouldLoop;

@end
