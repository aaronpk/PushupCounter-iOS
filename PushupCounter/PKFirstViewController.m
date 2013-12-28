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
    [self.spinner stopAnimating];
    [self updateButtonValue];
    [[PKDataManager sharedManager] requestLocation];
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
    if(count == 0)
        [[PKDataManager sharedManager] requestLocation];

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

    NSString *userLocation = nil;
    CLLocation *loc;
    if((loc=[PKDataManager sharedManager].lastLocation)) {
        userLocation = [NSString stringWithFormat:@"geo:%f,%f;u=%d;a=%d;s=%d;ts=%d", loc.coordinate.latitude, loc.coordinate.longitude, (int)round(loc.horizontalAccuracy), (int)round(loc.altitude), (int)round(loc.speed), (int)[loc.timestamp timeIntervalSince1970]];
    }

    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:@{
                            @"h": @"entry",
                            @"published": [NSNumber numberWithLong:(long)[NSDate.date timeIntervalSince1970]],
                            @"timezone": @{
                                    @"offset": [NSNumber numberWithInteger:tz.secondsFromGMT],
                                    @"abbr": tz.abbreviation,
                                    @"name": tz.name,
                                    },
                            @"category": @"pushups",
                            @"count": [NSNumber numberWithInt:count],
                            @"name": [NSString stringWithFormat:@"Just did %d push-ups!", count]
                            }];
    if(userLocation) {
        [entry setObject:userLocation forKey:@"location"];
    }
    self.lastEntryKey = [NSString stringWithFormat:@"%ld", (long)[NSDate.date timeIntervalSince1970]];

    [[PKDataManager sharedManager] addEntryToQueue:entry withKey:self.lastEntryKey];
    [[PKDataManager sharedManager] scheduleSend];
}

@end
