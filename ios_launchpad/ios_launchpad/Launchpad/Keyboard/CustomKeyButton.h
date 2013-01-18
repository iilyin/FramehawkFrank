//
//  CustomKeyButton.h
//  Launchpad
//
//  Custom key button class
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomKeyButton : UIBarButtonItem

- (id)initWithTitle:(NSString*)title image:(UIImage*)image backroundImage:(UIImage*)backroundImage pressedBackroundImage:(UIImage*)pressedBackroundImage size:(CGSize)size;

+ (CustomKeyButton*)createWithTitle:(NSString*)title backroundImage:(UIImage*)backroundImage pressedBackroundImage:(UIImage*)pressedBackroundImage size:(CGSize)size delegate:(id<NSObject>)delegate action:(SEL)action keys:(int)keys tag:(int)tag;

+ (CustomKeyButton*)createWithImage:(UIImage*)image backroundImage:(UIImage*)backroundImage pressedBackroundImage:(UIImage*)pressedBackroundImage size:(CGSize)size delegate:(id<NSObject>)delegate action:(SEL)action keys:(int)keys tag:(int)tag;

+ (CustomKeyButton*)createWithTitle:(NSString*)title size:(CGSize)size delegate:(id<NSObject>)delegate action:(SEL)action keys:(int)keys tag:(int)tag;

@property (nonatomic, weak) id delegate;
@property (nonatomic) SEL buttonAction;
@property (nonatomic) int keys;

- (void)setSelected:(BOOL)value;
- (BOOL)selected;

@end

