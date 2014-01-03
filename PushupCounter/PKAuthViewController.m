//
//  PKAuthViewController.m
//  PushupCounter
//
//  Created by Aaron Parecki on 12/28/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import "PKAuthViewController.h"
#import "PKURLHelpers.h"
#import "PKDataManager.h"

@interface PKAuthViewController ()

@end

@implementation PKAuthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processAuthRequestFromURL:) name:@"auth" object:nil];
    }
    return self;
}

- (IBAction)signInButtonWasTapped:(id)sender
{
    
    NSString *authURL = [NSString stringWithFormat:@"http://client.indieauth.com/auth/start?me=%@&client_id=%@&redirect_uri=%@",
                         self.usernameField.text, @"http://marvelouslabs.com/pushup-counter", @"pushups://auth"];
    NSURL *url = [NSURL URLWithString:authURL];
    
    // Launch the native browser to the auth URL, which will redirect back to this app when auth is complete
    [[UIApplication sharedApplication] openURL:url];
}

- (void)processAuthRequestFromURL:(NSNotification *)notification
{
    NSURL *url = notification.object;
    NSLog(@"Launched with URL: %@", url);
    
    if([[url host] isEqualToString:@"auth"]) {
        NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *params = [NSDictionary dictionaryWithFormEncodedString:query];
        NSLog(@"%@", params);
        
        if([params objectForKey:@"error"]) {
            // There was an error!
            self.errorTextView.text = [NSString stringWithFormat:@"Error!\n\n%@\n\n%@", [params objectForKey:@"error"], [params objectForKey:@"error_description"]];
            self.errorTextView.hidden = NO;
            
        } else if([params objectForKey:@"access_token"]
                  && [params objectForKey:@"me"]
                  && [params objectForKey:@"micropub_endpoint"]
                  && [params objectForKey:@"scope"]) {
            
            // Got everything we need, store in NSUserDefaults and they are logged in!
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[params objectForKey:@"micropub_endpoint"] forKey:PKAPIEndpointDefaultsName];
            [defaults setObject:[params objectForKey:@"me"] forKey:PKAPIMeDefaultsName];
            [defaults setObject:[params objectForKey:@"access_token"] forKey:PKAPIAccessTokenDefaultsName];
            [defaults synchronize];
            
            [[PKDataManager sharedManager] setupHTTPClient];
            self.errorTextView.text = @"";
            self.errorTextView.hidden = YES;
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
        } else {
            // Some parameters were missing
            NSLog(@"Launched with incomplete auth URL");

            self.errorTextView.text = [NSString stringWithFormat:@"Error, launched with incomplete auth URL!\n\nAuth URL: %@", url];
            self.errorTextView.hidden = NO;

        }
    } else {
        self.errorTextView.text = [NSString stringWithFormat:@"Error, launched with incomplete auth URL!\n\nAuth URL: %@", url];
        self.errorTextView.hidden = NO;
    }
}

@end
