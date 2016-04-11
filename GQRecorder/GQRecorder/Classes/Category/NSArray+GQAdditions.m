//
//  NSArray+GQAdditions.m
//  GQRecorder
//
//  Created by 郭琪 on 16/4/9.
//  Copyright © 2016年 guoqi. All rights reserved.
//

#import "NSArray+GQAdditions.h"

@implementation NSArray (GQAdditions)

+ (NSMutableArray*)arrayWithArrays:(NSArray*)array, ... {
    // va_list一个字符指针
    va_list args;
    // 初始化args，让其指向...之前的那个参数（这里为array）
    va_start(args, array);
    
    NSInteger totalSize = array.count;
    
    NSMutableArray * arrays = [[NSMutableArray alloc] init];
    [arrays addObject:array];
    
    NSArray *otherArray = nil;
    
    // 获取的参数的指定类型，然后返回这个指定类型的值，并且把args的位置指向变参表的下一个变量位置
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
