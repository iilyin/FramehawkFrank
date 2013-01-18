//
//  MagnifierView.h
//  Launchpad
//
//  Handles magnify display for mouse offset
//  TODO: Fix bug with multiple view (no zoom currently)
//
//  Copyright (c) 2012  Framehawk, Inc. All rights reserved.

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <QuartzCore/QuartzCore.h>

@class FHUIView;
@protocol MagnifierViewDelegate;

@interface MagnifierView : UIView
{
    CGPoint _sourceCenter;
    CGImageRef resultImgRef;
    UIImageView *magnifierView;
    BOOL capture;
    GLubyte *resdata;
    NSInteger dataLength;
    GLint framebufferID;
}

@property (nonatomic, strong) UIView* sourceView;
@property (nonatomic, strong) UIImageView* capturedImage;
@property (nonatomic, strong) UIImageView* cursorView;
@property (nonatomic, strong) NSDate *lastDate;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSLock *threadLock; 

@property (nonatomic) float scale;
@property (nonatomic, weak) id<MagnifierViewDelegate>delegate;

- (id)initWithFrame:(CGRect)frame magnifierImage:(UIImage*)image;
- (void)setMagnifierImage:(UIImage*)image;

- (void)stopCapturing;
- (void)changeLocation:(CGPoint)newPanLocation;
- (CGPoint)adjustedCenter;

@end

@protocol MagnifierViewDelegate
- (void)loupeView:(MagnifierView*)view hideAtPosition:(CGPoint)location click:(BOOL)click;
- (void)loupeView:(MagnifierView *)view rightHalfClick:(CGPoint)location;
- (void)loupeView:(MagnifierView *)view magnifierClick:(CGPoint)location;
@end

/*
    Workaround to synchronize threads working with OpenGL
 */
@interface EAGLContext(custom)
{
}

- (BOOL)presentRenderbufferOld:(NSUInteger)target;

@end
