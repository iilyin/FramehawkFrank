//
//  MenuSelectionCell.h
//  Framehawk
//
//  Created by Hursh Prasad on 4/17/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuSelectionCell : UITableViewCell
@property (strong,nonatomic) NSString *command;
@property (atomic) BOOL connectionIsClosed;
-(void)setSelectionCommand:(NSString *)selectionCommand;

@end