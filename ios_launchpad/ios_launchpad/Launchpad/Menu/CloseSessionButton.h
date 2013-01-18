//
//  CloseSessionButton.h
//  Framehawk
//
//  Button used to close associated session
//
//  Created by Hursh Prasad on 4/18/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloseSessionButton : UIButton
@property (nonatomic) NSIndexPath *cellPath;
- (id)initWithFrame:(CGRect)frame cellPath:(NSIndexPath *)indexPath;
@end