//
//  GPQActionStatistics.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/21.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "EDPMessageRecorder.h"
#import "EDPMessage.h"

static EDPMessageRecorder *instance;

@implementation EDPMessageRecorder

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

- (void)putoutAnalysisData{
    NSArray *pathArr=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *strPath=[pathArr lastObject];
    NSString *strFinalPath=[NSString stringWithFormat:@"%@/dispatch_data.txt",strPath];
    NSMutableString *string = [[NSMutableString alloc]initWithFormat:@"["];
    MessageNode *current = gMessageList->front;
    while (current != NULL) {
        if(pthread_mutex_trylock(&gMessageList->q_lock) == 0){
            Message *message = current->message;
            [string appendFormat:@"{\"task_id\":%ld,\"qos\":%d,\"log\":%d,\"time\":%f},\n",message->task_id, message->qos, message->info_type, message->time];
            current = current->next;
            pthread_mutex_unlock(&gMessageList->q_lock);
        }else{
            continue;
        }
    }
    [string deleteCharactersInRange:NSMakeRange(string.length-2, 2)];
    [string appendString:@"]"];
    [[string copy] writeToFile:strFinalPath atomically:YES];
}

@end
