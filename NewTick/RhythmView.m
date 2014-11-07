//
//  RhythmView.m
//  tick
//
//  Created by DuZexu on 14/10/28.
//  Copyright (c) 2014年 Duzexu. All rights reserved.
//

#import "RhythmView.h"
#import "RhythmManager.h"

@interface RhythmView ()

@end

@implementation RhythmView {
    UIButton *rhythmBtn;
    UIButton *speedBtn;
    RhythmManager *rhythmManager;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:31/255.0f green:35/255.0f blue:33/255.0f alpha:1.0f];
        rhythmManager = [[RhythmManager alloc] init];
        
        float width = self.frame.size.width;
        float height = self.frame.size.height;
        rhythmBtn = [self drawButtonWithSize:CGSizeMake(width/2.0, 60) bordered:NO];
        rhythmBtn.center = CGPointMake(width/2.0, 100);
        [rhythmBtn addTarget:self action:@selector(thythmChange:) forControlEvents:UIControlEventTouchUpInside];
        [self setTitle:[rhythmManager rhythmAtIndex:0] withFont:18 toButton:rhythmBtn];
        [self addSubview:rhythmBtn];
        
        speedBtn = [self drawButtonWithSize:rhythmBtn.frame.size bordered:YES];
        speedBtn.center = CGPointMake(width/2.0, CGRectGetMaxY(rhythmBtn.frame)+60);
        [self setTitle:[rhythmManager currentSpeed] withFont:30 toButton:speedBtn];
        [self addSubview:speedBtn];
        
        UIButton *left = [self drawButtonWithSize:CGSizeMake(60, 60) bordered:NO];
        left.center = CGPointMake(width/2.0-speedBtn.frame.size.width/2.0-50, speedBtn.center.y);
        CAShapeLayer *layer_L = [self drawTitleWithSize:left.frame.size plus:NO];
        [left.layer addSublayer:layer_L];
        [left addTarget:self action:@selector(speedDown:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:left];
        
        UIButton *right = [self drawButtonWithSize:CGSizeMake(60, 60) bordered:NO];
        right.center = CGPointMake(width/2.0+speedBtn.frame.size.width/2.0+50, speedBtn.center.y);
        CAShapeLayer *layer_R = [self drawTitleWithSize:left.frame.size plus:YES];
        [right.layer addSublayer:layer_R];
        [right addTarget:self action:@selector(speedUp:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:right];
        
        UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        playBtn.frame = CGRectMake(0, 0, rhythmBtn.frame.size.width, rhythmBtn.frame.size.width);
        playBtn.center = CGPointMake(width/2.0, height/2.0+50);
        CAShapeLayer *layerRound = [self drawRoundWithSize:playBtn.frame.size];
        layerRound.frame = playBtn.frame;
        [self.layer addSublayer:layerRound];
        [playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
        [playBtn addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:playBtn];
        
    }
    return self;
}

#pragma mark - 点击事件

- (void)thythmChange:(UIButton*)sender
{
    [self setTitle:[rhythmManager rhythmAtIndex:3] withFont:18 toButton:rhythmBtn];
}

- (void)speedChange:(UIButton*)sender
{
    
}

- (void)speedDown:(UIButton*)sender
{
    [rhythmManager downTargetRate:^(BOOL success, NSInteger speed) {
        if (success) {
            [self setTitle:[NSString stringWithFormat:@"%ld",(long)speed] withFont:30 toButton:speedBtn];
        }
    }];
}

- (void)speedUp:(UIButton*)sender
{
    [rhythmManager upTargetRate:^(BOOL success, NSInteger speed) {
        if (success) {
            [self setTitle:[NSString stringWithFormat:@"%ld",(long)speed] withFont:30 toButton:speedBtn];
        }
    }];
}

- (void)playOrPause:(UIButton*)sender
{
    !sender.selected ? [rhythmManager resume] : [rhythmManager pause];
    sender.selected = !sender.selected;
}

- (void)setTitle:(NSString*)title withFont:(float)size toButton:(UIButton*)btn
{
    NSAttributedString *titleName = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:size],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [btn setAttributedTitle:titleName forState:UIControlStateNormal];
}

#pragma mark - DrawCode
- (UIButton*)drawButtonWithSize:(CGSize)size bordered:(BOOL)bordered
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (bordered) {
        btn.layer.borderWidth = 2.0;
        btn.layer.borderColor = [UIColor colorWithRed:30/255.0f green:191/255.0f blue:121/255.0f alpha:1.0f].CGColor;
        [btn setBackgroundColor:[UIColor clearColor]];
    }else{
        [btn setBackgroundColor:[UIColor colorWithRed:30/255.0f green:191/255.0f blue:121/255.0f alpha:1.0f]];
    }
    [btn.layer setCornerRadius:10.0f];
    [btn setFrame:CGRectMake(0, 0, size.width, size.height)];
    return btn;
}

- (CAShapeLayer*)drawTitleWithSize:(CGSize)size plus:(BOOL)plus
{
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.frame = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(size.width/4.0, size.height/2.0)];
    [path addLineToPoint:CGPointMake(size.width/4.0*3, size.height/2.0)];
    if (plus) {
        [path moveToPoint:CGPointMake(size.width/2.0, size.height/4.0)];
        [path addLineToPoint:CGPointMake(size.width/2.0, size.height/4.0*3)];
    }
    layer.path = path.CGPath;
    layer.fillColor = nil;
    layer.strokeColor = [UIColor colorWithRed:31/255.0f green:35/255.0f blue:33/255.0f alpha:1.0f].CGColor;
    layer.lineWidth = 10;
    layer.lineCap = kCALineCapRound;
    
    return layer;
}

- (CAShapeLayer*)drawRoundWithSize:(CGSize)size
{
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.frame = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:layer.frame];
    CAShapeLayer *circle = [[CAShapeLayer alloc] init];
    circle.frame = layer.frame;
    circle.path = path.CGPath;
    circle.strokeColor = [UIColor colorWithRed:30/255.0f green:191/255.0f blue:121/255.0f alpha:1.0f].CGColor;
    layer.lineWidth = 2;
    circle.fillColor = nil;
    
    UIBezierPath *InsetPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(layer.frame, 12, 12)];
    CAShapeLayer *round = [[CAShapeLayer alloc] init];
    round.frame = layer.frame;
    round.path = InsetPath.CGPath;
    round.fillColor = [UIColor colorWithRed:30/255.0f green:191/255.0f blue:121/255.0f alpha:1.0f].CGColor;
    
    [layer addSublayer:circle];
    [layer addSublayer:round];
    
    return layer;
}

@end
