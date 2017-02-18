#import <Foundation/Foundation.h>
#import "LibraryProperties.h"
#import "LibraryCard.h"

@interface MoreLibrariesViewController : UITableViewController
{
	LibraryCard					*libraryCard;
	NSFetchedResultsController	*fetchedResultsController;
	DataStore					*dataStore;
	NSString					*currentPath;
}

@property(retain) LibraryCard	*libraryCard;
@property(retain) NSString		*currentPath;

@end