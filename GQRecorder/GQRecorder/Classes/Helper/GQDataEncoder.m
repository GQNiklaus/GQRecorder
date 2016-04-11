//
//  GQDataEncoder.m
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQDataEncoder.h"
#import "GQRecorder_internal.h"

@interface GQDataEncoder ()
{
    CMTime _lastTakenFrame;
    BOOL _initialized;
}

@property (weak, nonatomic) GQRecorder *recorder;

@end

@implementation GQDataEncoder

- (instancetype)initWithRecorder:(GQRecorder *)recorder {
    if (self = [super init]) {
        self.recorder = recorder;
        self.enabled = YES;
        self.useInputFormatTypeAsOutputType = YES;
        _lastTakenFrame = CMTimeMake(0, 1);
        _initialized = NO;
    }
    return self;
}

- (AVAssetWriterInput *)createWriterInputForSampleBuffer:(CMSampleBufferRef)sampleBuffer error:(NSError *__autoreleasing *)error {
    return nil;
}

- (void)reset {
    if (self.writerInput != nil) {
        self.writerInput = nil;
        if ([self.delegate respondsToSelector:@selector(dataEncoder:didEncodeFrame:)]) {
            [self.delegate dataEncoder:self didEncodeFrame:0];
        }
    }
    _initialized = NO;
    _lastTakenFrame = CMTimeMake(0, 1);
}

- (void)dealloc {
    self.writerInput = nil;
}

#pragma mark - handle

- (CMSampleBufferRef)adjustBuffer:(CMSampleBufferRef)sample withTimeOffset:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void)initialize:(CMSampleBufferRef)sampleBuffer atFrameTime:(CMTime)frameTime {
    _initialized = YES;
    _lastTakenFrame = frameTime;
    NSError * error = nil;
    self.writerInput = [self createWriterInputForSampleBuffer:sampleBuffer error:&error];
    
    if (self.writerInput == nil && error == nil) {
        error = [GQRecorder createError:@"Encoder didn't create a WriterInput"];
    }
    
    if (self.writerInput != nil) {
        if ([self.recorder.assetWriter canAddInput:self.writerInput]) {
            [self.recorder.assetWriter addInput:self.writerInput];
        } else {
            error = [GQRecorder createError:@"Unable to add WriterInput to the AssetWriter"];
        }
    }
    
    if (error != nil) {
        if ([self.delegate respondsToSelector:@selector(dataEncoder:didFailToInitializeEncoder:)]) {
            [self.delegate dataEncoder:self didFailToInitializeEncoder:error];
        }
    }
}

- (void)computeOffset:(CMTime)frameTime {
    self.recorder.shouldComputeOffset = NO;
    
    if (CMTIME_IS_VALID(_lastTakenFrame)) {
        CMTime offset = CMTimeSubtract(frameTime, _lastTakenFrame);
        
        CMTime currentTimeOffset = self.recorder.currentTimeOffset;
        currentTimeOffset = CMTimeAdd(currentTimeOffset, offset);
        self.recorder.currentTimeOffset = CMTimeSubtract(currentTimeOffset, self.recorder.lastFrameTimeBeforePause);
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    CGSize videoSize;
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    videoSize.width = width;
//    videoSize.height = height;
//    NSLog(@"VideoSize: %f/%f", videoSize.width, videoSize.height);

    if (!self.enabled) {
        return;
    }
    CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if ([_recorder isPrepared] && [_recorder isRecording]) {
        
        if (!_initialized) {
            // 初始化AVAssetWriter
            [self initialize:sampleBuffer atFrameTime:frameTime];
        }
        
        // 设置视频写入的初始时间
        [_recorder prepareWriterAtSourceTime:frameTime fromEncoder:self];
        
        if ([self.writerInput isReadyForMoreMediaData]) {
            if (_recorder.shouldComputeOffset) {
                // 分段录视频处理时间偏移量
                [self computeOffset:frameTime];
            }
            
            CMSampleBufferRef adjustedBuffer = [self adjustBuffer:sampleBuffer withTimeOffset:_recorder.currentTimeOffset];
            
            CMTime currentTime = CMTimeSubtract(CMSampleBufferGetPresentationTimeStamp(adjustedBuffer), _recorder.startedTime);
            [self.writerInput appendSampleBuffer:adjustedBuffer];
            CFRelease(adjustedBuffer);
            
            if ([self.delegate respondsToSelector:@selector(dataEncoder:didEncodeFrame:)]) {
                [self.delegate dataEncoder:self didEncodeFrame:CMTimeGetSeconds(currentTime)];
            }
        }
        _lastTakenFrame = frameTime;
    }
}

@end
