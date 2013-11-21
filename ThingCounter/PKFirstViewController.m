//
//  PKFirstViewController.m
//  ThingCounter
//
//  Created by Aaron Parecki on 10/13/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import "PKFirstViewController.h"
#import "AFHTTPSessionManager.h"

@interface PKFirstViewController ()
@end

@implementation PKFirstViewController {
    AFHTTPSessionManager *manager;
    int count;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    count = 0;
    [self.spinner stopAnimating];
    [self updateButtonValue];
}

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
    count++;
    [self updateButtonValue];
}

- (IBAction)countDownButtonTapped:(id)sender
{
    
}

- (IBAction)resetButtonTapped:(id)sender
{
    count = 0;
    [self updateButtonValue];
}

- (IBAction)saveButtonWasTapped:(id)sender
{
    NSDictionary *parameters = @{
        @"category": @"pushups",
        @"count": [NSNumber numberWithInt:count],
        @"name": [NSString stringWithFormat:@"Just did %d push-ups!", count]
    };
    NSLog(@"Making post request");
    [self.spinner startAnimating];
    
    if(manager == nil) {
        manager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }

    [manager POST:@"/micropub/pushups.php"
                 parameters:parameters
          success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
              [self.spinner stopAnimating];
              count = 0;
              [self updateButtonValue];
              NSLog(@"JSON: %@", responseObject);
          }
          failure:^(NSURLSessionTask *task, NSError *error) {
              [self.spinner stopAnimating];
              NSLog(@"Error: %@", error);
          }];
    }


@end
