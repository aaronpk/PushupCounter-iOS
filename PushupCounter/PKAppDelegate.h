//
//  PKAppDelegate.h
//  PushupCounter
//
//  Created by Aaron Parecki on 10/13/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKFirstViewController.h"

@interface PKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) PKFirstViewController *viewController;
@property (strong, nonatomic) UIWindow *window;

@end
