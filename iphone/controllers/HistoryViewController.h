#import <UIKit/UIKit.h>
#import "DataStore.h"

@interface HistoryViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController	*fetchedResultsController;
	NSArray						*months;
	DataStore					*dataStore;
	NSDateFormatter				*dateFormatter;
	NSDateFormatter				*indexDateFormatter;
	
	IBOutlet UIView				*noHistoryView;
}

- (void) reloadTable: (id) sender;

@end