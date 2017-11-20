//
//  dispatchpools.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/2.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "dispatchpool.h"


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

static dispatch_queue_t lineQueues[4] = {0};
static dispatch_semaphore_t semaphores[4] = {0};

dispatch_queue_t dispatch_pool_get_global_queue(long identifier, unsigned long flags){
    dispatch_queue_t queue = dispatch_get_global_queue(identifier, flags);
    return queue;
}

dispatch_queue_t dispatch_pool_serial_queue_create(const char *_Nullable label,long identifier){
    dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(identifier, 0));
    return queue;
}

void initDispatchPool(){
    lineQueues[0] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_high", DISPATCH_QUEUE_PRIORITY_HIGH);
    lineQueues[1] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_default", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    lineQueues[2] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_low", DISPATCH_QUEUE_PRIORITY_LOW);
    lineQueues[3] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_background", DISPATCH_QUEUE_PRIORITY_BACKGROUND);
    semaphores[0] = dispatch_semaphore_create(4);
    semaphores[1] = dispatch_semaphore_create(6);
    semaphores[2] = dispatch_semaphore_create(5);
    semaphores[3] = dispatch_semaphore_create(7);
}

dispatch_semaphore_t dispatch_pool_get_line_queue_semaphore_with_qos(dispatch_qos_class_t qos){
    dispatch_semaphore_t semaphore;
    switch (qos) {
        case QOS_CLASS_UNSPECIFIED:
        case QOS_CLASS_DEFAULT:{
            semaphore = semaphores[1];
        }break;
        case QOS_CLASS_USER_INITIATED:{
            semaphore = semaphores[0];
        }break;
        case QOS_CLASS_UTILITY:{
            semaphore = semaphores[2];
        }break;
        case QOS_CLASS_BACKGROUND:{
            semaphore = semaphores[3];
        }break;
        case QOS_CLASS_USER_INTERACTIVE:{
            semaphore = semaphores[0];
        }break;
        default:{
            semaphore = semaphores[1];
        }break;
    }
    return semaphore;
}

dispatch_queue_t dispatch_pool_get_line_queue_with_qos(dispatch_qos_class_t qos){
    dispatch_queue_t queue;
    switch (qos) {
        case QOS_CLASS_UNSPECIFIED:
        case QOS_CLASS_DEFAULT:{
            queue = lineQueues[1];
        }break;
        case QOS_CLASS_USER_INITIATED:{
            queue = lineQueues[0];
        }break;
        case QOS_CLASS_UTILITY:{
            queue = lineQueues[2];
        }break;
        case QOS_CLASS_BACKGROUND:{
            queue = lineQueues[3];
        }break;
        case QOS_CLASS_USER_INTERACTIVE:{
            queue = dispatch_get_main_queue();
        }break;
        default:{
            queue = lineQueues[1];
        }break;
    }
    return queue;
}

BOOL is_qos_class_user_interactive(dispatch_qos_class_t qos){
    if(qos == QOS_CLASS_USER_INTERACTIVE){
        return true;
    }
    return false;
}

void dispatch_pool_queue_sync(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_qos_class_t qos = dispatch_queue_get_qos_class(queue, NULL);
    if(is_qos_class_user_interactive(qos)){
        dispatch_sync(dispatch_get_main_queue(), block);
    }else{
        dispatch_queue_t lineQueue = dispatch_pool_get_line_queue_with_qos(qos);
        dispatch_semaphore_t semaphorse = dispatch_pool_get_line_queue_semaphore_with_qos(qos);
        dispatch_async(lineQueue,^{
            dispatch_semaphore_wait(semaphorse, DISPATCH_TIME_FOREVER);
            dispatch_sync(queue,^{
                if (block) {
                    block();
                }
                dispatch_semaphore_signal(semaphorse);
            });
        });
    }
}

void dispatch_pool_queue_async(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_qos_class_t qos = dispatch_queue_get_qos_class(queue, NULL);
    if(is_qos_class_user_interactive(qos)){
        dispatch_async(dispatch_get_main_queue(), block);
    }else{
        dispatch_queue_t lineQueue = dispatch_pool_get_line_queue_with_qos(qos);
        dispatch_semaphore_t semaphorse = dispatch_pool_get_line_queue_semaphore_with_qos(qos);
        dispatch_async(lineQueue,^{
            dispatch_semaphore_wait(semaphorse, DISPATCH_TIME_FOREVER);
            dispatch_async(queue,^{
                if (block) {
                    block();
                }
                dispatch_semaphore_signal(semaphorse);
            });
        });
    }
}
