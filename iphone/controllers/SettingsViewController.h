#import <UIKit/UIKit.h>
#import "DataStore.h"
#import "Settings.h"

@interface SettingsViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	DataStore					*dataStore;
	NSFetchedResultsController	*fetchedResultsController;
	NSUserDefaults				*defaults;
	Settings					*settings;
	
	LibraryCard					*libraryCardToEdit;
	UIAlertView					*alertView;
	BOOL						checkedForUpdate;
	NSInvocationOperation		*updateOperation;
}

- (int) countLibraryCards;
- (BOOL) checkForUpdate;
- (void) displayLibraryCardEditor;

@end