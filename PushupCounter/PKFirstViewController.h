//
//  PKFirstViewController.h
//  PushupCounter
//
//  Created by Aaron Parecki on 10/13/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKAuthViewController.h"

@interface PKFirstViewController : UIViewController

@property (strong, nonatomic) PKAuthViewController *authViewController;
- (void)launchAuthView;

@property (strong, nonatomic) IBOutlet UIButton *countUpButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;

- (IBAction)countUpButtonTapped:(id)sender;
- (IBAction)resetButtonTapped:(id)sender;
- (IBAction)saveButtonWasTapped:(id)sender;

@end
