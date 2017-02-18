// =============================================================================
//
// Bellingham Public Library, WA, USA
//
//		* The ready for pickup title has been changed and the auto-column
//		  detection doesn't work.
//
// =============================================================================

#import "BellinghamPublicLibrary.h"

@implementation BellinghamPublicLibrary

// -----------------------------------------------------------------------------
//
// Custom loans parsing because the library has customised the headers.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (Bellingham format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	[scanner scanPassString: @"renewitems"];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"sortby=" intoElement: &element])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"", @"parseLoanTitleCell:", @"", @"", @"dueDate", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Custom holds parsing.  The ready for pick title header has been changed
// to "<-- Click box at left to select all or click selected items; then click RENEW."
// so analyseHoldTableColumns won't work.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[super parseHolds1];

	[Debug log: @"Parsing holds (Bellingham format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	// Rescan holds ready for pickup
	if ([scanner scanNextElementWithName: @"table" regexValue: @"[;&]ready_sortby=" intoElement: &element])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"", @"parseHoldTitleCell:", @"pickupAt", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObjects: @";ready_sortby=sorttitle", nil] delegate: self];
		[self addHoldsReadyForPickup: rows];
	}
}

@end
