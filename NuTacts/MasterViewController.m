//
//  MasterViewController.m
//  NuTContactList
//
//  Created by Nutech Systems on 11/19/14.
//  Copyright (c) 2014 NuTech. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "sharedContactsTableViewController.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "defines.h"

@interface MasterViewController ()

@property (nonatomic, strong) NSMutableDictionary *Alphabet;
@property (nonatomic, strong) NSString *lastUsedEmailAddress;
@property (nonatomic, strong) NSCharacterSet *nonCapitals;
@property (nonatomic, strong) UIActivityIndicatorView *refreshActivity;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _nonCapitals = [[NSCharacterSet letterCharacterSet] invertedSet];
    _Alphabet = [[NSMutableDictionary alloc] init];


    //Background Texture
    CALayer *backGroundGradient = [self gradientBGLayerForBounds: self.tableView.layer.bounds];
    CGRect dimensions = self.tableView.frame;
    
    UIView *tempView = [[UIImageView alloc] initWithFrame:dimensions];
    [tempView.layer addSublayer:backGroundGradient];
    self.tableView.backgroundView = tempView;

    //Pull-To-Refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(updatedContactList) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    self.tableView.backgroundView.layer.zPosition -= 1;
    
    //NavigationBar Button:
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    UIBarButtonItem *profileButton = [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStylePlain target:self action:@selector(changeProfile:)];
    
    self.navigationItem.rightBarButtonItems = @[addButton, profileButton];
    
    //Pull Contacts
    [self updatedContactList];
}

//Method used to create background gradient
- (CALayer *)gradientBGLayerForBounds:(CGRect)bounds
{
    CAGradientLayer * gradientBG = [CAGradientLayer layer];
    
    gradientBG.frame = bounds;
    
    gradientBG.colors = [NSArray arrayWithObjects:
                         (id)[[UIColor colorWithRed:42.0f / 255.0f green:92.0f / 255.0f blue:252.0f / 255.0f alpha:1.0f] CGColor],
                         (id)[[UIColor colorWithRed:11.0f / 255.0f green:51.0f / 255.0f blue:101.0f / 255.0f alpha:1.0f] CGColor],
                         nil];
    
    return gradientBG;
}

//Pulls every contact from parse
-(void)updatedContactList
{
    for (int i=0; i<alphabetArray.count; i++) {
        [self loadSection:i];
    }
    [self.refreshControl endRefreshing];
}

//Updates CurrentUser object on parse.
//displays currentUser values, and also allows one to check on new contacts.
-(void)changeProfile:(id)sender{
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        PFQuery *query = [PFQuery queryWithClassName:@"SharedContact"];
        NSString *email = [[PFUser currentUser].email uppercaseString];
        [query whereKey:@"emailRecipient" equalTo:email];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            NSString *message = [NSString stringWithFormat:@"Username: %@\nE-Mail: %@", [PFUser currentUser].username, [PFUser currentUser].email];
            //display profile AlertController
            UIAlertController *profile = [UIAlertController alertControllerWithTitle:@"Profile" message:message preferredStyle:UIAlertControllerStyleAlert];
            
            //save changes to profile
            UIAlertAction *changePassword = [UIAlertAction actionWithTitle:@"Change Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
            }];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            
            //logout of app and facebook
            UIAlertAction *logOut = [UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [PFUser logOut];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
            
            //if there are shared contacts, display the button and display a message.
            if (number) {
                UIAlertAction *addContacts = [UIAlertAction actionWithTitle:@"Check Shared Contacts" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    NSLog(@"Check Shared Contacts clicked.");
                    [self performSegueWithIdentifier:@"displaySharedContacts" sender:nil];
                }];
                profile.message = [profile.message stringByAppendingString:@"\nYou have contacts awaiting approval."];
                [profile addAction:addContacts];
            }
            
            [profile addAction:cancel];
            [profile addAction:changePassword];
            [profile addAction:logOut];

            [self presentViewController:profile animated:YES completion:nil];
        }];
    }];
}

////detect when section is changed.
//-(void)editContact:(PFObject *)contact inSection:(NSInteger)section toSection:(NSInteger)newSection{
//    if (section != newSection) {
//        [self loadSection:section];
//    }
//    [self newContact:contact fromSection:-1];
//}

//Creates newContact, and also saves modifications to existing contacts. Section is used to refresh the section being updated.
-(void)newContact:(PFObject *)contact fromSection:(NSInteger)oldSection {
    [contact saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSString *canonName = contact[@"canonName"];
            NSString *firstLetter = [canonName substringToIndex:1];
            for (int i=0; i<alphabetArray.count; i++) {
                if ([firstLetter isEqualToString:alphabetArray[i]]) {
                    [self loadSection:i];
                    if (i!=oldSection&&oldSection!=-1) {
                        [self loadSection:oldSection];
                    }
                }
            }
        } else {
            NSLog(@"%@", error);
        }
    }];
}

//queries for a specific section and refreshes just that section.
-(void)loadSection:(NSInteger)section
{
    PFQuery *query = [PFQuery queryWithClassName:@"Contact"];
    NSString *sectionName = alphabetArray[section];
    [query whereKey:@"canonName" hasPrefix:sectionName];
    [query whereKey:@"userID" equalTo:[PFUser currentUser].objectId];

    [query orderByAscending:@"canonName"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        _Alphabet[alphabetArray[section]]=[objects mutableCopy];
        NSRange range = NSMakeRange(section, 1);
        NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.tableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationMiddle];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    PFObject *contact = [PFObject objectWithClassName:@"Contact"];
    [self editContact:(PFObject *)contact];
}

-(void)editContact:(PFObject *)contact {
    [self editContact:contact shareable:NO];
}

//Displays Edit Contact AlertController
-(void)editContact:(PFObject *)contact shareable:(BOOL)sharing{
    NSString *oldCanonName = contact[@"canonName"];

    UIAlertController *newContact = [UIAlertController alertControllerWithTitle:@"Contact" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSArray *textFields = newContact.textFields;
        int i = 0;
        for (UITextField *tf in textFields) {
            contact[columnNames[i]] = tf.text;
            i++;
        }
        NSString *newCanonName = [self createCanonNameFromFirst:contact[@"firstName"] andLastName:contact[@"lastName"]];
        contact[@"canonName"] = newCanonName;
        contact[@"userID"] = [PFUser currentUser].objectId;
        NSString *firstLetterOld = [oldCanonName substringToIndex:1];
        NSString *firstLetterNew = [newCanonName substringToIndex:1];
        
        if(sharing && ![firstLetterNew isEqualToString:firstLetterOld]){
            for (int i=0; i<alphabetArray.count; i++) {
                if ([firstLetterOld isEqualToString:alphabetArray[i]]) {
                    [self newContact:contact fromSection:i];
                }
            }
        } else {
            [self newContact:contact fromSection:-1];
        }
    }];
    UIAlertAction *share = [UIAlertAction actionWithTitle:@"Share Contact" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        PFObject *sharedContact = [PFObject objectWithClassName:@"SharedContact"];
        NSArray *textFields = newContact.textFields;
        int i = 0;
        for (UITextField *tf in textFields) {
            sharedContact[columnNames[i]] = tf.text;
            contact[columnNames[i]] = tf.text;
            i++;
        }
        sharedContact[@"canonName"] = [self createCanonNameFromFirst:sharedContact[@"firstName"] andLastName:sharedContact[@"lastName"]];
        contact[@"canonName"] = [self createCanonNameFromFirst:sharedContact[@"firstName"] andLastName:sharedContact[@"lastName"]];
        UIAlertController *share = [UIAlertController alertControllerWithTitle:nil message:@"Who do you wish to share the contact with?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *shareCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *shareAccept = [UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *tf = share.textFields[0];
            sharedContact[@"emailRecipient"] = [tf.text uppercaseString];
            [contact saveInBackground];
            [sharedContact saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    _lastUsedEmailAddress = tf.text;
                }
            }];
        }];
        [share addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = _lastUsedEmailAddress;
            textField.placeholder = @"Recipient's Email";
            textField.keyboardType = UIKeyboardTypeEmailAddress;
        }];
        [share addAction:shareCancel];
        [share addAction:shareAccept];
        [self presentViewController:share animated:YES completion:nil];
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
    if (sharing) {
        [newContact addAction:share];
    }
    [self presentViewController:newContact animated:YES completion:nil];
}


//creates Canon Name for use in sorting by trimming nonletter characters and capitalizing any letters.
//saves on bandwidth and processing time when retrieving contacts.
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"displaySharedContacts"]) {
        sharedContactsTableViewController *vc = [segue destinationViewController];
        vc.delegate = self;
    }
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

    NSString *phone =contact[@"phoneNumber"];
    if (phone.length >0) {
        UIImage *image = [UIImage imageNamed:@"phoneIcon.png"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        button.frame = frame;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        
        [button addTarget:self action:@selector(checkButtonTapped:event:)  forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
        cell.accessoryView = button;
    } else{
        cell.accessoryView = nil;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@",contact[@"lastName"], contact[@"firstName"]];
    cell.detailTextLabel.text = contact[@"phoneNumber"];
//    cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.9];
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView.backgroundColor = [UIColor clearColor];
//    cell.bac
    return cell;
}

-(void)checkButtonTapped:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    
    if (indexPath != nil)
    {
        PFObject *contact = _Alphabet[alphabetArray[indexPath.section]][indexPath.row];
        NSString *urlString = [NSString stringWithFormat:@"tel:%@", contact[@"phoneNumber"]];
        NSURL *phoneURL = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:phoneURL];
    }
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
    [self editContact:contact shareable:YES];
}

@end
