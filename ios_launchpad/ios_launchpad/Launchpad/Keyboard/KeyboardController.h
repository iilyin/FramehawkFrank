//
//  KeyboardController.h
//  Launchpad
//
//  Keyboard contoller class handles general keyboard input
//
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FunctionKeysController.h"

enum keyBoardType 
{ 
    kUnknownKeyboard,
    kAlphabeticKeyboard, 
    kNumericKeyboard, 
    kSymbolsKeyboard, 
    kAlphabeticFunKeyboard, 
    kAlphabeticXKeyboard,
    kAlphabeticXTabKeyboard,
    kAlphabeticXExtendedDesktopKeyboard
};

typedef NSUInteger KeyboardType;

/*
 X buttons tag defines
 */
enum xKeyTag
{
    kXNone = -1,
    kXEsc = 0,
    kXTab = 1,
    kXCtrl = 2,
    kXAlt = 3,
    kXCommand = 4,
    kXCtrlAltDel = 5,
    kXDel = 6,
    kXLeft = 7,
    kXUp = 8,
    kXDown = 9,
    kXRight = 10,
    kXForward = 11,
    kXBackward = 12,
    kXInsert = 13,
    kXHome = 14,
    kXEnd = 15,
    kXPageUp = 16,
    kXPageDown = 17,
    kXFKeys = 18,
    kXShowEasyLogin = 19,
    kXToggleFnKeys = 20,
    kxShiftTab = 21,
    kxMinimizeKeyBoard = 22
};
typedef NSInteger XKeyTag;

@interface CustomButtonInfo : NSObject
{
    
}
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *image;
@property (nonatomic, copy) NSString *backgroundImage;
@property (nonatomic) UIEdgeInsets backgroundInsets;
@property (nonatomic, copy) NSString *pressedBackgroundImage;
@property (nonatomic) UIEdgeInsets pressedBackgroundInsets;
@property (nonatomic) CGFloat width;
@property (nonatomic) XKeyTag tag;

+ (id)customButtonInfoWithTitle:(NSString*)title width:(CGFloat)width tag:(XKeyTag)tag;
+ (id)customButtonInfoWithImage:(NSString*)image width:(CGFloat)width tag:(XKeyTag)tag;
+ (id)customButtonInfoWithTitle:(NSString*)title image:(NSString*)image backgroundImage:(NSString*)backgroundImage backgroundInsets:(UIEdgeInsets)backInsets pressedBackgroundImage:(NSString*)pressedBackgroundImage  pressedInsets:(UIEdgeInsets)pressedInsets width:(CGFloat)width tag:(XKeyTag)tag;

- (UIImage*)backImage;
- (UIImage*)pressedBackImage;

@end


@class CustomButton;

/*
 * Class which implements keyboard control/handle functional
 */

@interface KeyboardController : UIViewController<UIKeyInput, FunctionKeyDelegate,UIPopoverControllerDelegate>{
    BOOL showKeyboard;
    KeyboardType currentKeyBoardType;
    UIView *currentKeyboardAccessoryView;
    CustomButton *functionButton;
    CustomButton *xButton;
    UIView *buttonView;
    UIView *functionToolbar;
    int keyboardFlags;
    BOOL altPressed;
    BOOL ctrlPressed;
    BOOL insPressed;
    BOOL enableFnKeysPressed;
}

@property(nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property(atomic) UIPopoverController *fnKeysToolbar;
@property(atomic) FunctionKeysController* fnKeyToolbarController;

- (void)setCurrentKeyboardType:(KeyboardType)type;
- (void)togglekeyboard;
- (void) showKeyboard;
- (void) hideKeyboard;

#pragma mark keyboard handling
- (void) insertText:(NSString* )text;
- (void)deleteBackward;
- (BOOL)hasText;

- (UIView*)inputAccessoryView;

/*
 Called when aplication became foreground
 */
- (void)checkKeyboardButtons;

- (int)keyboardFlags;

/*
 * Keyboard event handling
 */
- (void)insertText:(NSString* )text;
- (void)deleteBackward;


/*
 * custom key buttons appearance controlling methods, override in descendant class if needed
 */
- (void)tuneFnKeyButton:(CustomButton*)button;
- (void)tuneXxKeyButton:(CustomButton*)button;


#pragma mark - Optional methods
/*
 * Optional methos to get titles, tags and widhts for the X keyboard accessory buttons 
 */

/*
 Returns array of CustomButtonInfo* objects with xAccessory buttons descriotions for XKeyboardType.
 Override in descendant class to create own X custom accessory 
 */
- (NSArray*)xAccessoryButtonsInfoForKeyBoardType:(KeyboardType) typeForXKeyBoard;

/*
 * Returns array of button titles for X accessory
 * If button title ends with ".png", routine tries to load image with that name and use it as button image 
 * Special titles:
 *  "fixed" - defines fixed space of width of 10 points;
 *  "flexible" - defines flexible space.
 * Override this method in descendant class to provide custom buttons for the X accessory
 */

/*
 * Returns array of buttons tags for X keyboard accessory buttons.
 * Each item is NSNumber* object with integer value of button tag (see xKeyTag enum).
 * Lenght of returned array must be equal to lenght of array returnded by xAccessoryButtonTitles minus 
 * number of fixed and flexible spaces.
 * Each item of array must correspond to item of array returned by xAccessoryButtonTitles
 * method, with ecxept of fixed and flexible items.
 * Override this method in descendant class to provide custom tags for buttons of the X accessory
 */

/*
 * Returns dictionary, where keys are titles of the X accessory buttons, except for fixed and flexible spaces,
 * and values are NSNumber* objects with integer values of widths of the corresponding buttons.
 * Lenght of returned dictionary must be equal to lenght of array returnded by xAccessoryButtonTitles minus 
 * number of fixed and flexible spaces.
 * Override this method in descendant class to provide custom widths for buttons of the X accessory
 */

- (void)keyboardVisibleChanged:(BOOL)visible;

/*
 *Reset all mode flags and buttons selected state to NO for Extended keyboard accessory view
 */
- (void) resetXKeyboardModeButtonsSelected;


@end
