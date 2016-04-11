//
//  GQAudioTool.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/8.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQAudioTool.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation GQAudioTool
+ (void) overrideCategoryMixWithOthers {
    UInt32 doSetProperty = 1;
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_6_0
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
#endif
}

@end
