//
//  sharedContactsTableViewController.m
//  NuTContactList
//
//  Created by Nutech Systems on 11/19/14.
//  Copyright (c) 2014 NuTech. All rights reserved.
//

#import "sharedContactsTableViewController.h"
#import "defines.h"
#import <Parse/Parse.h>

@interface sharedContactsTableViewController ()

@property (atomic, strong) NSMutableDictionary *Alphabet;
@property (nonatomic, strong) NSCharacterSet *nonCapitals;

@end

@implementation sharedContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _nonCapitals = [[NSCharacterSet letterCharacterSet] invertedSet];
    
    CALayer *backGroundGradient = [self gradientBGLayerForBounds: self.tableView.layer.bounds];
    UIView *tempView = [[UIImageView alloc] initWithFrame:self.tableView.layer.frame];
    [tempView.layer addSublayer:backGroundGradient];
    self.tableView.backgroundView = tempView;
    self.navigationItem.title = @"Shared Contacts";
    //Pull-To-Refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(updatedContactList) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    self.tableView.backgroundView.layer.zPosition -= 1;

    _Alphabet = [[NSMutableDictionary alloc] init];
    [self updatedContactList];
}


-(void)updatedContactList{
    for (int i=0; i<alphabetArray.count; i++) {
        [self loadSection:i];
    }
    [self.refreshControl endRefreshing];

}

- (CALayer *)gradientBGLayerForBounds:(CGRect)bounds

{
    CAGradientLayer * gradientBG = [CAGradientLayer layer];
    
    gradientBG.frame = bounds;
    
    gradientBG.colors = [NSArray arrayWithObjects:
                         
                         (id)[[UIColor colorWithRed:148.5f / 255.0f green:173.5f / 255.0f blue:253.5 / 255.0f alpha:1.0f] CGColor],
                         
                         (id)[[UIColor colorWithRed:11.0f / 255.0f green:51.0f / 255.0f blue:101.0f / 255.0f alpha:1.0f] CGColor],
                         
                         nil];
    
    return gradientBG;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadSection:(NSInteger)section
{
    //defining subqueries for lower and uppercase
    PFQuery *query = [PFQuery queryWithClassName:@"SharedContact"];
    NSString *sectionName = alphabetArray[section];
    [query whereKey:@"canonName" hasPrefix:sectionName];
    [query whereKey:@"emailRecipient" equalTo:[[PFUser currentUser].email uppercaseString]];
    
    [query orderByAscending:@"canonName"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _Alphabet[alphabetArray[section]]=[objects mutableCopy];
        NSRange range = NSMakeRange(section, 1);
        NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.tableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationMiddle];
    }];
}

-(void)newContact:(PFObject *)sharedContact inSection:(NSInteger)section{
    PFObject *contact = [PFObject objectWithClassName:@"Contact"];
    for (NSString *columnName in columnNames) {
        contact[columnName] = sharedContact[columnName];
    }
    contact[@"canonName"] = [self createCanonNameFromFirst:contact[@"firstName"] andLastName:contact[@"lastName"]];
    contact[@"userID"] = [PFUser currentUser].objectId;
    [sharedContact deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSString *canonName = contact[@"canonName"];
            NSString *firstLetter = [canonName substringToIndex:1];
            for (int i=0; i<alphabetArray.count; i++) {
                if ([firstLetter isEqualToString:alphabetArray[i]]) {
                    [self loadSection:i];
                }
            }
        } else {
            NSLog(@"%@", error);
        }
    }];
    [contact saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [_delegate updatedContactList];
        } else {
            NSLog(@"%@", error);
        }
    }];
}

-(void)editContact:(PFObject *)contact {
    UIAlertController *newContact = [UIAlertController alertControllerWithTitle:@"Contact" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textFields = newContact.textFields;
        int i = 0;
        for (UITextField *tf in textFields) {
            contact[columnNames[i]] = tf.text;
            i++;
        }
        [self newContact:contact inSection:i];
    }];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [contact deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            NSString *canonName = contact[@"canonName"];
            NSString *firstLetter = [canonName substringToIndex:1];
            for (int i=0; i<alphabetArray.count; i++) {
                if ([firstLetter isEqualToString:alphabetArray[i]]) {
                    [self loadSection:i];
                }
            }
        }];
    }];
    int i = 0;
    for (NSString *name in fieldNames) {
        NSString *content = contact[columnNames[i]];
        [newContact addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = name;
            textField.text = content;
            
            if ([name isEqualToString:@"Email"]) {
                textField.keyboardType =UIKeyboardTypeEmailAddress;
            } else if ([name isEqualToString:@"First Name"]||[name isEqualToString:@"Last Name"]||[name isEqualToString:@"City"]||[name isEqualToString:@"State"]){
                textField.keyboardType = UIKeyboardTypeAlphabet;
            } else if([name isEqualToString:@"Zip Code"]){
                textField.keyboardType = UIKeyboardTypeNumberPad;
            } else if ([name isEqualToString:@"Phone Number"]) {
                textField.keyboardType = UIKeyboardTypePhonePad;
            } else {
                textField.keyboardType = UIKeyboardTypeASCIICapable;
            }
        }];
        i++;
    }
    [newContact addAction:cancel];
    [newContact addAction:ok];
    [newContact addAction:delete];
    [self presentViewController:newContact animated:YES completion:nil];
}

-(NSString *)createCanonNameFromFirst:(NSString *)firstName andLastName:(NSString *)lastName{
    NSString *combinedString = [NSString stringWithFormat:@"%@%@",[lastName uppercaseString], [firstName uppercaseString]];
    NSString *canonNameString = combinedString;
    NSRange range = [combinedString rangeOfCharacterFromSet:_nonCapitals];
    
    while (range.location != NSNotFound) {
        canonNameString = [canonNameString stringByReplacingCharactersInRange:range withString:@""];
        range = [canonNameString rangeOfCharacterFromSet:_nonCapitals];
    }
    return canonNameString;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return alphabetArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *contacts = _Alphabet[alphabetArray[section]];
    return contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSArray *contacts = _Alphabet[alphabetArray[indexPath.section]];
    PFObject *contact = contacts[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@",contact[@"lastName"], contact[@"firstName"]];
//    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = contact[@"phoneNumber"];
//    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *contacts = _Alphabet[alphabetArray[indexPath.section]];
        PFObject *contact = contacts[indexPath.row];
        [contact deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                [contacts removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return alphabetArray[section];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.backgroundView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.1];
    v.textLabel.textColor = [UIColor lightTextColor];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *contact = _Alphabet[alphabetArray[indexPath.section]][indexPath.row];
    [self editContact:contact];
}

@end
