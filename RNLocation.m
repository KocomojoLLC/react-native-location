#import <CoreLocation/CoreLocation.h>

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

#import "RNLocation.h"

@interface RNLocation() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation RNLocation

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

#pragma mark Initialization

- (instancetype)init
{
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        
        self.locationManager.delegate = self;
        
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    
    return self;
}

#pragma mark


- (CLCircularRegion *) convertDictToCircularRegion: (NSDictionary *) dict
{
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dict[@"latitude"]doubleValue], [dict[@"longitude"]doubleValue]);
    CLLocationDistance radius = [dict[@"radius"]doubleValue];
    
    if(radius > self.locationManager.maximumRegionMonitoringDistance) {
        radius = self.locationManager.maximumRegionMonitoringDistance;
    }
    
    CLCircularRegion *circularRegion = [[CLCircularRegion alloc]initWithCenter:center radius:radius identifier:dict[@"id"]];
    
    return circularRegion;
}


RCT_EXPORT_METHOD(requestAlwaysAuthorization)
{
    [self.locationManager requestAlwaysAuthorization];
}

RCT_EXPORT_METHOD(requestWhenInUseAuthorization)
{
    [self.locationManager requestWhenInUseAuthorization];
}

RCT_EXPORT_METHOD(getAuthorizationStatus:(RCTResponseSenderBlock)callback)
{
    callback(@[[self nameForAuthorizationStatus:[CLLocationManager authorizationStatus]]]);
}

RCT_EXPORT_METHOD(setDesiredAccuracy:(NSString *) accuracy)
{
    if([accuracy isEqualToString:@"best"]) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    } else if([accuracy isEqualToString:@"ten_meters"]) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    } else if([accuracy isEqualToString:@"hundred_meters"]) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    } else if([accuracy isEqualToString:@"kilometer"]) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    } else if([accuracy isEqualToString:@"three_kilometers"]) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    }
}


RCT_EXPORT_METHOD(setDistanceFilter:(double) distance)
{
    self.locationManager.distanceFilter = distance;
}

RCT_EXPORT_METHOD(setAllowsBackgroundLocationUpdates:(BOOL) enabled)
{
    self.locationManager.allowsBackgroundLocationUpdates = enabled;
}

RCT_EXPORT_METHOD(startMonitoringSignificantLocationChanges)
{
    [self.locationManager startMonitoringSignificantLocationChanges];
}

RCT_EXPORT_METHOD(startMonitoringForRegion:(NSDictionary *) dict)
{
    CLCircularRegion *region = [self convertDictToCircularRegion:dict];
    
    [self.locationManager startMonitoringForRegion:region];
}

RCT_EXPORT_METHOD(stopMonitoringForRegion:(NSDictionary *) dict)
{
    [self.locationManager stopMonitoringForRegion:[self convertDictToCircularRegion:dict]];
}

RCT_EXPORT_METHOD(printMonitoredRegions)
{
    for (CLRegion *monitoredRegion in self.locationManager.monitoredRegions) {
        NSLog(@"monitoredRegion: %@", monitoredRegion);
    }
    NSLog(@"Count: %i", [self.locationManager.monitoredRegions count]);
}

RCT_EXPORT_METHOD(removeAllMonitoredRegions)
{
    for (CLRegion *monitoredRegion in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:monitoredRegion];
    }
    
}

RCT_EXPORT_METHOD(startUpdatingLocation)
{
    [self.locationManager startUpdatingLocation];
}

RCT_EXPORT_METHOD(startUpdatingHeading)
{
    [self.locationManager startUpdatingHeading];
}

RCT_EXPORT_METHOD(stopMonitoringSignificantLocationChanges)
{
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

RCT_EXPORT_METHOD(stopUpdatingLocation)
{
    [self.locationManager stopUpdatingLocation];
}

RCT_EXPORT_METHOD(stopUpdatingHeading)
{
    [self.locationManager stopUpdatingHeading];
}

-(NSString *)nameForAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
    switch (authorizationStatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
            return @"authorizedAlways";
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return @"authorizedWhenInUse";
            
        case kCLAuthorizationStatusDenied:
            return @"denied";
            
        case kCLAuthorizationStatusNotDetermined:
            return @"notDetermined";
            
        case kCLAuthorizationStatusRestricted:
            return @"restricted";
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSString *statusName = [self nameForAuthorizationStatus:status];
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"authorizationStatusDidChange" body:statusName];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    CLLocationDirection heading = ((newHeading.trueHeading > 0) ?
                                   newHeading.trueHeading : newHeading.magneticHeading);
    
    NSDictionary *headingEvent = @{
                                   @"heading": @(heading)
                                   };
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"headingUpdated" body:headingEvent];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    NSDictionary *locationEvent = @{
                                    @"coords": @{
                                            @"latitude": @(location.coordinate.latitude),
                                            @"longitude": @(location.coordinate.longitude),
                                            @"altitude": @(location.altitude),
                                            @"accuracy": @(location.horizontalAccuracy),
                                            @"altitudeAccuracy": @(location.verticalAccuracy),
                                            @"course": @(location.course),
                                            @"speed": @(location.speed),
                                            },
                                    @"timestamp": @([location.timestamp timeIntervalSince1970] * 1000) // in ms
                                    };
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"locationUpdated" body:locationEvent];
}


-(void)locationManager:(CLLocationManager *)manager
        didEnterRegion:(CLRegion *)region {
    
    if([region isMemberOfClass:[CLCircularRegion class]]) {
        CLCircularRegion *circularRegion = (CLCircularRegion *)region;
        NSDictionary *event = @{
                                @"region": circularRegion.identifier,
                                @"center": @{
                                        @"latitude": [NSNumber numberWithDouble:circularRegion.center.latitude],
                                        @"longitude": [NSNumber numberWithDouble:circularRegion.center.longitude]
                                        },
                                @"radius": [NSNumber numberWithDouble:circularRegion.radius]
                                };
        
        [self.bridge.eventDispatcher sendDeviceEventWithName:@"circularRegionDidEnter" body:event];
    }
}

-(void)locationManager:(CLLocationManager *)manager
         didExitRegion:(CLRegion *)region {
    
    if([region isMemberOfClass:[CLCircularRegion class]]) {
        CLCircularRegion *circularRegion = (CLCircularRegion *)region;
        NSDictionary *event = @{
                                @"region": circularRegion.identifier,
                                @"center": @{
                                        @"latitude": [NSNumber numberWithDouble:circularRegion.center.latitude],
                                        @"longitude": [NSNumber numberWithDouble:circularRegion.center.longitude]
                                        },
                                @"radius": [NSNumber numberWithDouble:circularRegion.radius]
                                };
        
        [self.bridge.eventDispatcher sendDeviceEventWithName:@"circularRegionDidExit" body:event];
    }
}


@end
