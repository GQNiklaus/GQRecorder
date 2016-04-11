//
//  GQAudioEncoder.h
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQDataEncoder.h"

@interface GQAudioEncoder : GQDataEncoder<AVCaptureAudioDataOutputSampleBufferDelegate>

@property (assign, nonatomic) Float64 outputSampleRate;
@property (assign, nonatomic) int outputChannels;
@property (assign, nonatomic) int outputBitRate;

// Must be like kAudioFormat* (example kAudioFormatMPEGLayer3)
@property (assign, nonatomic) int outputEncodeType;

@end
