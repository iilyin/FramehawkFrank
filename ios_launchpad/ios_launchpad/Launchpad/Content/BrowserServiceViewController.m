//
//  BrowserServiceViewController.m
//  Framehawk
//
//  Browser view controler for Framehawk Session
//
//  Created by Hursh Prasad on 4/19/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#define SpinnerViewTag 111
#define ToolBarTag 4
#define DrawerButtonTag 5

#define BrowserMinFrame CGRectMake(0,59,1024,709)
#define BrowserMaxFrame CGRectMake(0,0,1024,768)

#import "BrowserServiceViewController.h"
#import "SpinnerController.h"
@interface BrowserServiceViewController ()
@property (weak,nonatomic) IBOutlet UIWebView *browser;
@property (weak,nonatomic) IBOutlet UIButton *forward;
@property (weak,nonatomic) IBOutlet UIButton *back;
@property (weak,nonatomic) IBOutlet UIButton *refresh;
@property (weak,nonatomic) IBOutlet UIButton *home;
@property (weak,nonatomic) IBOutlet UITextField *searchField;
@property (weak,nonatomic) NSString *homePage;
@end

@implementation BrowserServiceViewController
@synthesize browser, forward, back, refresh, home, homePage, command, searchField, search;
@synthesize submenu;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}
-(IBAction)maxMinBrowser:(id)sender{
    
    CGRect frame = [self.view viewWithTag:ToolBarTag].frame;
    CGRect drawerFrame = [self.view viewWithTag:DrawerButtonTag].frame;
    CGRect browserFrame;
    if (0 == [self.view viewWithTag:ToolBarTag].frame.origin.y) {
        frame.origin.y -= 61;
        drawerFrame.origin.y -= 61;
        browserFrame = BrowserMaxFrame;
    }else if (-61 == [self.view viewWithTag:ToolBarTag].frame.origin.y) {
        frame.origin.y += 61;
        drawerFrame.origin.y += 61;
        browserFrame = BrowserMinFrame;
    }
        [UIView animateWithDuration:0.6
     
                    animations:^{ 
                         [self.view viewWithTag:ToolBarTag].frame = frame;
                         [self.view viewWithTag:DrawerButtonTag].frame = drawerFrame;
                         browser.frame = browserFrame;
                     }
     
                     completion:^(BOOL  completed){
                         //DLog(@"Closed Menu");
                     }
         ];
}
-(IBAction)refresh:(id)sender{
    [browser reload];
}
-(IBAction)goToHomePage:(id)sender{
    self.searchField.text = self.homePage;
    [self.browser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.homePage]]];
    [self webViewDidFinishLoad:browser];
}
-(IBAction)goBackward:(id)sender{
    if (browser.canGoBack) {
        [browser goBack];
    }
}
-(void)addSubmenu:(UIViewController *)submenucontroller{
    self.submenu = submenucontroller;
    [self.view addSubview:submenucontroller.view];
}
-(IBAction)goForward:(id)sender{
    if (browser.canGoForward) {
        [browser goForward];
    }
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
 
    if ([self.view viewWithTag:SpinnerViewTag])
        [[self.view viewWithTag:SpinnerViewTag] removeFromSuperview];
    
    (webView.canGoBack)?[back setHighlighted:YES] :[back setHighlighted:NO];
    (webView.canGoForward)?[forward setHighlighted:YES] :[forward setHighlighted:NO];
    
    self.searchField.text = [[[webView request] URL] absoluteString];
    
    if (self.search != nil) {
        self.search = nil;
    }
        
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
   /* UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Browser Error!"
                                                      message:@"Failed To Load Web Page."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    [message show];
    */
    
    if (self.search != nil) {
        self.search = nil;
    }
}
-(void)browseToURL:(NSString *)url forCommand:(NSString *)objCommand{
    if (url == NULL)
        DLog(@"Cannot navigate to a null URL.");
    
    self.command = [[NSString alloc] initWithString:objCommand];
    self.homePage = [[NSString alloc] initWithString:url];
}
-(void)browseToURL{
    if (self.homePage == NULL)
        DLog(@"Cannot navigate to a null URL.");

    if(self.search)
    {
        [self.browser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?q=%@",self.homePage,self.search]]]];
    }
    else 
    {
        [self.browser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.homePage]]];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self.searchField.text length]==0) {
        self.searchField.text = self.homePage;
        
        NSString *url;
        if ([self.search length]>0) {
            url = [NSString stringWithFormat:@"%@?q=%@",self.homePage,self.search];
        }else {
            url = self.homePage;
        }
        
        self.search = nil;
        // set keyboard type to browser type include previous/next buttons
        [self setCurrentKeyboardType:kAlphabeticXTabKeyboard];

        [self.browser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        
        SpinnerController *spinner = [[SpinnerController alloc] initWithNibName:nil bundle:nil];
        [spinner setCommand:self.command];
        spinner.view.frame = browser.frame;
        spinner.view.tag = SpinnerViewTag;
        [self.view insertSubview:spinner.view atIndex:1];
        
    }
    
    
    //  Triple Tap Recognizer for keyboard
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(threeFingersTap:)];
    tripleTap.numberOfTapsRequired = 1;
    tripleTap.numberOfTouchesRequired = 3;
    [self.view addGestureRecognizer:tripleTap];

}
-(void)viewWillAppear:(BOOL)animated{
    
/*    dispatch_async(dispatch_get_main_queue(), ^{
        [self.connectionUtilityDelegate connectionReadyToStream];
    });
*/    
    
    if (self.search != nil) {
       NSString *url =  [NSString stringWithFormat:@"%@?q=%@",self.homePage,self.search];
       [self.browser loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]]; 
        self.search = nil;
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
 
}
-(void)dealloc{

    UIView *v;
    if ([self.view viewWithTag:SpinnerViewTag]) {
        v = [self.view viewWithTag:SpinnerViewTag];
        [[self.view viewWithTag:SpinnerViewTag] removeFromSuperview];
        v = nil;
    }
    
    if ([self.view viewWithTag:ToolBarTag]) {
        v = [self.view viewWithTag:ToolBarTag];
        [[self.view viewWithTag:ToolBarTag] removeFromSuperview];
        v = nil;
    }
    
    if ([self.view viewWithTag:DrawerButtonTag]) {
        v = [self.view viewWithTag:DrawerButtonTag];
        [[self.view viewWithTag:DrawerButtonTag] removeFromSuperview];
        v = nil;
    }
    
    if (self.homePage) {
        self.homePage = nil;
    }
    
    command = nil;
    browser = nil;
    forward = nil;
    back    = nil;
    home    = nil;
    homePage = nil;
    searchField = nil;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)threeFingersTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.numberOfTouches == 3)
    {
        if([self.searchField isFirstResponder]){
            [self.searchField resignFirstResponder];  
        }
        else {
            [self.searchField becomeFirstResponder];  
        }
    }
}



@end
