//
//  GQRecorder_internal.h
//  GQRecorder
//
//  Created by guoqi on 16/4/5.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQRecorder.h"

@interface GQRecorder ()
//
// Internal methods and fields
//
- (void)prepareWriterAtSourceTime:(CMTime)sourceTime fromEncoder:(GQDataEncoder *)encoder;
- (void) dispatchBlockOnAskedQueue:(void(^)())block;
+ (NSError*)createError:(NSString*)name;

@property (assign, nonatomic) BOOL shouldComputeOffset;
@property (assign, nonatomic) CMTime startedTime;
@property (assign, nonatomic) CMTime currentTimeOffset;
@property (assign, nonatomic) CMTime lastFrameTimeBeforePause;
@property (strong, nonatomic) dispatch_queue_t dispatch_queue;
@property (strong, nonatomic) AVAssetWriter * assetWriter;

@end