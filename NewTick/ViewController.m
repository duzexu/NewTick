//
//  ViewController.m
//  NewTick
//
//  Created by 杜 泽旭 on 14/11/4.
//  Copyright (c) 2014年 杜 泽旭. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _rhythmView = [[RhythmView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_rhythmView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
