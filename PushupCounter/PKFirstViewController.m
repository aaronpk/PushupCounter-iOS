//
//  PKFirstViewController.m
//  PushupCounter
//
//  Created by Aaron Parecki on 10/13/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import "PKFirstViewController.h"
#import "PKFlipsideViewController.h"
#import "PKDataManager.h"

@interface PKFirstViewController ()
@property (strong, nonatomic) NSString *lastEntryKey;
@end

@implementation PKFirstViewController {
    int count;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    count = 0;
    [self updateButtonValue];
    [[PKDataManager sharedManager] requestLocation];
    self.authViewController = [[PKAuthViewController alloc] initWithNibName:@"PKAuthViewController" bundle:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    if([[NSUserDefaults standardUserDefaults] stringForKey:PKAPIAccessTokenDefaultsName]) {
        // Already logged in
    } else {
        [self launchAuthView];
    }
}

- (void)launchAuthView
{
    // Launch the auth view if it's not already present
    // Note that self.presentedViewController is normally actually the Flipside controller
    if(!self.presentedViewController) {
        [self presentViewController:self.authViewController animated:YES completion:nil];
    }
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(PKFlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark -

- (void)updateButtonValue
{
    [self.countUpButton setTitle:[NSString stringWithFormat:@"%d", count] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)countUpButtonTapped:(id)sender
{
    if(count == 0) {
        [[PKDataManager sharedManager] requestLocation];
        NSLog(@"Requesting location");
    }

    count++;
    [self updateButtonValue];
}

- (IBAction)resetButtonTapped:(id)sender
{
    count = 0;
    [self updateButtonValue];
}

- (IBAction)saveButtonWasTapped:(id)sender
{
    if(count == 0) {
        return;
    }

    NSString *userLocation = nil;
    CLLocation *loc;
    if((loc=[PKDataManager sharedManager].lastLocation)) {
        userLocation = [NSString stringWithFormat:@"geo:%f,%f;u=%d;a=%d;s=%d;d=%@", loc.coordinate.latitude, loc.coordinate.longitude, (int)round(loc.horizontalAccuracy), (int)round(loc.altitude), (int)round(loc.speed), [[PKDataManager iso8601DateFormatter] stringFromDate:loc.timestamp]];
    }

    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:@{
                            @"h": @"entry",
                            @"published": [[PKDataManager iso8601DateFormatter] stringFromDate:NSDate.new],
                            @"category": @"pushups",
                            @"count": [NSNumber numberWithInt:count],
                            @"name": [NSString stringWithFormat:@"Just did %d push-ups!", count],
                            @"timezone_abbr": tz.abbreviation,
                            @"timezone_name": tz.name,
                            }];
    if(userLocation) {
        [entry setObject:userLocation forKey:@"location"];
    }
    self.lastEntryKey = [NSString stringWithFormat:@"%ld", (long)[NSDate.date timeIntervalSince1970]];

    [[PKDataManager sharedManager] addEntryToQueue:entry withKey:self.lastEntryKey];
    [[PKDataManager sharedManager] scheduleSend];
    
    [self resetButtonTapped:nil];
}

@end
