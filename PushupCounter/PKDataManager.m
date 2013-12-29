//
//  PKDataManager.m
//  ReactionTime
//
//  Created by Aaron Parecki on 11/22/13.
//  Copyright (c) 2013 Aaron Parecki. All rights reserved.
//

#import "PKDataManager.h"
#import "LOLDatabase.h"
#import "AFHTTPSessionManager.h"

@interface PKDataManager()

@property BOOL sendInProgress;
@property (strong, nonatomic) NSDate *lastSentDate;
@property (strong, nonatomic) NSTimer *scheduleSendTimer;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (strong, nonatomic) NSDate *startedLocationRequestDate;
@property (strong, nonatomic) NSTimer *locationRequestTimer;

@property (strong, nonatomic) LOLDatabase *db;

@end

@implementation PKDataManager

static NSString *const PKCollectionQueueName = @"PKCollectionQueue";

AFHTTPSessionManager *_httpClient;

+ (PKDataManager *)sharedManager {
    static PKDataManager *_instance = nil;
    
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
            
            _instance.db = [[LOLDatabase alloc] initWithPath:[self cacheDatabasePath]];
            _instance.db.serializer = ^(id object){
                return [self dataWithJSONObject:object error:NULL];
            };
            _instance.db.deserializer = ^(NSData *data) {
                return [self objectFromJSONData:data error:NULL];
            };
            
            [_instance setupHTTPClient];
        }
    }
    
    return _instance;
}

- (void)setupHTTPClient {
    if([[NSUserDefaults standardUserDefaults] stringForKey:PKAPIAccessTokenDefaultsName] && [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIEndpointDefaultsName]) {
    
        NSURL *endpoint = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:PKAPIEndpointDefaultsName]];
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIAccessTokenDefaultsName]]};
        
        _httpClient = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", endpoint.scheme, endpoint.host]] sessionConfiguration:sessionConfiguration];
        _httpClient.requestSerializer = [AFHTTPRequestSerializer serializer];
        _httpClient.responseSerializer = [AFHTTPResponseSerializer serializer];
        _httpClient.responseSerializer.acceptableStatusCodes = [[NSIndexSet alloc] initWithIndex:201];
        
        NSLog(@"Set up HTTP client with token: %@", [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIAccessTokenDefaultsName]);
    }
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 1;
        _locationManager.pausesLocationUpdatesAutomatically = YES;
    }
    
    return _locationManager;
}

+ (NSDateFormatter *)iso8601DateFormatter {
    static NSDateFormatter *iso8601;
    
    if (!iso8601) {
        iso8601 = [[NSDateFormatter alloc] init];
        
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        NSInteger offset = [timeZone secondsFromGMT];
        
        NSMutableString *strFormat = [NSMutableString stringWithString:@"yyyy-MM-dd'T'HH:mm:ss"];
        offset /= 60;
        if (offset == 0) {
            [strFormat appendString:@"Z"];
        } else {
            [strFormat appendFormat:@"%+03ld:%02ld", (long)(offset / 60), (long)(offset % 60)];
        }
        
        [iso8601 setTimeStyle:NSDateFormatterFullStyle];
        [iso8601 setDateFormat:strFormat];
    }
    
    return iso8601;
}

#pragma mark LOLDB

+ (NSString *)cacheDatabasePath
{
	NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	return [caches stringByAppendingPathComponent:@"PKDBCache.sqlite"];
}

+ (id)objectFromJSONData:(NSData *)data error:(NSError **)error;
{
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
}

+ (NSData *)dataWithJSONObject:(id)object error:(NSError **)error;
{
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
}

#pragma mark - Queue

- (void)addEntryToQueue:(NSDictionary *)data withKey:(NSString *)key
{
    NSLog(@"Adding Entry: %@", data);
	[self.db accessCollection:PKCollectionQueueName withBlock:^(id<LOLDatabaseAccessor> accessor) {
        [accessor setDictionary:data forKey:key];
	}];
}

- (void)numberOfEntriesInQueue:(void(^)(long num))callback {
    [self.db accessCollection:PKCollectionQueueName withBlock:^(id<LOLDatabaseAccessor> accessor) {
        [accessor countObjectsUsingBlock:callback];
    }];
}

- (void)deleteEntryFromQueue:(NSString *)key
{
	[self.db accessCollection:PKCollectionQueueName withBlock:^(id<LOLDatabaseAccessor> accessor) {
        [accessor removeDictionaryForKey:key];
	}];
}

- (void)sendingStarted {
    self.sendInProgress = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:PKSendingStartedNotification object:self];
}

- (void)sendingFinished {
    self.sendInProgress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:PKSendingFinishedNotification object:self];
}

- (void)scheduleSend {
    // Sets a delay to send the data. If no new points are entered within the window, the data is sent
    if(!self.sendInProgress) {
        if(self.scheduleSendTimer) {
            // If there is already a timer, cancel it and set a new timer
            [self.scheduleSendTimer invalidate];
        }
        self.scheduleSendTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(sendNowAfterSchedule) userInfo:nil repeats:NO];
    }
}

// This method is run after the NSTimer fires, which means the data may or may not have already been sent anyway
- (void)sendNowAfterSchedule {
    NSLog(@"Timer fired");
    if(self.scheduleSendTimer && !self.sendInProgress) {
        [self.scheduleSendTimer invalidate];
        self.scheduleSendTimer = nil;
        [self sendQueueNow];
    }
}

- (void)sendQueueNow {

    __block long numEntries;
    [self numberOfEntriesInQueue:^(long num) {
        if(num == 0) {
            numEntries = num;
        }
    }];
    
    if(numEntries == 0) {
        NSLog(@"Nothing in the queue");
        return;
    }

    NSString *endpoint = [[NSUserDefaults standardUserDefaults] stringForKey:PKAPIEndpointDefaultsName];
    
    if(endpoint == nil || [endpoint isEqualToString:@""]) {
        NSLog(@"No endpoint configured");
        return;
    }

    NSLog(@"Endpoint: %@", endpoint);

    NSMutableSet *syncedEntries = [NSMutableSet set];
    NSMutableArray *entries = [NSMutableArray array];
    
    [self.db accessCollection:PKCollectionQueueName withBlock:^(id<LOLDatabaseAccessor> accessor) {
        
        [accessor enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *object) {
            [syncedEntries addObject:key];
            [entries addObject:object];
            return (BOOL)(entries.count == 1);
        }];
        
    }];
    

    [self sendingStarted];
    
    NSDictionary *postData = [entries objectAtIndex:0];
    
    NSLog(@"Entries in post: %lu", (unsigned long)entries.count);
    
    [_httpClient POST:endpoint parameters:postData success:^(NSURLSessionDataTask *task, id responseObject) {

        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSLog(@"Response Code %ld", (long)response.statusCode);
        NSLog(@"Headers: %@", response.allHeaderFields);
        
        // Check for a "Location" header which has the URL of the created entry
        if([response.allHeaderFields objectForKey:@"Location"]) {
            self.lastSentDate = NSDate.date;
            
            [self.db accessCollection:PKCollectionQueueName withBlock:^(id<LOLDatabaseAccessor> accessor) {
                for(NSString *key in syncedEntries) {
                    [accessor removeDictionaryForKey:key];
                }
            }];
        } else {
            [self notify:@"No Location header returned. Entry was not saved." withTitle:@"Error"];
        }
        
        [self sendingFinished];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
        [self notify:error.description withTitle:@"Error"];
        [self sendingFinished];
    }];
    
}

#pragma mark - Location

// Gets one location fix (with greater accuracy than 200m) and then stops
- (void)requestLocation
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:PKSaveLocationDefaultsName]) {
        [self.locationManager startUpdatingLocation];
        self.startedLocationRequestDate = NSDate.date;
        self.locationRequestTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(locationRequestTimedOut) userInfo:nil repeats:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = (CLLocation *)locations[0];
    if(location.horizontalAccuracy < 200) {
        // If the accuracy is good enough, store in lastLocation and stop updating
        self.lastLocation = location;
        [self.locationManager stopUpdatingLocation];
        [self.locationRequestTimer invalidate];
        self.locationRequestTimer = nil;
        NSLog(@"Got location fix: %@", location);
    }

    if([self.startedLocationRequestDate timeIntervalSinceNow] >= 30) {
        [self.locationManager stopUpdatingLocation];
        self.startedLocationRequestDate = nil;
        [self.locationRequestTimer invalidate];
        self.locationRequestTimer = nil;
        NSLog(@"Location acquisition timed out");
    }
}

- (void)locationRequestTimedOut
{
    // Time out after 30 seconds of trying to get a fix
    [self.locationManager stopUpdatingLocation];
    self.startedLocationRequestDate = nil;
    [self.locationRequestTimer invalidate];
    self.locationRequestTimer = nil;
    NSLog(@"Location acquisition timed out");
}


#pragma mark -

- (void)notify:(NSString *)message withTitle:(NSString *)title
{
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alert show];
    } else {
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
        localNotification.alertBody = [NSString stringWithFormat:@"%@: %@", title, message];
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

@end
