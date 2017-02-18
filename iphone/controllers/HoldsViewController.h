#import <UIKit/UIKit.h>
#import "DataStore.h"
#import "AnimatedRefreshButton.h"
#import "UpdateManager.h"

@interface HoldsViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	DataStore					*dataStore;
	NSFetchedResultsController	*fetchedResultsController;
	
	// Reload stuff
	UIBarButtonItem				*refreshButton;
	AnimatedRefreshButton		*animatedRefreshButton;
	UpdateManager				*updateManager;
	
	IBOutlet UIView				*noHoldsView;
	IBOutlet UILabel			*noHoldsViewMainLabel;
	IBOutlet UILabel			*noHoldsViewTopHintLabel;
	IBOutlet UIImageView		*noHoldsViewTopHintArrow;
	IBOutlet UILabel			*noHoldsViewBottomHintLabel;
	IBOutlet UIImageView		*noHoldsViewBottomHintArrow;
}

- (void) reloadTable: (id) sender;

@end
