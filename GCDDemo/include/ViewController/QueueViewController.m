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

@interface QueueViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) NSArray<GCDSectionModel *> *sections;
@property (nonatomic, assign) int concurrentNum;
@property (nonatomic, assign) NSInteger count;

@end

@implementation QueueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupUI];
}

- (void)setupData{
    _count = 1000;
    GCDSectionModel *sectionmodel = [[GCDSectionModel alloc]init];
    sectionmodel.sectionTitle = @"GCD";
    sectionmodel.titles = @[[NSString stringWithFormat:@"创建%ld个并行线程,并增加10个随机任务",_count],
                            [NSString stringWithFormat:@"创建%ld个串型线程,并增加10个随机任务",_count],
                            [NSString stringWithFormat:@"创建%ld个默认线程",_count]];
    _sections = @[sectionmodel];
    initDispatchPool();
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
