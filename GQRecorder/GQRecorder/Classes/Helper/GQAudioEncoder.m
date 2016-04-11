//
//  GQAudioEncoder.m
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQAudioEncoder.h"
#import "GQRecorder_internal.h"

@implementation GQAudioEncoder
- (instancetype)initWithRecorder:(GQRecorder *)recorder {
    if (self = [super initWithRecorder:recorder]) {
        self.outputBitRate = 128000;
        self.outputEncodeType = kAudioFormatMPEG4AAC;
    }
    return self;
}

// 传入视频流，设置音频输出参数，返回音频输出写入对象
- (AVAssetWriterInput*)createWriterInputForSampleBuffer:(CMSampleBufferRef)sampleBuffer error:(NSError **)error {
    // 采样率
    Float64 sampleRate = self.outputSampleRate;
    // 通道数
    int channels = self.outputChannels;
    
    if (self.useInputFormatTypeAsOutputType) { // 是否用输入格式作为输出格式
        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        const AudioStreamBasicDescription * streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        
        sampleRate = streamBasicDescription->mSampleRate;
        channels = streamBasicDescription->mChannelsPerFrame;
    }
    
    AVAssetWriterInput * audioInput = nil;
    NSDictionary * audioCompressionSetings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [ NSNumber numberWithInt: self.outputEncodeType], AVFormatIDKey,
                                              [ NSNumber numberWithInt: self.outputBitRate ], AVEncoderBitRateKey,
                                              [ NSNumber numberWithFloat: sampleRate], AVSampleRateKey,
                                              [ NSNumber numberWithInt: channels], AVNumberOfChannelsKey,
                                              nil];
    
    if ([self.recorder.assetWriter canApplyOutputSettings:audioCompressionSetings forMediaType:AVMediaTypeAudio]) {
        audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSetings];
        audioInput.expectsMediaDataInRealTime = YES;
        *error = nil;
    } else {
        *error = [GQRecorder createError:@"Cannot apply Audio settings"];
    }
    
    return audioInput;
}

@end
