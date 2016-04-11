//
//  GQRecorder.m
//  GQRecorder
//
//  Created by guoqi on 16/4/1.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQRecorder.h"
#import "GQRecorder_internal.h"
#import "NSArray+GQAdditions.h"

@interface GQRecorder ()
{
    BOOL _recording;
    BOOL _shouldWriteToCameraRoll;
    BOOL _audioEncoderReady;
    BOOL _videoEncoderReady;
}

@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property (strong, nonatomic) GQVideoEncoder *videoEncoder;
@property (strong, nonatomic) GQAudioEncoder *audioEncoder;
@property (strong, nonatomic) NSURL *outputFileUrl;
@property (strong, nonatomic) AVPlayer *playbackPlayer;

@end

@implementation GQRecorder

#pragma mark - 初始化

- (instancetype)init {
    if (self = [super init]) {
        self.dispatch_queue = dispatch_queue_create("GQVideoRecorder", NULL);
        self.outputFileType = AVFileTypeMPEG4;
        _audioEncoderReady = NO;
        _videoEncoderReady = NO;
        self.audioEncoder = [[GQAudioEncoder alloc] initWithRecorder:self];
        self.videoEncoder = [[GQVideoEncoder alloc] initWithRecorder:self];
        self.audioEncoder.delegate = self;
        self.videoEncoder.delegate = self;
        _recording = NO;
        
        self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        // 设置视频输出代理
        [self.videoOutput setSampleBufferDelegate:self.videoEncoder queue:_dispatch_queue];
        
        self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        // 设置音频输出代理
        [self.audioOutput setSampleBufferDelegate:self.audioEncoder queue:_dispatch_queue];
        
        self.lastFrameTimeBeforePause = CMTimeMake(0, 1);
        self.dispatchDelegateMessagesOnMainQueue = YES;
        
    }
    return self;
}

- (void)dealloc {
    self.videoOutput = nil;
    self.audioOutput = nil;
    self.videoEncoder = nil;
    self.audioEncoder = nil;
    self.outputFileUrl = nil;
    self.assetWriter = nil;
}

//
// Video Recorder methods
//

- (void)prepareRecordingAtCameraRoll:(NSError **)error {
    [self prepareRecordingOnTempDir:error];
    _shouldWriteToCameraRoll = YES;
}

- (NSURL *)prepareRecordingOnTempDir:(NSError **)error {
    long timeInterval =  (long)[[NSDate date] timeIntervalSince1970];
    NSURL * fileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%ld%@", NSTemporaryDirectory(), timeInterval, @"SCVideo.MOV"]];
    
    NSError * recordError = nil;
    [self prepareRecordingAtUrl:fileUrl error:&recordError];
    
    if (recordError != nil) {
        if (error != nil) {
            *error = recordError;
        }
        [self removeFile:fileUrl];
        fileUrl = nil;
        
    }
    
    return fileUrl;
}

- (void)prepareRecordingAtUrl:(NSURL *)fileUrl error:(NSError **)error {
    if (fileUrl == nil) {
        [NSException raise:@"Invalid argument" format:@"FileUrl must be not nil"];
    }
    
    dispatch_sync(_dispatch_queue, ^ {
        [self resetInternal];
        _shouldWriteToCameraRoll = NO;
        self.currentTimeOffset = CMTimeMake(0, 1);
        
        if (self.playbackAsset != nil) {
            self.playbackPlayer = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.playbackAsset]];
        }
        
        NSError * assetError;
        
        AVAssetWriter * writer = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:self.outputFileType error:&assetError];
        
        if (assetError == nil) {
            self.assetWriter = writer;
            self.outputFileUrl = fileUrl;
            
            if (error != nil) {
                *error = assetError;
            }
            [self record];
        } else {
            if (error != nil) {
                *error = assetError;
            }
        }
    });
}

- (void)removeFile:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [fileURL path];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        [fileManager removeItemAtPath:filePath error:&error];
    }
}

- (NSURL *)finalizeAudioMixForUrl:(NSURL*)fileUrl  withCompletionBlock:(void(^)())completionBlock {
    if (self.playbackAsset != nil) {
        // Move the file to a tmp one
        NSURL * oldUrl = [[fileUrl URLByDeletingPathExtension] URLByAppendingPathExtension:@"old.mp4"];
        [[NSFileManager defaultManager] moveItemAtURL:fileUrl toURL:oldUrl error:nil];
        
        AVMutableComposition * composition = [[AVMutableComposition alloc] init];
        
        AVMutableCompositionTrack * audioTrackComposition = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack * videoTrackComposition = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVURLAsset * fileAsset = [AVURLAsset URLAssetWithURL:oldUrl options:nil];
        
        // We create an array of tracks containing the audio tracks and the video tracks
        NSArray * audioTracks = [NSArray arrayWithArrays:[self.playbackAsset tracksWithMediaType:AVMediaTypeAudio], [fileAsset tracksWithMediaType:AVMediaTypeAudio], nil];
        
        NSArray * videoTracks = [fileAsset tracksWithMediaType:AVMediaTypeVideo];
        
        CMTime duration = ((AVAssetTrack*)[videoTracks objectAtIndex:0]).timeRange.duration;
        
        for (AVAssetTrack * track in audioTracks) {
            [audioTrackComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:track atTime:kCMTimeZero error:nil];
        }
        
        for (AVAssetTrack * track in videoTracks) {
            [videoTrackComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:track atTime:kCMTimeZero error:nil];
        }
        
        AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
        exportSession.outputFileType = self.outputFileType;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputURL = fileUrl;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^ {
            [self removeFile:oldUrl];
            NSLog(@"Status: %ld", exportSession.status);
            NSLog(@"Error: %@", exportSession.error);
            completionBlock();
        }];
    } else {
        completionBlock();
    }
    return fileUrl;
}


- (void)assetWriterFinished:(NSURL*)fileUrl {
    self.assetWriter = nil;
    self.outputFileUrl = nil;
    [self.audioEncoder reset];
    [self.videoEncoder reset];
    
    fileUrl = [self finalizeAudioMixForUrl:fileUrl withCompletionBlock:^{
        if (_shouldWriteToCameraRoll) {
            ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:fileUrl completionBlock:^(NSURL *assetUrl, NSError * error) {
                [self removeFile:fileUrl];
                
                [self dispatchBlockOnAskedQueue:^ {
                    if ([self.delegate respondsToSelector:@selector(recorder:didFinishRecordingAtUrl:error:)]) {
                        [self.delegate recorder:self didFinishRecordingAtUrl:assetUrl error:error];
                    }
                }];
            }];
        } else {
            [self dispatchBlockOnAskedQueue:^ {
                if ([self.delegate respondsToSelector:@selector(recorder:didFinishRecordingAtUrl:error:)]) {
                    [self.delegate recorder:self didFinishRecordingAtUrl:fileUrl error:nil];
                }
            }];
        }
    }];

}

- (void)stop {
    [self pause];
    
    dispatch_async(_dispatch_queue, ^ {
        if (self.assetWriter == nil) {
            [self dispatchBlockOnAskedQueue:^ {
                if ([self.delegate respondsToSelector:@selector(recorder:didFinishRecordingAtUrl:error:)]) {
                    [self.delegate recorder:self didFinishRecordingAtUrl:nil error:[GQRecorder createError:@"Recording must be started before calling stopRecording"]];
                }
            }];
        } else {
            NSURL * fileUrl = self.outputFileUrl;
            
            if(self.assetWriter.status == AVAssetWriterStatusFailed){
                NSLog(@"assets write failed:%@ ",self.assetWriter.error);
                return;
            }
            
            if (self.assetWriter.status != AVAssetWriterStatusUnknown) {
                [self.assetWriter finishWritingWithCompletionHandler:^ {
                    [self assetWriterFinished:fileUrl];
                }];
            } else {
                [self assetWriterFinished:fileUrl];
            }
        }
    });
    
}

- (void)pause {
    [self.playbackPlayer pause];
    dispatch_async(_dispatch_queue, ^ {
        _recording = NO;
        // As I don't know any way to get the current time, setting this will always
        // let the last frame to last 1/24th of a second
        self.lastFrameTimeBeforePause = CMTimeMake(1, 24);
    });
}

- (void)record {
    if (![self isPrepared]) {
        [NSException raise:@"Recording not previously started" format:@"Recording should be started using startRecording before trying to resume it"];
    }
    [self.playbackPlayer play];
    dispatch_async(_dispatch_queue, ^ {
        self.shouldComputeOffset = YES;
        _recording = YES;
    });
}

- (void)cancel {
    dispatch_sync(_dispatch_queue, ^ {
        [self resetInternal];
    });
}

- (void)resetInternal {
    AVAssetWriter *writer = self.assetWriter;
    NSURL *fileUrl = self.outputFileUrl;
    
    _audioEncoderReady = NO;
    _videoEncoderReady = NO;
    
    self.outputFileUrl = nil;
    self.assetWriter = nil;
    self.playbackPlayer = nil;
    _recording = NO;
    
    [self.audioEncoder reset];
    [self.videoEncoder reset];
    
    if (writer != nil) {
        if (writer.status != AVAssetWriterStatusUnknown) {
            [writer finishWritingWithCompletionHandler:^ {
                if (fileUrl != nil) {
                    [self removeFile:fileUrl];
                }
            }];
        }
    }
}

#pragma mark - GQDataEncoderDelegate
- (void)dataEncoder:(GQDataEncoder *)dataEncoder didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if ([self.delegate respondsToSelector:@selector(recorder:didOutputSampleBuffer:)]) {
        [self.delegate recorder:self didOutputSampleBuffer:sampleBuffer];
    }
}

- (void)dataEncoder:(GQDataEncoder *)dataEncoder didEncodeFrame:(Float64)frameSecond {
    [self dispatchBlockOnAskedQueue:^ {
        if (dataEncoder == self.audioEncoder) {
            if ([self.delegate respondsToSelector:@selector(recorder:didRecordAudioSample:)]) {
                [self.delegate recorder:self didRecordAudioSample:frameSecond];
            }
        } else if (dataEncoder == self.videoEncoder) {
            if ([self.delegate respondsToSelector:@selector(recorder:didRecordVideoFrame:)]) {
                [self.delegate recorder:self didRecordVideoFrame:frameSecond];
            }
        }
    }];
}

- (void)dataEncoder:(GQDataEncoder *)dataEncoder didFailToInitializeEncoder:(NSError *)error {
    [self dispatchBlockOnAskedQueue: ^ {
        if (dataEncoder == self.audioEncoder) {
            if ([self.delegate respondsToSelector:@selector(recorder:didFailToInitializeAudioEncoder:)]) {
                [self.delegate recorder:self didFailToInitializeAudioEncoder:error];
            }
        } else if (dataEncoder == self.videoEncoder) {
            if ([self.delegate respondsToSelector:@selector(recorder:didFailToInitializeVideoEncoder:)]) {
                [self.delegate recorder:self didFailToInitializeVideoEncoder:error];
            }
        }
    }];
}

//
// Misc methods
//

- (void)dispatchBlockOnAskedQueue:(void(^)())block {
    if (self.dispatchDelegateMessagesOnMainQueue) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        block();
    }
}

+ (NSError*)createError:(NSString*)name {
    return [NSError errorWithDomain:@"SCAudioVideoRecorder" code:500 userInfo:[NSDictionary dictionaryWithObject:name forKey:NSLocalizedDescriptionKey]];
}

- (void)prepareWriterAtSourceTime:(CMTime)sourceTime fromEncoder:(GQDataEncoder *)encoder {
    // Set an encoder as ready if it's the caller or if it's not enabled
    _audioEncoderReady |= (encoder == self.audioEncoder) | !self.audioEncoder.enabled;
    _videoEncoderReady |= (encoder == self.videoEncoder) | !self.videoEncoder.enabled;
    
    // We only start the writing when both encoder are ready
    if (_audioEncoderReady && _videoEncoderReady) {
        if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
            if ([self.assetWriter startWriting]) {
                [self.assetWriter startSessionAtSourceTime:sourceTime];
            }
            self.startedTime = sourceTime;
        }
    }
}

#pragma mark - getters

- (BOOL)isPrepared {
    return self.assetWriter != nil;
}

- (BOOL)isRecording {
    return _recording;
}

- (void)setEnableSound:(BOOL)enableSound {
    self.audioEncoder.enabled = enableSound;
}

- (BOOL)enableSound {
    return self.audioEncoder.enabled;
}

- (void)setEnableVideo:(BOOL)enableVideo {
    self.videoEncoder.enabled = enableVideo;
}

- (BOOL)enableVideo {
    return self.videoEncoder.enabled;
}


@end
