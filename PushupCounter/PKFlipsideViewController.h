//
//  PKFlipsideViewController.h
//  PushupCounter
//
//  Created by Aaron Parecki on 11/22/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PKFlipsideViewController;

@protocol PKFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(PKFlipsideViewController *)controller;
@end

@interface PKFlipsideViewController : UIViewController

@property (weak, nonatomic) id <PKFlipsideViewControllerDelegate> delegate;
- (IBAction)done:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField *usernameField;
- (IBAction)signInWasTapped:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField *apiEndpointField;
- (IBAction)apiEndpointHelpTapped:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *entriesInQueueLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *sendingIndicator;
@property (strong, nonatomic) IBOutlet UIButton *sendNowButton;
- (IBAction)sendNowWasTapped:(id)sender;

@property (strong, nonatomic) IBOutlet UISwitch *saveLocationSwitch;
- (IBAction)saveLocationSwitchChanged:(id)sender;

@end

