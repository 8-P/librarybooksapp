#import <UIKit/UIKit.h>
#import "Loan.h"
#import "DataStore.h"

@interface LoansDetailViewContoller : UITableViewController
{
	Loan				*loan;
	NSMutableArray		*rows;
}

@property(retain) Loan *loan;

- (void) addRowWithText: (NSString *) text colour: (UIColor *) colour;
- (void) addRowWithText: (NSString *) text;

@end