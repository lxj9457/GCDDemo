//
//  dispatchpools.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/2.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "dispatchpool.h"
#import <UIKit/UIKit.h>


static inline dispatch_queue_priority_t NSQualityOfServiceToDispatchPriority(NSQualityOfService qos) {
    switch (qos) {
        case NSQualityOfServiceUserInteractive: return DISPATCH_QUEUE_PRIORITY_HIGH;
        case NSQualityOfServiceUserInitiated: return DISPATCH_QUEUE_PRIORITY_HIGH;
        case NSQualityOfServiceUtility: return DISPATCH_QUEUE_PRIORITY_LOW;
        case NSQualityOfServiceBackground: return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
        case NSQualityOfServiceDefault: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
        default: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
    }
}

static inline qos_class_t NSQualityOfServiceToQOSClass(NSQualityOfService qos) {
    switch (qos) {
        case NSQualityOfServiceUserInteractive: return QOS_CLASS_USER_INTERACTIVE;
        case NSQualityOfServiceUserInitiated: return QOS_CLASS_USER_INITIATED;
        case NSQualityOfServiceUtility: return QOS_CLASS_UTILITY;
        case NSQualityOfServiceBackground: return QOS_CLASS_BACKGROUND;
        case NSQualityOfServiceDefault: return QOS_CLASS_DEFAULT;
        default: return QOS_CLASS_UNSPECIFIED;
    }
}

static dispatch_queue_t serialQueue[4] = {0};
static dispatch_semaphore_t semaphore[4] = {0};

dispatch_queue_t dispatch_pool_get_global_queue(long identifier, unsigned long flags){
//    switch (identifier) {
//        case DISPATCH_QUEUE_PRIORITY_HIGH:return serialQueue[0];
//        case DISPATCH_QUEUE_PRIORITY_DEFAULT:return serialQueue[1];
//        case DISPATCH_QUEUE_PRIORITY_LOW:return serialQueue[2];
//        case DISPATCH_QUEUE_PRIORITY_BACKGROUND:return serialQueue[3];
//        default:return serialQueue[1];
//    }
    dispatch_queue_t queue = dispatch_get_global_queue(identifier, flags);
    return queue;
}

dispatch_queue_t dispatch_pool_serial_queue_create(const char *_Nullable label,long identifier){
    //    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
    //        dispatch_qos_class_t qosClass = NSQualityOfServiceToQOSClass(qos);
    //        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qosClass, 0);
    //        return dispatch_queue_create(label, attr);
    //    } else {
    long identifier = NSQualityOfServiceToDispatchPriority(qos);
    dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(identifier, 0));
    return queue;
    //    }
}

void initDispatchPool(){
    serialQueue[0] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_high", DISPATCH_QUEUE_PRIORITY_HIGH);
    serialQueue[1] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_default", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    serialQueue[2] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_low", DISPATCH_QUEUE_PRIORITY_LOW);
    serialQueue[3] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_background", DISPATCH_QUEUE_PRIORITY_BACKGROUND);
    semaphore[0] = dispatch_semaphore_create(4);
    semaphore[1] = dispatch_semaphore_create(6);
    semaphore[2] = dispatch_semaphore_create(5);
    semaphore[3] = dispatch_semaphore_create(7);
}

void dispatch_pool_queue_sync(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    
    
    dispatch_queue_t queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(<#dispatch_object_t  _Nonnull object#>, <#dispatch_queue_t  _Nullable queue#>)
//    dispatch_set_target_queue(queue, dispatch_get_global_queue(identifier, 0));
    
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
//
//
//static uint32_t group_task_number=0;
//
//void dispatch_pool_group_async(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block){
//    if (!block) {
//        return;
//    }
//    dispatch_async(dispatch_pool_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
//        dispatch_semaphore_wait(semaphore[1], DISPATCH_TIME_FOREVER);
//        dispatch_async(queue,^{
//            if (block) {
//                block();
//            }
//            if(group_task_number==0){
//
//            };
//            dispatch_semaphore_signal(semaphore[1]);
//        });
//    });
//}

