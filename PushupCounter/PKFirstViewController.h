//
//  PKFirstViewController.h
//  PushupCounter
//
//  Created by Aaron Parecki on 10/13/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PKFirstViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *countUpButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

- (IBAction)countUpButtonTapped:(id)sender;
- (IBAction)resetButtonTapped:(id)sender;
- (IBAction)saveButtonWasTapped:(id)sender;

@end
