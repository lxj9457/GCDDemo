//
//  dispatchpools.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/2.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "dispatchpool.h"
#import "GPQActionAnalysis.h"
#import <libkern/OSAtomic.h>

typedef struct task_node{
    int task_id;
    dispatch_queue_t queue;
    dispatch_block_t block;
    struct task_node *pre;
    struct task_node *next;
}taskNode;

typedef struct{
    taskNode *front;
    taskNode *rear;
    int size;
    pthread_mutex_t q_lock;
    pthread_cond_t cond;
}taskList;

taskList *gWaitList;
taskList *gDoList;
int maxTaskNum = 2;
int currentTaskNum = 0;

static dispatch_queue_t lineQueues[4] = {0};
static dispatch_semaphore_t semaphores[4] = {0};
static long task_id = 0;

taskList *initTaskList(void);
void actionTask(taskNode *node);

dispatch_queue_t dispatch_pool_get_global_queue(long identifier, unsigned long flags){
    dispatch_queue_t queue = dispatch_get_global_queue(identifier, flags);
    return queue;
}

dispatch_queue_t dispatch_pool_serial_queue_create(const char *_Nullable label,long identifier){
    dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(identifier, 0));
    return queue;
}



void dispatch_pool_init(){
    lineQueues[0] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_high", DISPATCH_QUEUE_PRIORITY_HIGH);
    lineQueues[1] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_default", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    lineQueues[2] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_low", DISPATCH_QUEUE_PRIORITY_LOW);
    lineQueues[3] = dispatch_pool_serial_queue_create("sdp.nd.serial_common_background", DISPATCH_QUEUE_PRIORITY_BACKGROUND);
    semaphores[0] = dispatch_semaphore_create(20);
    semaphores[1] = dispatch_semaphore_create(20);
    semaphores[2] = dispatch_semaphore_create(20);
    semaphores[3] = dispatch_semaphore_create(20);
    gMessageList = initMessageList();
    gWaitList = initTaskList();
    gDoList = initTaskList();
    printf("init");
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

char *qosStr_with_qos(dispatch_qos_class_t qos){
    char *qosStr;
    switch (qos) {
        case QOS_CLASS_UNSPECIFIED:
        case QOS_CLASS_DEFAULT:{
            qosStr = "默认优先级";
        }break;
        case QOS_CLASS_USER_INITIATED:{
            qosStr = "高优先级";
        }break;
        case QOS_CLASS_UTILITY:{
            qosStr = "低优先级";
        }break;
        case QOS_CLASS_BACKGROUND:{
            qosStr = "后台优先级";
        }break;
        case QOS_CLASS_USER_INTERACTIVE:{
            qosStr = "主线程";
        }break;
        default:{
            qosStr = "默认优先级";
        }break;
    }
    return qosStr;
}

BOOL is_qos_class_user_interactive(dispatch_qos_class_t qos){
    if(qos == QOS_CLASS_USER_INTERACTIVE){
        return true;
    }
    return false;
}

void dispatch_pool_sync(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_qos_class_t qos = dispatch_queue_get_qos_class(queue, NULL);
    __block long current_task_id = task_id;
    task_id++;
    enList(gMessageList, &(Message){current_task_id,"","",fun_dispatch_pool_sync,qos,CFAbsoluteTimeGetCurrent()});
    if(is_qos_class_user_interactive(qos)){
        dispatch_sync(queue, block);
    }else{
        dispatch_queue_t lineQueue = dispatch_pool_get_line_queue_with_qos(qos);
        dispatch_semaphore_t semaphorse = dispatch_pool_get_line_queue_semaphore_with_qos(qos);
        dispatch_sync(lineQueue,^{
            CFAbsoluteTime enterTime = CFAbsoluteTimeGetCurrent();
            enList(gMessageList, &(Message){current_task_id,"","",taskStatus_EnterLineQueue,qos,enterTime});
            dispatch_semaphore_wait(semaphorse, DISPATCH_TIME_FOREVER);
            dispatch_sync(queue,^{
                CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
                enList(gMessageList, &(Message){current_task_id,"","",taskStatus_StartTask,qos,startTime - enterTime});
                if (block) {
                    block();
                }
                dispatch_semaphore_signal(semaphorse);
                CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                enList(gMessageList, &(Message){current_task_id,"","",taskStatus_StartTask,qos,endTime - startTime});
            });
        });
    }
}


taskList *initTaskList(){
    taskList *plist = (taskList *)malloc(sizeof(taskList));
    if(plist!=NULL){
        plist->front = NULL;
        plist->rear = NULL;
        plist->size = 0;
        pthread_mutex_init(&plist->q_lock, NULL);
        pthread_cond_init(&plist->cond, NULL);
    }
    return plist;
}

int isTaskListEmpty(taskList *plist){
    if(plist->front==NULL && plist->size==0){
        return 1;
    }else{
        return 0;
    }
}

int getTaskListSize(taskList *plist){
    return plist->size;
}

taskNode *getTaskListFront(taskList *plist){
    pthread_mutex_lock(&plist->q_lock);
    while(isTaskListEmpty(plist)){
        pthread_cond_wait(&plist->cond, &plist->q_lock);
    }
    taskNode *message = plist->front;
    pthread_mutex_unlock(&plist->q_lock);
    return message;//---->此处有bug，队列为空时，在锁释放后，plist->front可能被入队操作赋值，出现node等于NULL，而plist->front不等于NULL
}

void enTaskList(taskList *plist, taskNode *pnode){
    if(pnode != NULL) {
        pthread_mutex_lock(&plist->q_lock);
        if(isTaskListEmpty(plist)) {
            plist->front = pnode;
        } else {
            pnode->pre=plist->rear;
            plist->rear->next = pnode;
        }
        plist->rear = pnode;
        plist->size++;
        pthread_cond_signal(&plist->cond);
        pthread_mutex_unlock(&plist->q_lock);
    }
    return;
}

void deTaskList(taskList *plist, taskNode *taskNode){
    pthread_mutex_lock(&plist->q_lock);
    taskList *waitList = gWaitList;
    taskList *doList = gDoList;
    if(!isTaskListEmpty(plist)) {
        if(taskNode->pre != NULL){
            taskNode->pre->next = taskNode->next;
        }else if(taskNode->next != NULL){
            taskNode->next->pre = taskNode->pre;
        }
        if(gWaitList->rear == taskNode){
            gWaitList->rear = taskNode->pre;
        }
        if(plist->front == taskNode){
            plist->front = taskNode->next;
        }
        plist->size--;
//        free(taskNode);
        if(plist->size==0){
            plist->front = NULL;
            plist->rear = NULL;
        }
    }
    pthread_cond_signal(&plist->cond);
    pthread_mutex_unlock(&plist->q_lock);
    return;
}



void moveListFrontToOthersRear(taskList *waitList,taskList *doList){
    //        printf("%d:离开等待队列\n",node->task_id);
    pthread_mutex_lock(&gWaitList->q_lock);
    taskNode *node = gWaitList -> front;
    gWaitList->front = gWaitList->front->next;
    if(gWaitList->rear == node){
        gWaitList->rear = NULL;
    }
    gWaitList->size--;
    //        printf("%d:加入执行队列\n",node->task_id);
    enTaskList(gDoList, node);
    pthread_cond_signal(&gWaitList->cond);
    pthread_mutex_unlock(&gWaitList->q_lock);
}

void pool_async(){
    if(gDoList->front){
        taskNode *node = gDoList->front;
        printf("%d:发起异步执行\n",node->task_id);
        dispatch_async(node->queue,^{
            taskList *waitList = gWaitList;
            taskList *doList = gDoList;
            printf("%d:开始执行\n",node->task_id);
            if(node->block){
                            node->block();
            }
            printf("%d:执行结束\n",node->task_id);
            deTaskList(gDoList, node);
            pool_async();
        });
    }
}

void actionTask(taskNode *node){
    taskList *waitList = gWaitList;
    taskList *doList = gDoList;
    while(gDoList->size < maxTaskNum && gWaitList->front != NULL){
        moveListFrontToOthersRear(gWaitList,doList);
    }
    pool_async();
};


void dispatch_pool_async(dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_qos_class_t qos = dispatch_queue_get_qos_class(queue, NULL);
    int current_task_id = OSAtomicIncrement32(&task_id);
    if(is_qos_class_user_interactive(qos)){
        dispatch_async(queue, block);
    }else{
        taskList *waitList = gWaitList;
        taskList *doList = gDoList;
        taskNode *pnodeCopy = (taskNode *)malloc(sizeof(taskNode));
        dispatch_queue_t queueCopy;
//        memcpy(, , )
        
        memcpy(pnodeCopy, &(taskNode){current_task_id,queue,block,NULL,NULL}, sizeof(taskNode));
        enTaskList(gWaitList,pnodeCopy);
//        printf("%d:加入等待队列\n",pnodeCopy->task_id);
        actionTask(pnodeCopy);
    }
}

dispatch_group_t dispatch_pool_group_create(){
    enList(gMessageList, &(Message){0,"","",fun_dispatch_pool_group_create,-1,CFAbsoluteTimeGetCurrent()});
    return dispatch_group_create();
}

/*
 在pool中加入异步group任务，用于替代GCD的 dispatch_group_async 接口,将任务加入排队队列管理并分发到queue中执行，同时便于埋点统计和后续优化。
 @param group 组
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_group_async(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
        dispatch_qos_class_t qos = dispatch_queue_get_qos_class(queue, NULL);
    __block long current_task_id = task_id;
    task_id++;
    enList(gMessageList, &(Message){current_task_id,"","",fun_dispatch_pool_group_async,qos,CFAbsoluteTimeGetCurrent()});
    if(is_qos_class_user_interactive(qos)){
        dispatch_group_async(group,queue, block);
    }else{
        dispatch_queue_t lineQueue = dispatch_pool_get_line_queue_with_qos(qos);
        dispatch_semaphore_t semaphorse = dispatch_pool_get_line_queue_semaphore_with_qos(qos);
        dispatch_async(lineQueue,^{
            dispatch_semaphore_wait(semaphorse, DISPATCH_TIME_FOREVER);
            dispatch_group_async(group, queue,^{
                if (block) {
                    block();
                }
                dispatch_semaphore_signal(semaphorse);
            });
        });
    }
}

/*
 在pool中加入同步group任务，用于替代GCD的 dispatch_group_sync 接口,将任务加入排队队列管理并分发到queue中执行，同时便于埋点统计和后续优化
 @param group 组
 @param queue 队列
 @param block 任务block
 */
void dispatch_pool_group_sync(dispatch_group_t group,dispatch_queue_t queue,dispatch_block_t block){
    if (!block) {
        return;
    }
    dispatch_qos_class_t qos = dispatch_queue_get_qos_class(queue, NULL);
    __block long current_task_id = task_id;
    task_id++;
    enList(gMessageList, &(Message){current_task_id,"","",fun_dispatch_pool_group_sync,qos,CFAbsoluteTimeGetCurrent()});
    if(is_qos_class_user_interactive(qos)){
        dispatch_group_async(group, queue, block);
    }else{
        dispatch_queue_t lineQueue = dispatch_pool_get_line_queue_with_qos(qos);
        dispatch_semaphore_t semaphorse = dispatch_pool_get_line_queue_semaphore_with_qos(qos);
//        dispatch_sync(lineQueue,^{
//            dispatch_semaphore_wait(semaphorse, DISPATCH_TIME_FOREVER);
            dispatch_group_async(group, queue,^{
                
                if (block) {
                    block();
                }
//                dispatch_semaphore_signal(semaphorse);
            });
//        });
    }
}



/*
 增加一个group任务信号量，用于替代GCD的 dispatch_group_enter 接口，便于埋点统计和后续优化
 @param group 组
 */
void dispatch_pool_group_enter(dispatch_group_t group){
    __block long current_task_id = task_id;
    task_id++;
    enList(gMessageList, &(Message){current_task_id,"","",fun_dispatch_pool_group_enter,-1,CFAbsoluteTimeGetCurrent()});
    dispatch_group_enter(group);
}

/*
 减少一个group任务信号量，用于替代GCD的 dispatch_group_leave 接口，便于埋点统计和后续优化
 @param group 组
 */
void dispatch_pool_group_leave(dispatch_group_t group){
    __block long current_task_id = task_id;
    task_id++;
    enList(gMessageList, &(Message){current_task_id,"","",fun_dispatch_pool_group_leave,-1,CFAbsoluteTimeGetCurrent()});
    dispatch_group_leave(group);
}

/*
 在group任务完成后回调，用于替代GCD的 dispatch_group_notify 接口，便于埋点统计和后续优化
 */
void dispatch_pool_group_notify(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block){
    enList(gMessageList, &(Message){0,"","",fun_dispatch_pool_group_notify,-1,CFAbsoluteTimeGetCurrent()});
    dispatch_group_notify(group, queue,block);
}


