//
//  dispatchpools.h
//  GCDDemo
//
//  Created by 林训键 on 2017/11/2.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import <Foundation/Foundation.h>

void dispatch_pool_init(void);

/*
 创建队列，用于创建真串行队列，或者获取一个全局并发队列，用于替代GCD的dispatch_queue_create接口,便于埋点统计和后续优化。
 @param label 队列名称
 @param attr 队列类型
 */
dispatch_queue_t dispatch_pool_queue_create(const char *_Nullable label,    dispatch_queue_attr_t _Nullable attr);

/*
 获取一个全局并发队列，用于替代GCD的 dispatch_get_global_queue 接口,便于埋点统计和后续优化。
 @param identifier 优先级
 @param flags 保留字段
 */
dispatch_queue_t dispatch_pool_get_global_queue(long identifier, unsigned long flags);

/*
 在pool中加入异步任务，用于替代GCD的 dispatch_queue_async 接口,将任务加入排队队列管理并分发到queue中执行，同时便于埋点统计和后续优化。
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_async(dispatch_queue_t queue,dispatch_block_t block);

/*
 在pool中加入同步任务，用于替代GCD的 dispatch_queue_sync 接口,将任务加入排队队列管理并分发到queue中执行，同时便于埋点统计和后续优化。
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_sync(dispatch_queue_t queue,dispatch_block_t block);

/*
 创建一个group，用于替代GCD的 dispatch_group_create 接口，便于埋点统计和后续优化。
 */
dispatch_group_t dispatch_pool_group_create(void);

/*
 在pool中加入异步group任务，用于替代GCD的 dispatch_group_async 接口,将任务加入排队队列管理并分发到queue中执行，同时便于埋点统计和后续优化。
 @param group 组
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_group_async(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);

/*
 在pool中加入同步group任务，用于替代GCD的 dispatch_group_sync 接口,将任务加入排队队列管理并分发到queue中执行，同时便于埋点统计和后续优化
 @param group 组
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_group_sync(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block);

/*
 增加一个group任务信号量，用于替代GCD的 dispatch_group_enter 接口，便于埋点统计和后续优化
 @param group 组
 */
void dispatch_pool_group_enter(dispatch_group_t group);

/*
 减少一个group任务信号量，用于替代GCD的 dispatch_group_leave 接口，便于埋点统计和后续优化
 @param group 组
 */
void dispatch_pool_group_leave(dispatch_group_t group);

/*
 在group任务完成后回调，用于替代GCD的 dispatch_group_notify 接口，便于埋点统计和后续优化
 */
void dispatch_pool_group_notify(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block);

