//
//  GPQActionStatistics.h
//  GCDDemo
//
//  Created by 林训键 on 2017/11/21.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct queueMessageNode{
    long task_id;
    char *task_info;
    char *queue_info;
    char *message;
    int qos;
    double time;
    struct queueMessageNode *next;
}messageNode, *messageList;

//messageNode create_message_list(void);

void add_message_to_list(char * message);
void print_messages(messageList list);

@interface GPQActionStatistics : NSObject

@end

