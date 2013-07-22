//
//  RJOBorderedView.m
//
//  Created by Robert Olivier on 7/17/13.
//  Copyright (c) 2013 Robert Joubert Olivier. All rights reserved.
//

#import "RJOBorderedView.h"

@implementation RJOBorderedView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureLayer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureLayer];
    }
    return self;
}

- (void)configureLayer
{
    self.layer.borderColor = [[UIColor blackColor] CGColor];
    self.layer.borderWidth = 2.0;
    self.layer.cornerRadius = 5.0;
    self.layer.backgroundColor = [[UIColor colorWithWhite:0.796 alpha:1.000] CGColor];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
