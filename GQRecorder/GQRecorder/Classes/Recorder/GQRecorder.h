//
//  GQRecorder.h
//  GQRecorder
//
//  Created by guoqi on 16/4/1.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "GQAudioEncoder.h"
#import "GQVideoEncoder.h"

@class GQRecorder;

@protocol GQRecorderDelegate <NSObject>

@optional

- (void)recorder:(GQRecorder *)recorder didRecordVideoFrame:(Float64)frameSecond;
- (void)recorder:(GQRecorder *)recorder didRecordAudioSample:(Float64)sampleSecond;
- (void)recorder:(GQRecorder *)recorder didFinishRecordingAtUrl:(NSURL*)recordedFile error:(NSError*)error;
- (void)recorder:(GQRecorder *)recorder didFailToInitializeVideoEncoder:(NSError*)error;
- (void)recorder:(GQRecorder *)recorder didFailToInitializeAudioEncoder:(NSError*)error;
- (void)recorder:(GQRecorder *)recorder didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end

@interface GQRecorder : NSObject <GQDataEncoderDelegate>

- (void)prepareRecordingAtCameraRoll:(NSError**)error;
- (NSURL *)prepareRecordingOnTempDir:(NSError**)error;
- (void)prepareRecordingAtUrl:(NSURL*)url error:(NSError**)error;

- (void)record;
- (void)pause;
- (void)cancel;
- (void)stop;

- (BOOL)isPrepared;
- (BOOL)isRecording;

@property (nonatomic, weak) id<GQRecorderDelegate> delegate;
@property (strong, nonatomic, readonly) AVCaptureVideoDataOutput * videoOutput;
@property (strong, nonatomic, readonly) AVCaptureAudioDataOutput * audioOutput;

@property (assign, nonatomic) BOOL enableSound;
@property (assign, nonatomic) BOOL enableVideo;

// 访问这个属性来进行视频编码配置
@property (strong, nonatomic, readonly) GQVideoEncoder *videoEncoder;
// 访问这个属性来进行音频编码配置
@property (strong, nonatomic, readonly) GQAudioEncoder *audioEncoder;
// When the recording is prepared, this getter contains the output file
@property (strong, nonatomic, readonly) NSURL *outputFileUrl;
// If not null, the asset will be played when the record starts, and pause when it pauses.
// When the record ends, the audio mix will be mixed with the playback asset
@property (strong, nonatomic) AVAsset *playbackAsset;
// 如果为YES，任何发送给代理的消息都会走主线程
@property (assign, nonatomic) BOOL dispatchDelegateMessagesOnMainQueue;
// 输出文件类型，Must be like AVFileType*
@property (copy, nonatomic) NSString *outputFileType;

@end
