#import <UIKit/UIKit.h>
#import "History.h"
#import "DataStore.h"

@interface HistoryDetailViewController : UITableViewController
{
	History				*history;
	NSMutableArray		*rows;
}

@property(retain) History *history;

- (void) addRowWithText: (NSString *) text;

@end