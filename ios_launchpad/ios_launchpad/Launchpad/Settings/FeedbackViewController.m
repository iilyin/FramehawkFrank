//
//  FeedbackViewController.m
//  Launchpad
//
//  View controller for handling User Feedback
//  NOTE: Not currently used
//
//  Created by Ellie Shin on 8/10/12.
//  Copyright (c) 2012 Framehawk, Inc. All rights reserved.
//

#import "FeedbackViewController.h"

@interface FeedbackViewController ()

@end

typedef enum FEEDBACK_SECTION {
    FEEDBACK_SECTION_TITLE,
    FEEDBACK_SECTION_DETAIL, 
    FEEDBACK_SECTION_BUTTONS,
    TOTAL_FEEDBACK_SECTIONS
}FEEDBACK_SECTION;

@implementation FeedbackViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"PLEASE GIVE US YOUR FEEDBACK"; 
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return TOTAL_FEEDBACK_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == FEEDBACK_SECTION_TITLE)
        return @"Feedback Title:"; 
    if (section == FEEDBACK_SECTION_DETAIL)
        return @"Details:"; 
    
    return @"";
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == FEEDBACK_SECTION_TITLE)
        return 44; 
    if(indexPath.section == FEEDBACK_SECTION_DETAIL)
        return 120; 
    return 50;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if(indexPath.section == FEEDBACK_SECTION_BUTTONS){
        // add cancel and submit button 
        UIButton* cancel = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
        [cancel sizeToFit];
        CGRect fr = cell.contentView.bounds; 
        fr.size.width /= 2;
        fr.size.width -= 10;
        cancel.frame = fr; 
        
        UIButton* submit = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        [submit setTitle:@"Submit" forState:UIControlStateNormal];
        [submit addTarget:self action:@selector(submitClicked) forControlEvents:UIControlEventTouchUpInside];
        [submit sizeToFit];
        fr.origin.x += fr.size.width + 20; 
        submit.frame = fr;     
        
        [cell.contentView addSubview:cancel];
        [cell.contentView addSubview:submit];
    }
    else {
        
        // TOOD: change to textview so word wrapping is allowed 

        UITextField* t = [[UITextField alloc] initWithFrame:cell.contentView.bounds];
        t.placeholder = @"Enter here";
        t.delegate = self;
        t.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
//        cell.contentView.backgroundColor = [UIColor yellowColor];
//        cell.backgroundColor = [UIColor redColor];
//        t.backgroundColor = [UIColor greenColor];
        [cell.contentView addSubview:t];
    }
    
    
    return cell;
}

- (void) cancelClicked {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) submitClicked {
    
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    DLog(@"fdsfsdfs");
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
