//
//  DemoViewController.m
//  GCDDemo
//
//  Created by 林训键 on 2017/10/29.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "DemoViewController.h"
#import "GCDSectionModel.h"
#import "QSDispatchQueue.h"
#import "dispatchpool.h"
#import <YYDispatchQueuePool/YYDispatchQueuePool.h>

@interface DemoViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) NSArray<GCDSectionModel *> *sections;
@property (nonatomic, assign) int concurrentNum;
@property (nonatomic, assign) NSInteger count;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupUI];
}

- (void)setupData{
    _count = 1000;
    GCDSectionModel *sectionmodel = [[GCDSectionModel alloc]init];
    sectionmodel.sectionTitle = @"GCD";
    sectionmodel.titles = @[[NSString stringWithFormat:@"创建%ld个并行线程",_count],
                            [NSString stringWithFormat:@"创建%ld个串型线程",_count],
                            [NSString stringWithFormat:@"创建%ld个默认线程",_count]];
    GCDSectionModel *sectionmodel2 = [[GCDSectionModel alloc]init];
    sectionmodel2.sectionTitle = @"YYDispatchQueuePool";
    sectionmodel2.titles = @[[NSString stringWithFormat:@"创建%ld个线程池异步线程",_count],
                             [NSString stringWithFormat:@"创建%ld个线程池同步线程",_count]];
    GCDSectionModel *sectionmodel3 = [[GCDSectionModel alloc]init];
    sectionmodel3.sectionTitle = @"NSOptionQueue";
    sectionmodel3.titles = @[[NSString stringWithFormat:@"创建%ld个NSOptionQueue",_count]];
    GCDSectionModel *sectionmodel4 = [[GCDSectionModel alloc]init];
    sectionmodel4.sectionTitle = @"Group";
    sectionmodel4.titles = @[[NSString stringWithFormat:@"创建%ld个group任务",_count]];
    GCDSectionModel *sectionmodel5 = [[GCDSectionModel alloc]init];
    sectionmodel5.sectionTitle = @"QSDispatchQueue";
    sectionmodel5.titles = @[[NSString stringWithFormat:@"4队列创建%ld个异步任务",_count],
                             [NSString stringWithFormat:@"创建%ld个同步任务",_count]];
    GCDSectionModel *sectionmodel6 = [[GCDSectionModel alloc]init];
    sectionmodel6.sectionTitle = @"dispatchpool";
    sectionmodel6.titles = @[[NSString stringWithFormat:@"创建%ld个同步任务",_count],
                             [NSString stringWithFormat:@"创建%ld个异步任务",_count],
                             [NSString stringWithFormat:@"在group中执行%ld个异步任务",_count]];
    _sections = @[sectionmodel,sectionmodel2,sectionmodel3,sectionmodel4,sectionmodel5,sectionmodel6];
    dispatch_pool_init();
}

- (void)setupUI{
    _tableview = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableview.delegate = self;
    _tableview.dataSource = self;
    _tableview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tableviewcell"];
    [_tableview registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"headerView"];
    [self.view addSubview:_tableview];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    GCDSectionModel *sectionModel = [_sections objectAtIndex:section];
    return sectionModel.titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"headerView"];
    GCDSectionModel *sectionModel = [_sections objectAtIndex:section];
    [headerView.textLabel setText:sectionModel.sectionTitle];
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    GCDSectionModel *sectionModel = [_sections objectAtIndex:indexPath.section];
    NSString *title = [sectionModel.titles objectAtIndex:indexPath.row];
    UITableViewCell *cell = [_tableview dequeueReusableCellWithIdentifier:@"tableviewcell"];
    [cell.textLabel setText:title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    GCDSectionModel *sectionModel = [_sections objectAtIndex:indexPath.section];
    if(indexPath.section == 0)
    switch (indexPath.row) {
        case 0:{
            for(int i = 0; i < _count; i++){
                dispatch_queue_t queue = dispatch_queue_create("cn.coderlin.queue", DISPATCH_QUEUE_CONCURRENT);
                NSLog(@"%d:for begin",i+_concurrentNum);
                dispatch_async(queue, ^{
                    NSLog(@"%d:thread:%@,action begin",i+_concurrentNum,[NSThread currentThread]);
                    sleep(5);
                    NSLog(@"%d:thread:%@,action end",i+_concurrentNum,[NSThread currentThread]);
                });
                NSLog(@"%d:end",i+_concurrentNum);
            }
            _concurrentNum += 10;
            break;
        }
        case 1:{
            for(int i = 0; i < _count; i++){
                dispatch_queue_t queue = dispatch_queue_create("cn.coderlin.queue", DISPATCH_QUEUE_SERIAL);
                NSLog(@"%d:begin",i+_concurrentNum);
                dispatch_async(queue, ^{
                    NSLog(@"%d:thread:%@,action begin",i+_concurrentNum,[NSThread currentThread]);
                    sleep(random()%15);
                    NSLog(@"%d:thread:%@,action end",i+_concurrentNum,[NSThread currentThread]);
                });
                NSLog(@"%d:end",i+_concurrentNum);
            }
            _concurrentNum += 10;
            break;
        }
        case 2:{
            for(int i = 0; i < _count; i++){
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                NSLog(@"%d:for begin",i+_concurrentNum);
                dispatch_async(queue, ^{
                    NSLog(@"%d:thread:%@,action begin",i+_concurrentNum,[NSThread currentThread]);
                    sleep(random()%15);
                    NSLog(@"%d:thread:%@,action end",i+_concurrentNum,[NSThread currentThread]);
                });
                NSLog(@"%d:end",i+_concurrentNum);
            }
            _concurrentNum += 10;
            break;
        }
        default:
            break;
    }else if(indexPath.section == 1)
        switch (indexPath.row) {
            case 0:{
                for(int i = 0; i < _count; i++){
                    dispatch_queue_t queue = YYDispatchQueueGetForQOS(NSQualityOfServiceDefault);
                    NSLog(@"%d:for begin",i+_concurrentNum);
                    dispatch_async(queue, ^{
                        NSLog(@"%d:thread:%@,action begin",i+_concurrentNum,[NSThread currentThread]);
                        sleep(random()%15);
                        NSLog(@"%d:thread:%@,action end",i+_concurrentNum,[NSThread currentThread]);
                    });
                    NSLog(@"%d:end",i+_concurrentNum);
                }
                _concurrentNum += 10;
                break;
            }
            case 1:{
                for(int i = 0; i < _count; i++){
                    dispatch_queue_t queue2 = YYDispatchQueueGetForQOS(NSQualityOfServiceDefault);
                    NSLog(@"%d:for begin",i+_concurrentNum);
                        dispatch_async(queue2, ^{
                            NSLog(@"%d:%@,thread:%@,action begin",i+_concurrentNum,@"中",[NSThread currentThread]);
                            sleep(random()%5+0.2);
                            NSLog(@"%d:%@,thread:%@,action end",i+_concurrentNum,@"中",[NSThread currentThread]);
                        });
                    NSLog(@"%d:end",i+_concurrentNum);
                }
                _concurrentNum += 10;
                break;
            }
            default:
                break;
        }else if(indexPath.section == 2){
            switch (indexPath.row) {
                case 0:{
                    NSOperationQueue *operationQueue = [[NSOperationQueue alloc]init];
                    operationQueue.maxConcurrentOperationCount = 8;
                    for(int i = 0; i < _count; i++){
                        [operationQueue addOperationWithBlock:^{
                            NSLog(@"%d:thread:%@,action begin",i,[NSThread currentThread]);
                            sleep(random()%5+0.2);
                            NSLog(@"%d:thread:%@,action end",i,[NSThread currentThread]);
                        }];
                    }
                }break;
                default:
                    break;
            }
        }else if(indexPath.section == 3){
            switch (indexPath.row) {
                case 0:{
                    dispatch_group_t group = dispatch_group_create();
                    for(int i = 0; i< _count; i++){
                        dispatch_queue_t queue = YYDispatchQueueGetForQOS(NSQualityOfServiceDefault);
                        dispatch_group_async(group, queue, ^{
                            NSLog(@"%d:thread:%@,action begin",i,[NSThread currentThread]);
                            sleep(random()%5+0.2);
                            NSLog(@"%d:thread:%@,action end",i,[NSThread currentThread]);
                        });
                    }
                    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                        NSLog(@"Group action end");
                    });
                }break;
                default:
                    break;
            }
        }else if(indexPath.section == 4){
            switch (indexPath.row) {
                case 0:{
                    dispatch_queue_t workConcurrentQueue = dispatch_queue_create("com.jzp.async.queue", DISPATCH_QUEUE_CONCURRENT);
                    QSDispatchQueue *queue = [[QSDispatchQueue alloc]initWithQueue:workConcurrentQueue concurrentCount:8];
                    for (NSInteger i = 0; i < _count; i++) {
                        [queue async:^{
                            NSLog(@"thread-info:%@开始执行任务%d",[NSThread currentThread],(int)i);
                            sleep(random()%4+0.2);
                            NSLog(@"thread-info:%@结束执行任务%d",[NSThread currentThread],(int)i);
                        }];
                    }
                    NSLog(@"异步:主线程任务...");
                }break;
                case 1:{
                    dispatch_queue_t workConcurrentQueue = dispatch_queue_create("com.jzp.sync.queue", DISPATCH_QUEUE_CONCURRENT);
                    QSDispatchQueue *queue = [[QSDispatchQueue alloc]initWithQueue:workConcurrentQueue concurrentCount:1];
                    for (NSInteger i = 0; i < _count; i++) {
                        [queue sync:^{
                            NSLog(@"%d:thread-info:%@开始执行任务",(int)i,[NSThread currentThread]);
                            sleep(random()%4+0.2);
                            NSLog(@"%d:thread-info:%@结束执行任务",(int)i,[NSThread currentThread]);
                        }];
                    }
                    NSLog(@"异步:主线程任务...");
                }break;
                default:
                    break;
            }
        }else if(indexPath.section == 5){
            switch (indexPath.row) {
                case 0:{
                    dispatch_queue_t queue = dispatch_pool_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    for (NSInteger i = 0; i < _count; i++) {
                        dispatch_pool_sync(queue, ^{
                            NSLog(@"%d:thread-info:%@开始执行任务",(int)i,[NSThread currentThread]);
                            sleep(random()%4+0.2);
                            NSLog(@"%d:thread-info:%@结束执行任务",(int)i,[NSThread currentThread]);
                        });
                        
                    }
                }
                    break;
                case 1:{
                    //                    dispatch_queue_t queue = dispatch_pool_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    for (NSInteger i = 0; i < _count; i++) {
                        dispatch_pool_async(queue, ^{
                            NSLog(@"%d:thread-info:%@开始执行任务",(int)i,[NSThread currentThread]);
                            sleep(random()%4+0.2);
                            NSLog(@"%d:thread-info:%@结束执行任务",(int)i,[NSThread currentThread]);
                        });
                    }
                }
                    break;
                case 2:{
                    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_group_t group = dispatch_group_create();
                    for (NSInteger i = 0; i < _count; i++) {
                        dispatch_group_async(group, queue, ^{
                            NSLog(@"%d:thread-info:%@开始执行任务",(int)i,[NSThread currentThread]);
                            sleep(random()%4+0.2);
                            NSLog(@"%d:thread-info:%@结束执行任务",(int)i,[NSThread currentThread]);
                        });
                    }
                    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                        NSLog(@"end");
                    });
                }
                default:
                    break;
            }
            
        }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
