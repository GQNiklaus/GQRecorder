//
//  GQViewController.m
//  GQRecorder
//
//  Created by guoqi on 16/4/1.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQViewController.h"
#import "GQTouchDetector.h"
#import "GQCamera.h"
#import "GQAudioTool.h"


@interface GQViewController () <GQCameraDelegate>
/** 相机 */
@property (nonatomic, strong) GQCamera *camera;
/** 播放器 */
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation GQViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupRecorder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

#pragma mark - initialise
- (void)setupRecorder {
    _camera = [[GQCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720];
    _camera.delegate = self;
    _camera.enableSound = NO;
    self.camera.previewVideoGravity = AVLayerVideoGravityResizeAspectFill;
    self.camera.previewView = self.previewView;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [GQAudioTool overrideCategoryMixWithOthers];
    
    [self.camera initialize:^(NSError *audioError, NSError *videoError) {
        
    }];
    
    [self.retakeButton addTarget:self action:@selector(handleRetakeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton addTarget:self action:@selector(handleStopButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.recordView addGestureRecognizer:[[GQTouchDetector alloc] initWithTarget:self action:@selector(handleTouchDetected:)]];
    
    self.loadingView.hidden = YES;
    
}

#pragma mark - gesture
- (void)handleTouchDetected:(GQTouchDetector *)touchDetector {
    if (touchDetector.state == UIGestureRecognizerStateBegan) {
        NSLog(@"==== STARTING RECORDING ====");
        if (![self.camera isPrepared]) {
            NSError * error;
            [self.camera  prepareRecordingAtCameraRoll:&error];
            
            if (error != nil) {
                [self showAlertViewWithTitle:@"Failed to start camera" message:[error localizedFailureReason]];
                NSLog(@"%@", error);
            }
        } else {
            [self.camera record];
        }
    } else if (touchDetector.state == UIGestureRecognizerStateEnded) {
        NSLog(@"==== PAUSING RECORDING ====");
        [self.camera pause];
    }
}

#pragma mark - action
- (void)handleRetakeButtonTapped:(id)sender {
    [self.camera cancel];
    [self updateLabelForSecond:0];
}
- (void)handleStopButtonTapped:(id)sender {
    self.loadingView.hidden = NO;
    self.downBar.userInteractionEnabled = NO;
    [self.camera stop];
}

#pragma mark - handle
- (void)showAlertViewWithTitle:(NSString*)title message:(NSString*) message {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)updateLabelForSecond:(Float64)totalRecorded {
    self.timeRecordedLabel.text = [NSString stringWithFormat:@"Recorded - %.2f sec", totalRecorded];
}

#pragma mark - GQRecorderDelegate
- (void)recorder:(GQRecorder *)recorder didRecordVideoFrame:(Float64)frameSecond {
    [self updateLabelForSecond:frameSecond];
}

- (void)recorder:(GQRecorder *)recorder didFinishRecordingAtUrl:(NSURL *)recordedFile error:(NSError *)error {
    self.loadingView.hidden = YES;
    self.downBar.userInteractionEnabled = YES;
    if (error != nil) {
        [self showAlertViewWithTitle:@"Failed to save video" message:[error localizedFailureReason]];
    } else {
        [self showAlertViewWithTitle:@"Video saved!" message:@"Video saved successfully"];
    }
}

- (void)recorder:(GQRecorder *)recorder didFailToInitializeVideoEncoder:(NSError *)error {
    NSLog(@"Failed to initialize VideoEncoder");
}

- (void)recorder:(GQRecorder *)recorder didFailToInitializeAudioEncoder:(NSError *)error {
    NSLog(@"Failed to initialize AudioEncoder");
}

@end
