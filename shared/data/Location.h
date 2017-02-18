#import <Foundation/Foundation.h>
#import "Library.h"

@interface Location : NSManagedObject
{
	CLLocationDistance distance;
}

@property(nonatomic, retain)	NSString			*identifier;
@property(nonatomic, retain)	NSNumber			*latitude;
@property(nonatomic, retain)	NSNumber			*longitude;
@property(nonatomic, retain)	Library				*library;
@property						CLLocationDistance	distance;

+ (Location *) location;
- (NSComparisonResult) compare: (Location *) location;
- (void) setDistanceFromCLLocation: (CLLocation *) location;

@end
