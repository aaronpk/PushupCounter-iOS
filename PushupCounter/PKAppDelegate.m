//
//  PKAppDelegate.m
//  PushupCounter
//
//  Created by Aaron Parecki on 10/13/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import "PKAppDelegate.h"
#import "PKURLHelpers.h"
#import "PKDataManager.h"

@implementation PKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// App launched by clicking a URL
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if([[url host] isEqualToString:@"auth"]) {
        NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"Launched with URL: %@", query);
        NSDictionary *params = [NSDictionary dictionaryWithFormEncodedString:query];
        NSLog(@"%@", params);
        
        if([params objectForKey:@"error"]) {
            // There was an error!
            
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
            
        } else {
            // Some parameters were missing
            
        }
    }
    
    return YES;
}

@end
