#import "Library.h"
#import "DataStore.h"

@implementation Library

@dynamic identifier, properties, path, name, libraryDrillDownItem, locations, type, beta;

+ (Library *) library
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"Library" inManagedObjectContext: context]; 
}

@end