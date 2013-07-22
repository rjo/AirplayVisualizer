//
//  RJOVisualizerControlView.m
//  grid
//
//  Created by Robert Olivier on 7/19/13.
//  Copyright (c) 2013 Robert Joubert Olivier. All rights reserved.
//

#import "RJOVisualizerControlView.h"

@implementation RJOVisualizerControlView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    path.lineJoinStyle = kCGLineJoinRound;

    CGFloat lw = 2;
    CGFloat r = 5;
    CGFloat w = self.frame.size.width - lw;
    CGFloat h = self.frame.size.height - lw;
    CGFloat nw = 205;
    CGFloat nh = 75;
    path.lineWidth = lw;
    
    [[UIColor blackColor] setStroke];
    [[UIColor colorWithWhite:0.796 alpha:1.000] setFill];
    
    [path moveToPoint:CGPointMake(r, lw)];
    [path addLineToPoint:CGPointMake(w-r, lw)];
    [path addArcWithCenter:CGPointMake(w-r, lw+r) radius:5.0 startAngle:4.71238898038469 endAngle:6.28318530717959 clockwise:YES];
    [path addLineToPoint:CGPointMake(w, h - r - nh)];
    [path addArcWithCenter:CGPointMake(w-r,h-r - nh) radius:5.0 startAngle:6.28318530717959 endAngle:1.5707963267949 clockwise:YES];
    [path addLineToPoint:CGPointMake(w + r - nw,h - nh)];
    [path addArcWithCenter:CGPointMake(w + r - nw,h + r - nh) radius:5.0 startAngle:4.71238898038469 endAngle:3.141592653589793 clockwise:NO];
    [path addLineToPoint:CGPointMake(w - nw,h - r)];
    [path addArcWithCenter:CGPointMake(w - r - nw,h - r) radius:5.0 startAngle:6.28318530717959 endAngle:1.5707963267949 clockwise:YES];
    [path addLineToPoint:CGPointMake(lw+r,h)];
    [path addArcWithCenter:CGPointMake(lw+r,h-r) radius:5.0 startAngle:1.5707963267949 endAngle:3.141592653589793 clockwise:YES];
    [path addLineToPoint:CGPointMake(lw, lw+r)];
    [path addArcWithCenter:CGPointMake(lw+r,lw+r) radius:5.0 startAngle:3.141592653589793  endAngle:4.71238898038469 clockwise:YES];
    [path closePath];
    [path fill];
    [path stroke];
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(520,30)];
    [path addLineToPoint:CGPointMake(520, 180)];
    [path stroke];
    
}

@end
