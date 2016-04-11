//
//  GQCamera.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/7.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQCamera.h"
#import "GQRecorder_internal.h"

@interface GQCamera ()
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation GQCamera

@synthesize delegate = _delegate;
@synthesize previewView = _previewView;
@synthesize previewVideoGravity = _previewVideoGravity;

- (BOOL)isReady {
    return self.session != nil;
}

#pragma mark - initialized

- (void)dealloc {
    self.session = nil;
    self.previewLayer = nil;
    self.previewVideoGravity = nil;
}

+ (instancetype)camera {
    return [[GQCamera alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        self.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return self;
}

- (instancetype)initWithSessionPreset:(NSString *)sessionPreset {
    if (self = [self init]) {
        self.sessionPreset = sessionPreset;
    }
    return self;
}

- (void)initialize:(void(^)(NSError * audioError, NSError * videoError))completionHandler {
    if (![self isReady]) {
        dispatch_async(self.dispatch_queue, ^ {
            AVCaptureSession * captureSession = [[AVCaptureSession alloc] init];
            
            NSError * audioError;
            [self addInputToSession:captureSession withMediaType:AVMediaTypeAudio error:&audioError];
            if (!self.enableSound) {
                audioError = nil;
            }
            
            
            NSError * videoError;
            [self addInputToSession:captureSession withMediaType:AVMediaTypeVideo error:&videoError];
            if (!self.enableVideo) {
                videoError = nil;
            }
            
            [captureSession addOutput:self.audioOutput];
            [captureSession addOutput:self.videoOutput];
            
            self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
            self.previewLayer.videoGravity = self.previewVideoGravity;
            
            [captureSession startRunning];
            
            self.session = captureSession;
            dispatch_async(dispatch_get_main_queue(), ^ {
                UIView * settedPreviewView = self.previewView;
                
                // We force the setter to add the setted preview to the previewLayer
                if (settedPreviewView != nil) {
                    self.previewView = nil;
                    self.previewView = settedPreviewView;
                }
            });
            
            if (completionHandler != nil) {
                [self dispatchBlockOnAskedQueue:^ {
                    completionHandler(audioError, videoError);
                }];
            }
        });
    }
}

#pragma mark - setting

- (void)addInputToSession:(AVCaptureSession*)captureSession withMediaType:(NSString*)mediaType error:(NSError**)error {
    *error = nil;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:mediaType];
    
    if (device != nil) {
        AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:error];
        if (*error == nil) {
            [captureSession addInput:input];
        }
    } else {
        *error = [GQRecorder createError:[NSString stringWithFormat:@"No device of type %@ were found", mediaType]];
    }
}

- (void)prepareRecordingAtUrl:(NSURL *)fileUrl error:(NSError **)error {
    if ([self isReady]) {
        [super prepareRecordingAtUrl:fileUrl error:error];
    } else {
        if (error != nil) {
            *error = [GQRecorder createError:@"The camera must be initialized before trying to record"];
        }
    }
}

#pragma mark - setter or getter

- (void)setPreviewView:(UIView *)previewView {
    if (self.previewLayer != nil) {
        [self.previewLayer removeFromSuperlayer];
    }
    
    _previewView = previewView;
    
    if (previewView != nil && self.previewLayer != nil) {
        self.previewLayer.frame = previewView.bounds;
        [previewView.layer addSublayer:self.previewLayer];
    }
}

- (UIView *)previewView {
    return _previewView;
}

- (void)setPreviewVideoGravity:(NSString *)newPreviewVideoGravity {
    _previewVideoGravity = [newPreviewVideoGravity copy];
    
    if (self.previewLayer != nil && _previewVideoGravity != nil) {
        self.previewLayer.videoGravity = _previewVideoGravity;
    }
}

- (NSString *)previewVideoGravity {
    return _previewVideoGravity;
}



@end
