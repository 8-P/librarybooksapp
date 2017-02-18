#import <UIKit/UIKit.h>
#import "Hold.h"
#import "DataStore.h"

@interface HoldsDetailViewController : UITableViewController
{
	Hold				*hold;
	NSMutableArray		*rows;
}

@property(retain) Hold *hold;

- (void) addRowWithText: (NSString *) text colour: (UIColor *) colour;
- (void) addRowWithText: (NSString *) text;

@end