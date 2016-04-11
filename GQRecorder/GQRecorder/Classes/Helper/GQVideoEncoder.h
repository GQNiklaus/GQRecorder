//
//  GQVideoEncoder.h
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQDataEncoder.h"

@interface GQVideoEncoder : GQDataEncoder<AVCaptureVideoDataOutputSampleBufferDelegate>

// 获得视频比特率（bps）
+ (NSInteger)getBitsPerSecondForOutputVideoSize:(CGSize)size andBitsPerPixel:(Float32)bitsPerPixel;

// 这个属性只有在useInputFormatTypeAsOutputType失效时才有用
@property (nonatomic, assign) CGSize outputVideoSize;
@property (nonatomic, assign) CGAffineTransform outputAffineTransform;
@property (assign, nonatomic) Float32 outputBitsPerPixel;

@end
