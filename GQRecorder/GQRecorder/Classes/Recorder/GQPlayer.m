//
//  GQPlayer.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/11.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQPlayer.h"

@interface GQPlayer() {
    BOOL _loading;
}

@property (strong, nonatomic, readwrite) AVPlayerItem * oldItem;
@property (assign, nonatomic, readwrite, getter=isLoading) BOOL loading;

@end

GQPlayer * currentGQVideoPlayer = nil;

@implementation GQPlayer

- (id) init {
    self = [super init];
    
    if (self) {
        self.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        [self addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playReachedEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
        
        __unsafe_unretained GQPlayer * mySelf = self;
        [self addPeriodicTimeObserverForInterval:CMTimeMake(1, 24) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            if ([mySelf.delegate respondsToSelector:@selector(player:didPlay:secondsTotal:)]) {
                [mySelf.delegate player:mySelf didPlay:CMTimeGetSeconds(time) secondsTotal:CMTimeGetSeconds(mySelf.currentItem.duration)];
            }
        }];
        
        self.minimumBufferedTimeBeforePlaying = 2;
    }
    
    return self;
}

- (void) playReachedEnd:(NSNotification*)notification {
    if ([self isPlaying]) {
        [self seekToTime:CMTimeMake(0, 1)];
        [self play];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentItem"]) {
        [self initObserver];
    } else {
        if (object == self.currentItem) {
            if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
                if (!self.isLoading) {
                    self.loading = YES;
                }
            } else {
                Float64 playableDuration = [self playableDuration];
                Float64 minimumTime = self.minimumBufferedTimeBeforePlaying;
                Float64 itemTime = CMTimeGetSeconds(self.currentItem.duration);
                
                if (minimumTime < itemTime) {
                    minimumTime = itemTime;
                }
                
                if (playableDuration >= minimumTime) {
                    if ([self isPlaying]) {
                        [self play];
                    }
                    if (self.isLoading) {
                        self.loading = NO;
                    }
                }
            }
        }
    }
}

- (void) initObserver {
    if (self.oldItem != nil) {
        [self.oldItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.oldItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.oldItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.oldItem];
    }
    
    if (self.currentItem != nil) {
        [self.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [self.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        [self.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:
         NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
    }
    self.loading = YES;
    
    self.oldItem = self.currentItem;
}

- (void) play {
    if (currentGQVideoPlayer != self) {
        [GQPlayer pauseCurrentPlayer];
    }
    
    [super play];
    
    currentGQVideoPlayer = self;
}

- (void) pause {
    [super pause];
    
    if (currentGQVideoPlayer == self) {
        currentGQVideoPlayer = nil;
    }
}

- (Float64) playableDuration {
    AVPlayerItem * item = self.currentItem;
    Float64 playableDuration = 0;
    
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        
        if (item.loadedTimeRanges.count > 0) {
            NSValue * value = [item.loadedTimeRanges objectAtIndex:0];
            CMTimeRange timeRange = [value CMTimeRangeValue];
            
            playableDuration = CMTimeGetSeconds(timeRange.duration);
        }
    }
    
    return playableDuration;
}

- (void) setItemByStringPath:(NSString *)stringPath {
    [self setItemByUrl:[NSURL URLWithString:stringPath]];
}

- (void) setItemByUrl:(NSURL *)url {
    [self setItemByAsset:[AVURLAsset URLAssetWithURL:url options:nil]];
}

- (void) setItemByAsset:(AVAsset *)asset {
    [self setItem:[AVPlayerItem playerItemWithAsset:asset]];
}

- (void) setItem:(AVPlayerItem *)item {
    [self replaceCurrentItemWithPlayerItem:item];
}

- (BOOL) isPlaying {
    return currentGQVideoPlayer == self;
}

- (void) setLoading:(BOOL)loading {
    _loading = loading;
    
    if (loading) {
        if ([self.delegate respondsToSelector:@selector(player:didStartLoadingAtItemTime:)]) {
            [self.delegate player:self didStartLoadingAtItemTime:self.currentItem.currentTime];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(player:didEndLoadingAtItemTime:)]) {
            [self.delegate player:self didEndLoadingAtItemTime:self.currentItem.currentTime];
        }
    }
}

+ (GQPlayer *) videoPlayer {
    return [[GQPlayer alloc] init];
}

+ (void) pauseCurrentPlayer {
    if (currentGQVideoPlayer != nil) {
        [currentGQVideoPlayer pause];
    }
}

+ (GQPlayer *) currentPlayer {
    return currentGQVideoPlayer;
}

@end