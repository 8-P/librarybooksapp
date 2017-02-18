#import "Location.h"
#import "DataStore.h"

@implementation Location

@synthesize distance;
@dynamic identifier, latitude, longitude, library;

+ (Location *) location
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"Location" inManagedObjectContext: context]; 
}

// -----------------------------------------------------------------------------
//
// For comparing the distances between locations.  Useful for sorting locations
// based on distance.
//
// Note that you need to set the distance value first.
//
// -----------------------------------------------------------------------------
- (NSComparisonResult) compare: (Location *) anotherLocation
{
	CLLocationDistance diff = self.distance - anotherLocation.distance;
	if      (diff < 0) return NSOrderedAscending;
	else if (diff > 0) return NSOrderedDescending;
	else               return NSOrderedSame;
}

- (void) setDistanceFromCLLocation: (CLLocation *) location
{
	CLLocation *l	= [[CLLocation alloc] initWithLatitude: [self.latitude doubleValue] longitude: [self.longitude doubleValue]];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	distance		= [location getDistanceFrom: l];
#else
	distance		= [location distanceFromLocation: l];
#endif
	[l release];
}

@end
