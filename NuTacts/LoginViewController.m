//
//  LoginViewController.m
//  NuTContactList
//
//  Created by Nutech Systems on 11/19/14.
//  Copyright (c) 2014 NuTech. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse.h>
#import <QuartzCore/QuartzCore.h>



@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //NavigationBar alterations
    [self.navigationController.navigationBar setTintColor:[UIColor lightTextColor]];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"gradient.png" ] forBarMetrics:UIBarMetricsDefault];
    NSShadow *shadow = [NSShadow new];
    [shadow setShadowColor: [UIColor blackColor]];
    [shadow setShadowOffset: CGSizeMake(2.0f, 2.0f)];
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor lightTextColor],NSForegroundColorAttributeName,
                                               shadow, NSShadowAttributeName, nil];
    self.navigationController.navigationBar.TitleTextAttributes = navbarTitleTextAttributes;

    [_passwordField setSecureTextEntry:YES];
    UIImage *background = [UIImage imageNamed:@"darkWall.jpg"];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:background];
    [self.view insertSubview:backgroundView atIndex:0];
    [_createButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
    CGRect createFrame = _createButton.frame;
    [_loginButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
    CGRect loginFrame = _loginButton.frame;
    UIImage *createBackground = [self imageWithImage:[UIImage imageNamed:@"gradient.png"] scaledToSize:createFrame.size];
    UIImage *loginBackground = [self imageWithImage:[UIImage imageNamed:@"gradient.png"] scaledToSize:loginFrame.size];
    
    [_createButton setBackgroundImage:createBackground forState:UIControlStateNormal];
    _createButton.layer.cornerRadius = 10;
    _createButton.clipsToBounds = YES;
    [_loginButton setBackgroundImage:loginBackground forState:UIControlStateNormal];
    _loginButton.layer.cornerRadius = 10;
    _loginButton.clipsToBounds = YES;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (IBAction)loginPressed:(id)sender {
    if (_userNameField.text.length == 0 || _passwordField.text.length == 0) {
        UIAlertController *failure = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"Please Input all Fields" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [failure addAction:ok];
        [self presentViewController:failure animated:YES completion:nil];
    } else {
        [PFUser logInWithUsernameInBackground:_userNameField.text password:_passwordField.text block:^(PFUser *user, NSError *error) {
            if (user) {
                if ([user[@"emailVerified"] boolValue]) {
                    [self performSegueWithIdentifier:@"loadContactList" sender:self];
                } else {
                    [PFUser logOut];
                    UIAlertController *failure = [UIAlertController alertControllerWithTitle:@"ERROR" message:[NSString stringWithFormat:@"Verify your Email"] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [failure addAction:ok];
                    [self presentViewController:failure animated:YES completion:nil];
                }
            } else {
                UIAlertController *failure = [UIAlertController alertControllerWithTitle:@"ERROR" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [failure addAction:ok];
                [self presentViewController:failure animated:YES completion:nil];
            }
        }];
    }
}

- (IBAction)createPressed:(id)sender {
    UIAlertController *createAccount = [UIAlertController alertControllerWithTitle:@"Create New Account" message:@"Complete All Fields" preferredStyle:UIAlertControllerStyleAlert];
    [createAccount addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"User Name";
    }];
    [createAccount addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Email";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    [createAccount addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password";
        [textField setSecureTextEntry:YES];
    }];
    UIAlertAction *create = [UIAlertAction actionWithTitle:@"Create Account" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        BOOL completed = YES;
        NSArray *textFields = createAccount.textFields;
        for (UITextField *field in textFields) {
            if (field.text.length==0) {
                completed = NO;
            }
        }
        if(!completed){
            [self createPressed:nil];
        } else {
            PFUser *user = [PFUser user];
            UITextField *textField = textFields[0];
            NSString *userName = textField.text;
            textField = textFields[1];
            NSString *eMail = textField.text;
            textField = textFields[2];
            NSString *password = textField.text;
            user.username = userName;
            user.email = eMail;
            user.password = password;
            [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    UIAlertController *failure = [UIAlertController alertControllerWithTitle:@"ERROR" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [failure addAction:ok];
                    [self presentViewController:failure animated:YES completion:nil];
                }
            }];
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [createAccount addAction:create];
    [createAccount addAction:cancel];
    [self presentViewController:createAccount animated:YES completion:nil];
}


-(void)viewDidAppear:(BOOL)animated
{
//    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
    if ([PFUser currentUser]){
        [self performSegueWithIdentifier:@"loadContactList" sender:self];
    }
}

//- (IBAction)pushFacebookLogin:(id)sender {
//    NSArray *permissionsArray = @[@""];
//    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
//        if (!user){
//            if (!error){
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"The Facebook Login was Canceled" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//                [alertView show];
//            } else {
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//                [alertView show];
//            }
//        }
//        else
//        {
//            if ([user[@"setAlias"]boolValue]) {
//                NSLog(@"Needs a userName");
//            }
//            [self performSegueWithIdentifier:@"loadContactList" sender:self];
//        }
//    }];
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
