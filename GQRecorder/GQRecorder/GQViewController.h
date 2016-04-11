//
//  GQViewController.h
//  GQRecorder
//
//  Created by guoqi on 16/4/1.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GQViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *recordView;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *retakeButton;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UILabel *timeRecordedLabel;
@property (weak, nonatomic) IBOutlet UIView *downBar;

@end
