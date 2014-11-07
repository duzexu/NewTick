//
//  RhythmManager.h
//  NewTick
//
//  Created by 杜 泽旭 on 14/11/6.
//  Copyright (c) 2014年 杜 泽旭. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^completeBlock)(BOOL success,NSInteger speed);

@interface RhythmManager : NSObject

- (NSArray*)rhythmArray;//节奏数组
- (NSString*)rhythmAtIndex:(NSInteger)index;

- (void)upTargetRate:(completeBlock)complete;
- (void)downTargetRate:(completeBlock)complete;
- (NSString*)currentSpeed;

- (void)pause;
- (void)resume;
- (void)stop;

@end
