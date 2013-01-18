//
//  CloseSessionButton.m
//  Framehawk
//
//  Created by Hursh Prasad on 4/18/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "CloseSessionButton.h"

@implementation CloseSessionButton
@synthesize cellPath;
- (id)initWithFrame:(CGRect)frame cellPath:(NSIndexPath *)indexPath
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.frame = frame;
        [self setImage:[UIImage imageNamed:@"menu_close_icon"] forState:UIControlStateNormal];
        self.cellPath = indexPath;
    }
    return self;
}

@end
