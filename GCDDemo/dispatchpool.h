//
//  dispatchpools.h
//  GCDDemo
//
//  Created by 林训键 on 2017/11/2.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import <Foundation/Foundation.h>


void initDispatchPool(void);

/*
 获取队列
 @param identifier 优先级
 @param flags 保留字段
 */
dispatch_queue_t dispatch_pool_get_global_queue(long identifier, unsigned long flags);

/*
 在pool中加入同步任务
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_queue_sync(dispatch_queue_t queue,dispatch_block_t block);

/*
 在pool中加入异步任务
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_queue_async(dispatch_queue_t queue,dispatch_block_t block);
/*
 在pool中异步执行group任务
 @param group 组
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_group_async(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);

/*
 在pool中异步执行group任务
 @param group 组
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_group_sync(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);
//
//@interface dispatchpool : NSObject
//
////同步
//- (void)dispatchPoolQueueSync:(dispatch_queue_t)queue block:(dispatch_block_t)block;
//
////异步
//- (void)dispatchPoolQueueAsync:(dispatch_queue_t)queue block:(dispatch_block_t)block;
//
//@end

