//
//  GQTouchDetector.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/8.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "GQTouchDetector.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation GQTouchDetector

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.enabled) {
        self.state = UIGestureRecognizerStateBegan;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.enabled) {
        self.state = UIGestureRecognizerStateEnded;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.enabled) {
        self.state = UIGestureRecognizerStateEnded;
    }
}

@end
