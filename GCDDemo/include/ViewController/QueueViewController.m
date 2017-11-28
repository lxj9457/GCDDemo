//
//  MainViewController.m
//  GCDDemo
//
//  Created by 林训键 on 2017/11/16.
//  Copyright © 2017年 林训键. All rights reserved.
//

#import "QueueViewController.h"
#import "GCDSectionModel.h"
#import "dispatchpool.h"
#import "GPQActionAnalysis.h"
#import <Masonry/Masonry.h>

@interface QueueViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) NSArray<GCDSectionModel *> *sections;
@property (nonatomic, assign) int currentTaskId;

@end

@implementation QueueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupUI];
}

- (void)setupData{
    _currentTaskId = 0;
    GCDSectionModel *sectionmodel = [[GCDSectionModel alloc]init];
    sectionmodel.sectionTitle = @"优先级测试";
    sectionmodel.titles = @[@"获取主线程优先级",
                            @"获取高优先级全局队列优先级",
                            @"获取中优先级全局队列优先级",
                            @"获取低优先级全局队列优先级",
                            @"获取后台全局队列优先级",
                            @"获取自建队列优先级",
                            @"获取其他队列优先级"
                            ];
    GCDSectionModel *sectionmodel1 = [[GCDSectionModel alloc]init];
    sectionmodel1.sectionTitle = @"dispatch_pool异步功能测试";
    sectionmodel1.titles = @[@"增加一个主线程异步操作",
                            @"增加一个全局高优先级异步操作",
                            @"增加一个全局中优先级异步操作",
                            @"增加一个全局低优先级异步操作",
                            @"增加一个全局后台优先级异步操作",
                            ];
    GCDSectionModel *sectionmodel2 = [[GCDSectionModel alloc]init];
    sectionmodel2.sectionTitle = @"dispatch_pool同步功能测试";
    sectionmodel2.titles = @[@"增加一个主线程同步操作",
                             @"增加一个全局高优先级同步操作",
                             @"增加一个全局中优先级同步操作",
                             @"增加一个全局低优先级同步操作",
                             @"增加一个全局后台优先级同步操作"
                             ];
    GCDSectionModel *sectionmodel3 = [[GCDSectionModel alloc]init];
    sectionmodel3.sectionTitle = @"其他操作";
    sectionmodel3.titles = @[@"输出log",@"测试dispatch_pool性能",@"测试gcd性能"];
    
    _sections = @[sectionmodel,sectionmodel1,sectionmodel2,sectionmodel3];
    dispatch_pool_init();
}

- (void)setupUI{
    _tableview = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableview.delegate = self;
    _tableview.dataSource = self;
    [_tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tableviewcell"];
    [_tableview registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"headerView"];
    [self.view addSubview:_tableview];
    __weak __typeof(self)weakSelf = self;
    [_tableview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.view);
    }];
//    UIButton *button = [[UIButton alloc]initWithFrame:CGRectZero];
//    [self.view addSubview:button];
//    [button mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(weakSelf.view);
//    }];
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
    dispatch_qos_class_t qos;
    dispatch_queue_t queue;
    if(indexPath.section == 0){
        queue = [self ququeByTag:indexPath.row];
        qos = dispatch_queue_get_qos_class(queue, NULL);
        [self log:qos];
    }else if(indexPath.section == 1){
        queue = [self ququeByTag:indexPath.row];
        __block int currentId = _currentTaskId;
        _currentTaskId++;
        NSLog(@"%d:%@开始队列池异步任务",currentId,[NSThread currentThread]);
        dispatch_pool_async(queue, ^{
            NSLog(@"%d:%@开始执行异步任务",currentId,[NSThread currentThread]);
            sleep(random()%4+1);
            NSLog(@"%d:%@结束执行异步任务",currentId,[NSThread currentThread]);
        });
    }else if(indexPath.section == 2){
        queue = [self ququeByTag:indexPath.row];
        __block int currentId = _currentTaskId;
        _currentTaskId++;
        NSLog(@"%d:%@开始队列池异步任务",currentId,[NSThread currentThread]);
        dispatch_pool_sync(queue, ^{
            _currentTaskId ++;
            NSLog(@"%d:%@开始执行同步任务",currentId,[NSThread currentThread]);
            sleep(random()%4+1);
            NSLog(@"%d:%@结束执行同步任务",currentId,[NSThread currentThread]);
        });
    }else if(indexPath.section == 3){
        if(indexPath.row == 0){
            [[GPQActionAnalysis shareInstance] putoutAllLog];
        }else if(indexPath.row == 1){
            double beginTime = CFAbsoluteTimeGetCurrent();
            for(int i=0; i< 100000; i++){
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_pool_async(queue, ^{
                    [self sleepWithTag:i time:0.005 info:@"dispatch_pool"];
                    if(i==99999){
                        double endTime = CFAbsoluteTimeGetCurrent();
                        NSLog(@"100000个任务在dispatch_pool中执行时间为:%f\n",endTime-beginTime);
                    }
                });
            }
        }else if(indexPath.row == 2){
            double beginTime = CFAbsoluteTimeGetCurrent();
            for(int i=0; i< 100000; i++){
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(queue, ^{
                    [self sleepWithTag:i time:0.005 info:@"gcd"];
                    if(i==99999){
                        double endTime = CFAbsoluteTimeGetCurrent();
                        NSLog(@"100000个任务在gcd中执行时间为:%f\n",endTime-beginTime);
                    }
                });
            }
        }
    }
}

- (void)actionWithTag:(int)tag info:(NSString *)info{
    for(int k = 0; k < tag; k = k + 1){
        if(k == tag - 1 && tag%100 ==0){
            NSLog(@"%@:%d\n",info,tag);
        }
    }
}


- (void)sleepWithTag:(int)tag time:(double)time info:(NSString *)info{
    sleep(time);
    if(tag%100 ==0){
        NSLog(@"%@:%d\n",info,tag);
    }
}

- (dispatch_queue_t)ququeByTag:(NSInteger)tag{
    dispatch_queue_t queue;
    if(tag == 0){
        queue = dispatch_get_main_queue();
    }else if(tag == 1){
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }else if(tag == 2){
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }else if(tag == 3){
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    }else if(tag == 4){
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    }else if(tag == 5){
        queue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    }
    return queue;
}

- (void)log:(dispatch_qos_class_t)qos{
    if(qos == QOS_CLASS_USER_INTERACTIVE){
        NSLog(@"QOS_CLASS_USER_INTERACTIVE");
    }else if(qos == QOS_CLASS_USER_INITIATED){
        NSLog(@"QOS_CLASS_USER_INITIATED");
    }else if(qos == QOS_CLASS_DEFAULT){
        NSLog(@"QOS_CLASS_DEFAULT");
    }else if(qos == QOS_CLASS_UTILITY){
        NSLog(@"QOS_CLASS_UTILITY");
    }else if(qos == QOS_CLASS_BACKGROUND){
        NSLog(@"QOS_CLASS_BACKGROUND");
    }else if(qos == QOS_CLASS_UNSPECIFIED){
        NSLog(@"QOS_CLASS_UNSPECIFIED");
    }else{
        NSLog(@"other");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
