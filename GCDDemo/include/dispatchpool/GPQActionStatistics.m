//
//  GPQActionStatistics.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/21.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "GPQActionStatistics.h"
//#include <vector>

static messageNode *lastMessage;
static messageNode *headMessage;
static int messageNum = 0;

void print_messages(messageList list){
    for(messageNode *node = list; node->next != NULL; node = node->next){
        printf("%s",node->message);
    }
}

void add_message_to_list(long task_id, char * msg){
    
    if(strlen(msg) != 0){
//        printf("%s",msg);
        messageNode *message_node = (messageNode *)malloc(sizeof(messageNode));
        message_node -> message = msg;
        message_node -> next = NULL;
        message_node -> task_id = task_id;
        messageNum ++;
        if(lastMessage != NULL){
            lastMessage -> next = message_node;
            lastMessage = message_node;
        }else{
            headMessage = message_node;
            lastMessage = message_node;
        }
        print_messages(headMessage);
    }
}


@implementation GPQActionStatistics



@end
