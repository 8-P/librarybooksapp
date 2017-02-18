#import <Foundation/Foundation.h>
#import "LibraryProperties.h"
#import "LibraryCard.h"

@interface LibrariesViewController : UITableViewController <CLLocationManagerDelegate>
{
	LibraryProperties	*libraryProperties;
	LibraryCard			*libraryCard;
	CLLocationManager	*locationManager;
	NSArray				*nearbyLocations;
}

@property(retain) LibraryCard *libraryCard;

@end