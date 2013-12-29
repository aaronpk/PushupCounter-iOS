//
//  PKFlipsideViewController.m
//  PushupCounter
//
//  Created by Aaron Parecki on 11/22/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import "PKFlipsideViewController.h"
#import "PKAuthViewController.h"
#import "PKDataManager.h"

@interface PKFlipsideViewController ()

@end

@implementation PKFlipsideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.apiEndpointField.text = [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIEndpointDefaultsName];
    self.saveLocationSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:PKSaveLocationDefaultsName];
    self.entriesInQueueLabel.text = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.sendingIndicator stopAnimating];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(sendingStarted)
												 name:PKSendingStartedNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(sendingFinished)
												 name:PKSendingFinishedNotification
											   object:nil];
    [self refreshQueueCount];
    [self refreshSignedInFields];
}

- (void)refreshQueueCount
{
    [[PKDataManager sharedManager] numberOfEntriesInQueue:^(long num) {
        self.entriesInQueueLabel.text = [NSString stringWithFormat:@"%ld unsent entries", num];
    }];
}

- (void)refreshSignedInFields
{
    self.usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIMeDefaultsName];
    self.apiEndpointField.text = [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIEndpointDefaultsName];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveLocationSwitchChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:self.saveLocationSwitch.isOn forKey:PKSaveLocationDefaultsName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"State: %d", self.saveLocationSwitch.isOn);
}

- (IBAction)apiEndpointHelpTapped:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://indiewebcamp.com/micropub"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)signInWasTapped:(id)sender
{
    PKAuthViewController *authView = [[PKAuthViewController alloc] init];
    [self presentViewController:authView animated:YES completion:^{
        [self refreshSignedInFields];
    }];
}

- (IBAction)sendNowWasTapped:(id)sender
{
    [[PKDataManager sharedManager] sendQueueNow];
}

- (void)sendingStarted {
    [self.sendingIndicator startAnimating];
    self.sendNowButton.enabled = NO;
}

- (void)sendingFinished {
    [self.sendingIndicator stopAnimating];
    self.sendNowButton.enabled = YES;
    [self refreshQueueCount];
}


#pragma mark - Flip

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end
