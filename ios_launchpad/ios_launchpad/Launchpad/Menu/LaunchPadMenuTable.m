//
//  LaunchPadMenuTable.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/17/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import "CommandCenter.h"
#import "LaunchPadMenuTable.h"


@implementation LaunchPadMenuTable


- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {

        // Configure
        self.backgroundColor = [UIColor clearColor];
        self.scrollEnabled = NO;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}


@end