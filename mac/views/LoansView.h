#import <Cocoa/Cocoa.h>
#import "Loan.h"

@interface LoansView : NSView
{
	NSTextField *weekdayLabel;
	NSTextField *dayLabel;
	NSTextField *monthLabel;
	NSTextField *todayLabel;
	NSImageView *dot;
	NSTextField *titleLabel;

	NSString	*weekday;
	NSString	*day;
	NSString	*month;
	NSString	*today;
	NSString	*title;
	NSString	*author;
	NSString	*timesRenewed;
	
	BOOL		dueDateHidden;
	NSInteger	daysUntilDue;
}

@property(retain)	NSString	*weekday;
@property(retain)	NSString	*day;
@property(retain)	NSString	*month;
@property(retain)	NSString	*today;
@property(retain)	NSString	*title;
@property(retain)	NSString	*author;
@property(retain)	NSString	*timesRenewed;
@property			BOOL		dueDateHidden;
@property			NSInteger	daysUntilDue;

- (void) setLoan: (Loan *) loan;
- (void) adjustHeightForTextField: (NSTextField *) textLabel;

@end