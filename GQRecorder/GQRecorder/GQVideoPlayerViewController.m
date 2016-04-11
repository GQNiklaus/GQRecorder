//
//  GQVideoPlayerViewController.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/11.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQVideoPlayerViewController.h"

@implementation GQVideoPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.videoPlayerView.player setItemByStringPath:@"https://v.cdn.vine.co/r/videos/C7EDC2F6EE981816034254524416_19c10057e43.3.1_3qHAGX7s6yiU7RIV_DJ4NNlDaaJjixmQY1pWf9.CBHb3Q6bZqfSRfwu8IciIigqI.mp4"];
    [self.videoPlayerView.player play];
    self.videoPlayerView.player.shouldLoop = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
