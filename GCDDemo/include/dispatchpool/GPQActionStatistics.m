//
//  GPQActionStatistics.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/21.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "GPQActionStatistics.h"

MessageList *gMessageList;

/*构造一个空队列*/
MessageList *initMessageList(){
    MessageList *plist = (MessageList *)malloc(sizeof(MessageList));
    if(plist!=NULL){
        plist->front = NULL;
        plist->rear = NULL;
        plist->size = 0;
        pthread_mutex_init(&plist->q_lock, NULL);
        pthread_cond_init(&plist->cond, NULL);
    }
    return plist;
}

/*销毁一个队列*/
void destroyList(MessageList *plist){
    if(!plist){
        return;
    }
    clearList(plist);
    pthread_mutex_destroy(&plist->q_lock);
    pthread_cond_destroy(&plist->cond);
    free(plist);
    plist = NULL;
}

/*清空一个队列*/
void clearList(MessageList *plist){
    while(!isEmpty(plist)) {
        deList(plist);
    }
}

/*判断队列是否为空*/
int isEmpty(MessageList *plist){
    if(plist->front==NULL && plist->rear==NULL && plist->size==0){
        return 1;
    }else{
        return 0;
    }
}

/*返回队列大小*/
int getSize(MessageList *plist){
    return plist->size;
}

//返回队头元素
MessageNode *getFront(MessageList *plist){
    pthread_mutex_lock(&plist->q_lock);
    while(isEmpty(plist)){
        pthread_cond_wait(&plist->cond, &plist->q_lock);
    }
    MessageNode *message = plist->front;
    pthread_mutex_unlock(&plist->q_lock);
    return message;//---->此处有bug，队列为空时，在锁释放后，plist->front可能被入队操作赋值，出现node等于NULL，而plist->front不等于NULL
}

/**
 返回队尾元素

 @param plist 列表
 @return 队尾元素
 */


MessageNode *getRear(MessageList *plist){
    MessageNode *node = NULL;
    if(!isEmpty(plist)) {
        node = plist->rear;
    }
    return node;
}

/*将新元素入队*/
MessageNode *enList(MessageList *plist, Message *message){
    MessageNode *pnode = (MessageNode *)malloc(sizeof(MessageNode));
    Message *messageCopy = (Message *)malloc(sizeof(Message));
    memcpy(messageCopy, message, sizeof(Message));
    if(pnode != NULL) {
        pnode->message = messageCopy;
        pnode->next = NULL;
        pthread_mutex_lock(&plist->q_lock);
        if(isEmpty(plist)) {
            plist->front = pnode;
        } else {
            plist->rear->next = pnode;
        }
        plist->rear = pnode;
        plist->size++;
        pthread_cond_signal(&plist->cond);
        pthread_mutex_unlock(&plist->q_lock);
    }
    return pnode;
}

/*队头元素出队*/
MessageNode * deList(MessageList *plist){
    MessageNode *pnode = plist->front;
    pthread_mutex_lock(&plist->q_lock);
    if(!isEmpty(plist)) {
        plist->size--;
        plist->front = pnode->next;
        free(pnode);
        if(plist->size==0){
            plist->rear = NULL;
        }
    }
    pthread_mutex_unlock(&plist->q_lock);
    return plist->front;
}

/*遍历队列并对各数据项调用visit函数*/
void messageListTraverse(MessageList *plist, void (*visit)(Message *message)){
    MessageNode *pnode = plist->front;
    int i = plist->size;
    while(i--){
        visit(pnode->message);
        
//        ;
        pnode = pnode->next;
    }
}

void printMessage(Message *message){
    printf("{\"task_id:%ld\",\"qos\":%d,\"log\":%s,\"time\":%f},\n",message->task_id, message->qos, message->action_info,message->time);
}

static GPQActionStatistics *instance;

@implementation GPQActionStatistics

//- (instancetype)init{
//    self = [super init];
//    return self;
//}

+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

- (instancetype)copyWithZone:(NSZone *)zone{
    return instance;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone{
    return instance;
}

- (void)putoutAllLog{
    void (*print)(Message *message) = printMessage;
    messageListTraverse(gMessageList, print);
}

@end
