//
//  PKDataManager.h
//  ReactionTime
//
//  Created by Aaron Parecki on 11/22/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

static NSString *const PKAPIEndpointDefaultsName = @"PKAPIEndpointDefaults";
static NSString *const PKAPIAccessTokenDefaultsName = @"PKAPIAccessTokenDefaults";
static NSString *const PKAPIMeDefaultsName = @"PKAPIMeDefaults";

static NSString *const PKSaveLocationDefaultsName = @"PKSaveLocationDefaults";
static NSString *const PKSendingStartedNotification = @"PKSendingStartedNotification";
static NSString *const PKSendingFinishedNotification = @"PKSendingFinishedNotification";

@interface PKDataManager : NSObject <CLLocationManagerDelegate>

+ (PKDataManager *)sharedManager;

@property (readonly) BOOL sendInProgress;
@property (strong, nonatomic, readonly) NSDate *lastSentDate;

@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) CLLocation *lastLocation;

+ (NSDateFormatter *)iso8601DateFormatter;

// Call this if the API endpoint settings change to re-init the HTTP library
- (void)setupHTTPClient;

// Call this when you know you will be recording a data point soon, such as when the user loads the interface
- (void)requestLocation;

- (void)addEntryToQueue:(NSDictionary *)data withKey:(NSString *)key;
- (void)numberOfEntriesInQueue:(void(^)(long num))callback;
- (void)deleteEntryFromQueue:(NSString *)key;
- (void)scheduleSend;
- (void)sendQueueNow;

@end
