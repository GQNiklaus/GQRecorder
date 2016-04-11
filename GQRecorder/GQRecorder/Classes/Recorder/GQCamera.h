//
//  GQCamera.h
//  GQRecorder
//
//  Created by 郭琪 on 16/4/7.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQRecorder.h"
#import <UIKit/UIKit.h>

@class GQCamera;
@protocol GQCameraDelegate <GQRecorderDelegate>


@end

@interface GQCamera : GQRecorder

+ (instancetype)camera;

- (instancetype)initWithSessionPreset:(NSString *)sessionPreset;
- (void)initialize:(void(^)(NSError *audioError, NSError *videoError))completionHandler;
- (BOOL)isReady;

@property (strong, nonatomic, readonly) AVCaptureSession *session;
@property (weak, nonatomic) id<GQCameraDelegate> delegate;
@property (copy, nonatomic) NSString *sessionPreset;
@property (copy, nonatomic) NSString *previewVideoGravity;
@property (nonatomic, weak) UIView *previewView;

@end
