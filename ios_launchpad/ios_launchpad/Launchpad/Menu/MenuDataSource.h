//
//  MenuDataSource.h
//  Framehawk
//
//  Created by Hursh Prasad on 4/17/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface MenuDataSource : NSObject
 <UITableViewDataSource,
  UITableViewDelegate>
{
    NSArray* _dataArray;
}

- (void) setMenuDataFromProfile;

@end