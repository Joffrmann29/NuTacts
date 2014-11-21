//
//  sharedContactsTableViewController.h
//  NuTContactList
//
//  Created by Nutech Systems on 11/19/14.
//  Copyright (c) 2014 NuTech. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "MasterViewController.h"

@protocol sharedContactsDelegate

-(void)updatedContactList;

@end

@interface sharedContactsTableViewController : UITableViewController

@property (nonatomic, strong) id<sharedContactsDelegate> delegate;


@end
