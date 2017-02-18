#import "LibraryCard.h"
#import "DataStore.h"

@implementation LibraryCard

@dynamic authentication1, authentication2, authentication3, authenticationOK, overrideProperties,
	libraryPropertyName, ordering, name, deleted, enabled, lastUpdated;

+ (LibraryCard *) libraryCard
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"LibraryCard" inManagedObjectContext: context]; 
}

@end