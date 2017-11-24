//
//  GPQActionStatistics.h
//  GCDDemo
//
//  Created by 林训键 on 2017/11/21.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdlib.h>
#include <pthread.h>


//typedef enum taskStatus{
//    taskStatusEnterLineQueue = 1;
//    taskStatusWait = ;
//    taskStatusLeaveLineQueue = 0;
//};

typedef struct{
    long task_id;
    char *task_info;
    char *queue_info;
    char *action_info;
    int qos;
    double time;
}Message;

typedef struct messageNode{
    Message *message;
    struct messageNode *next;
}MessageNode;

typedef struct{
    MessageNode *front;
    MessageNode *rear;
    int size;
    pthread_mutex_t q_lock;
    pthread_cond_t cond;
}MessageList;

extern MessageList *gMessageList;

MessageList *initMessageList(void);

/*销毁一个队列*/
void destroyList(MessageList *);

/*清空一个队列*/
void clearList(MessageList *);

/*判断队列是否为空*/
int isEmpty(MessageList *);

/*返回队列大小*/
int getSize(MessageList *);

/*返回队头元素*/
MessageNode *getFront(MessageList *plist);

/*返回队尾元素*/
MessageNode *getRear(MessageList *plist);

/*将新元素入队*/
MessageNode *enList(MessageList *plist, Message *message);

/*队头元素出队*/
MessageNode *deList(MessageList *);

/*遍历队列并对各数据项调用visit函数*/
void messageListTraverse(MessageList *plist, void (*visit)(Message *message));


@interface GPQActionStatistics : NSObject

+ (instancetype)shareInstance;

- (void)putoutAllLog;

@end

