//
//  GQDataEncoder.h
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GQRecorder, GQDataEncoder;

@protocol GQDataEncoderDelegate <NSObject>

@optional
- (void)dataEncoder:(GQDataEncoder*)dataEncoder didEncodeFrame:(Float64)frameSecond;
- (void)dataEncoder:(GQDataEncoder *)dataEncoder didFailToInitializeEncoder:(NSError*)error;


- (void)dataEncoder:(GQDataEncoder *)dataEncoder didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface GQDataEncoder : NSObject

- (instancetype)initWithRecorder:(GQRecorder *)recorder;
- (void)reset;

/**
 *  抽象方法
 */
- (AVAssetWriterInput *)createWriterInputForSampleBuffer:(CMSampleBufferRef)sampleBuffer error:(NSError **)error;


@property (assign, nonatomic) BOOL useInputFormatTypeAsOutputType;
@property (assign, nonatomic) BOOL enabled;
@property (strong, nonatomic) AVAssetWriterInput *writerInput;
@property (weak, nonatomic) id<GQDataEncoderDelegate> delegate;
@property (weak, nonatomic, readonly) GQRecorder *recorder;

@end
