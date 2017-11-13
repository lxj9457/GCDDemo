//
//  dispatchpools.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/2.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "dispatchpool.h"
#import <UIKit/UIKit.h>


//static inline dispatch_queue_priority_t NSQualityOfServiceToDispatchPriority(NSQualityOfService qos) {
//    switch (qos) {
//        case NSQualityOfServiceUserInteractive: return DISPATCH_QUEUE_PRIORITY_HIGH;
//        case NSQualityOfServiceUserInitiated: return DISPATCH_QUEUE_PRIORITY_HIGH;
//        case NSQualityOfServiceUtility: return DISPATCH_QUEUE_PRIORITY_LOW;
//        case NSQualityOfServiceBackground: return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
//        case NSQualityOfServiceDefault: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
//        default: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
//    }
//}
//
//static inline qos_class_t NSQualityOfServiceToQOSClass(NSQualityOfService qos) {
//    switch (qos) {
//        case NSQualityOfServiceUserInteractive: return QOS_CLASS_USER_INTERACTIVE;
//        case NSQualityOfServiceUserInitiated: return QOS_CLASS_USER_INITIATED;
//        case NSQualityOfServiceUtility: return QOS_CLASS_UTILITY;
//        case NSQualityOfServiceBackground: return QOS_CLASS_BACKGROUND;
//        case NSQualityOfServiceDefault: return QOS_CLASS_DEFAULT;
//        default: return QOS_CLASS_UNSPECIFIED;
//    }
//}

static dispatch_queue_t serialQueue[4] = {0};
static dispatch_semaphore_t semaphore[4] = {0};

dispatch_queue_t dispatch_pool_get_global_queue(long identifier, unsigned long flags){
    switch (identifier) {
        case DISPATCH_QUEUE_PRIORITY_HIGH:return serialQueue[0];
        case DISPATCH_QUEUE_PRIORITY_DEFAULT:return serialQueue[1];
        case DISPATCH_QUEUE_PRIORITY_LOW:return serialQueue[2];
        case DISPATCH_QUEUE_PRIORITY_BACKGROUND:return serialQueue[3];
        default:return serialQueue[1];
    }
}

void initDispatchPool(){
    serialQueue[0] = dispatch_queue_create("sdp.nd.serial_common_high", DISPATCH_QUEUE_SERIAL);
    serialQueue[1] = dispatch_queue_create("sdp.nd.serial_common_default", DISPATCH_QUEUE_SERIAL);
    serialQueue[2] = dispatch_queue_create("sdp.nd.serial_common_low", DISPATCH_QUEUE_SERIAL);
    serialQueue[3] = dispatch_queue_create("sdp.nd.serial_common_background", DISPATCH_QUEUE_SERIAL);
    
    semaphore[0] = dispatch_semaphore_create(4);
    semaphore[1] = dispatch_semaphore_create(6);
    semaphore[2] = dispatch_semaphore_create(5);
    semaphore[3] = dispatch_semaphore_create(7);
}

void dispatch_pool_queue_sync(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_async(dispatch_pool_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        dispatch_semaphore_wait(semaphore[1], DISPATCH_TIME_FOREVER);
        dispatch_sync(queue,^{
            if (block) {
                block();
            }
            dispatch_semaphore_signal(semaphore[1]);
        });
    });
}

void dispatch_pool_queue_async(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_async(dispatch_pool_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        dispatch_semaphore_wait(semaphore[1], DISPATCH_TIME_FOREVER);
        dispatch_async(queue,^{
            if (block) {
                block();
            }
            dispatch_semaphore_signal(semaphore[1]);
        });
    });
}


static uint32_t group_task_number=0;

void dispatch_pool_group_async(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_async(dispatch_pool_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
//        OSAtomicIncrement32(group_task_number);
        dispatch_semaphore_wait(semaphore[1], DISPATCH_TIME_FOREVER);
        dispatch_async(queue,^{
            if (block) {
                block();
            }
//            OSAtomicDecrement32(group_task_number);
            if(group_task_number==0){

            };
            dispatch_semaphore_signal(semaphore[1]);
        });
    });
}

//@implementation dispatchpool
//
//- (instancetype)init{
//    self = [super init];
//    if(self){
//        if (!_semaphore) {
//            _semaphore = dispatch_semaphore_create(4);
//        }
//        if (!_serialQueue) {
//            _serialQueue = dispatch_queue_create([[NSString stringWithFormat:@"sdp.nd.serial_%p", self] UTF8String], DISPATCH_QUEUE_SERIAL);
//        }
//    }
//    return self;
//}
//
//- (dispatch_queue_t)dispatchPoolGetGlobalQueue:(long)identifier flags:(unsigned long)flags{
//    return _serialQueue;
//}
//
//
////同步
//- (void)dispatchPoolQueueSync:(dispatch_queue_t)queue block:(dispatch_block_t)block {
//    if (!block) {
//        return;
//    }
//    dispatch_sync(queue,^{
//        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);  //semaphore - 1
//        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
//            if (block) {
//                block();
//            }
//            dispatch_semaphore_signal(self.semaphore);  //semaphore + 1
//        });
//    });
//}
//
////异步
//- (void)dispatchPoolQueueAsync:(dispatch_queue_t)queue block:(dispatch_block_t)block {
//    if (!block) {
//        return;
//    }
//    dispatch_async(queue,^{
//        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);  //semaphore - 1
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
//            if (block) {
//                block();
//            }
//            dispatch_semaphore_signal(self.semaphore);  //semaphore + 1
//        });
//    });
//}
//
//@end

