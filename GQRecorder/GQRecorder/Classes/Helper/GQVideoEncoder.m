//
//  GQVideoEncoder.m
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQVideoEncoder.h"
#import "GQRecorder_internal.h"

@implementation GQVideoEncoder

- (instancetype)initWithRecorder:(GQRecorder *)recorder {
    if (self = [super initWithRecorder:recorder]) {
        self.outputAffineTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
        self.outputBitsPerPixel = 1000;
    }
    return self;
}

+ (NSInteger)getBitsPerSecondForOutputVideoSize:(CGSize)size andBitsPerPixel:(Float32)bitsPerPixel {
    // 获得像素
    int numPixels = size.width * size.height;
    
    return (NSInteger)((Float32)numPixels * bitsPerPixel);
}

// 视频合成
- (AVAssetWriterInput *)createWriterInputForSampleBuffer:(CMSampleBufferRef)sampleBuffer error:(NSError **)error {
    CGSize videoSize = self.outputVideoSize;
    
    if (self.useInputFormatTypeAsOutputType) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        videoSize.width = width;
        videoSize.height = height;
        NSLog(@"VideoSize: %f/%f", videoSize.width, videoSize.height);
    }
    
    // 获取视频流比特率
    NSInteger bitsPerSecond = [GQVideoEncoder getBitsPerSecondForOutputVideoSize:videoSize andBitsPerPixel:self.outputBitsPerPixel];
    
    AVAssetWriterInput *assetWriterVideoIn = nil;

    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:videoSize.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:videoSize.height], AVVideoHeightKey,
                                              
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                              nil], AVVideoCompressionPropertiesKey,
                                    
                                              nil];
    if ([self.recorder.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        assetWriterVideoIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        assetWriterVideoIn.expectsMediaDataInRealTime = YES;
        assetWriterVideoIn.transform = self.outputAffineTransform;
        *error = nil;
    } else {
        *error = [GQRecorder createError:@"Unable to configure output settings"];
    }
    return assetWriterVideoIn;
}

@end
