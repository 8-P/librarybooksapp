#import <UIKit/UIKit.h>
#import "DataStore.h"
#import "AnimatedRefreshButton.h"
#import "UpdateManager.h"

@interface LoansViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController	*fetchedResultsController;
	NSDateFormatter				*dayDateFormatter;
	NSDateFormatter				*monthDateFormatter;
	NSDateFormatter				*weekdayDateFormatter;
	DataStore					*dataStore;
	
	// Reload stuff
	UIBarButtonItem				*refreshButton;
	AnimatedRefreshButton		*animatedRefreshButton;
	UpdateManager				*updateManager;
	
	IBOutlet UIView				*noLoansView;
	IBOutlet UILabel			*noLoansViewMainLabel;
	IBOutlet UILabel			*noLoansViewTopHintLabel;
	IBOutlet UIImageView		*noLoansViewTopHintArrow;
	IBOutlet UILabel			*noLoansViewBottomHintLabel;
	IBOutlet UIImageView		*noLoansViewBottomHintArrow;
}

- (void) reloadTable: (id) sender;

@end