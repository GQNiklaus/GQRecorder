//
//  GQVideoPlayerView.h
//  GQRecorder
//
//  Created by 郭琪 on 16/4/11.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GQPlayer.h"

@class GQVideoPlayerView;

@interface GQVideoPlayerView : UIView<GQPlayerDelegate>

@property (strong, nonatomic, readonly)  GQPlayer* player;
@property (strong, nonatomic, readwrite) UIView * loadingView;

@end
