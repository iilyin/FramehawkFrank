//
//  CustomKeyButton.m
//  Launchpad
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "CustomKeyButton.h"
#import "UIUtils.h"
#import "InvokeSelector.h"

@implementation CustomKeyButton

@synthesize delegate, buttonAction, keys;


- (id)initWithTitle:(NSString*)title image:(UIImage*)image backroundImage:(UIImage*)backroundImage pressedBackroundImage:(UIImage*)pressedBackroundImage size:(CGSize)size
{
    if (image || backroundImage || pressedBackroundImage)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [UIUtils layoutKeyboardButton:button];
        button.frame = CGRectMake(0, 0, size.width, size.height);
        
        //set title if not nil
        if (title)
        {
            [button setTitle:title forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        }
        
        //set image if not nil
        if (image)
            [button setImage:image forState:UIControlStateNormal];
        
        //set backgroud image if not nil
        if (backroundImage)
            [button setImage:backroundImage forState:UIControlStateNormal];
        
        //set pressed background image if specified
        if (pressedBackroundImage)
        {
            [button setImage:pressedBackroundImage forState:UIControlStateHighlighted];
            [button setImage:pressedBackroundImage forState:UIControlStateSelected];
        }
        
        self = [self initWithCustomView:button];
        if (self)
            [button addTarget:self action:@selector(buttonTap:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
        self = [super initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:@selector(buttonTap:)];
    
    return self;
}


+ (CustomKeyButton*)createWithTitle:(NSString*)title backroundImage:(UIImage*)backroundImage pressedBackroundImage:(UIImage*)pressedBackroundImage size:(CGSize)size delegate:(id<NSObject>)delegate action:(SEL)action keys:(int)keys tag:(int)tag
{
    CustomKeyButton *button = [[CustomKeyButton alloc] initWithTitle:title image:nil backroundImage:backroundImage pressedBackroundImage:pressedBackroundImage size:size];
    
    if (button)
    {
        button.delegate = delegate;
        button.buttonAction = action;
        button.keys = keys;
        button.tag = tag;
    }
    return button;
}

+ (CustomKeyButton*)createWithImage:(UIImage*)image backroundImage:(UIImage*)backroundImage pressedBackroundImage:(UIImage*)pressedBackroundImage size:(CGSize)size delegate:(id<NSObject>)delegate action:(SEL)action keys:(int)keys tag:(int)tag
{
    CustomKeyButton *button = [[CustomKeyButton alloc] initWithTitle:nil image:image backroundImage:nil pressedBackroundImage:nil size:size];
    
    if (button)
    {
        button.delegate = delegate;
        button.buttonAction = action;
        button.keys = keys;
        button.tag = tag;
        [button setTintColor:[UIColor colorWithRed:.23 green:.23 blue:.23 alpha:1]];
    }
    return button;
}

+ (CustomKeyButton*)createWithTitle:(NSString*)title size:(CGSize)size delegate:(id<NSObject>)delegate action:(SEL)action keys:(int)keys tag:(int)tag
{
    CustomKeyButton *button = [[CustomKeyButton alloc] initWithTitle:title image:nil backroundImage:nil pressedBackroundImage:nil size:size];
    if (button)
    {
        button.delegate = delegate;
        button.buttonAction = action;
        button.keys = keys;
        button.tag = tag;
    }
    return button;
}

- (void)buttonTap:(UIButton*)sender
{
 if ([self.delegate respondsToSelector:self.buttonAction])
        [InvokeSelector invokeSelector:self.buttonAction onTarget:self.delegate withArgument:self , nil];
}

- (void)setSelected:(BOOL)selected
{
    ((UIButton*)self.customView).selected = selected;
}

- (BOOL)selected
{
    return ((UIButton*)self.customView).selected;
}

@end
