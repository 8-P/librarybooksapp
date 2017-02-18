#import "LibraryDrillDownItem.h"
#import "DataStore.h"

@implementation LibraryDrillDownItem

@dynamic path, name, isFolder, library, type, imageName, name2;

+ (LibraryDrillDownItem *) libraryDrillDownItem
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"LibraryDrillDownItem" inManagedObjectContext: context]; 
}

@end