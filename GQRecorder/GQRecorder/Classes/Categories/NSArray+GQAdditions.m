//
//  NSArray+GQAdditions.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/11.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "NSArray+GQAdditions.h"

@implementation NSArray (GQAdditions)

+ (NSMutableArray*) arrayWithArrays:(NSArray*)array, ... {
    // 定义一个指针变量
    va_list args;
    // 初始化args，将其指向...前面的第一个参数
    va_start(args, array);
    
    NSInteger totalSize = array.count;
    
    NSMutableArray * arrays = [[NSMutableArray alloc] init];
    [arrays addObject:array];
    
    NSArray * otherArray = nil;
    
    // va_arg获取当前指向的参数，并将位置指向下一个变量
    while ((otherArray = va_arg(args, NSArray*))) {
        totalSize += otherArray.count;
        [arrays addObject:otherArray];
    }
    
    // 释放指针
    va_end(args);
    
    NSMutableArray * resultArray = [[NSMutableArray alloc] initWithCapacity:totalSize];
    NSInteger i = 0;
    for (NSArray * stockedArray in arrays) {
        for (id element in stockedArray) {
            [resultArray setObject:element atIndexedSubscript:i];
            i++;
        }
    }
    
    return resultArray;
}

@end
