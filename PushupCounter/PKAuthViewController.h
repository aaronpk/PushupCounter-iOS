//
//  PKAuthViewController.h
//  PushupCounter
//
//  Created by Aaron Parecki on 12/28/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PKAuthViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextView *errorTextView;
- (IBAction)signInButtonWasTapped:(id)sender;
- (void)processAuthRequestFromURL:(NSURL *)url;

@end
