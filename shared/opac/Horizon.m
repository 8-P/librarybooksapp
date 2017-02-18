// =============================================================================
//
// Horizon DYNIX
//
// =============================================================================

#import "Horizon.h"

@implementation Horizon

- (BOOL) update
{
	URL *accountURL = [catalogueURL URLWithPath: @"?menu=account&forcelogout=true"];
	[browser go: accountURL];
	
	// Log in
	if ([browser submitFormNamed: @"security" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	NSString *session = @"";
	NSString *profile = @"";
	[browser.scanner scanRegex: @"session=(.*?)[&\"]" capture: 1 intoString: &session];
	[browser.scanner scanRegex: @"profile=(.*?)[&\"]" capture: 1 intoString: &profile];
	
	// The URLs a quite predictable so we just formulate them.
	URL *itemsURL = [browser.currentURL URLWithPathFormat: @"?session=%@&profile=%@&menu=account&submenu=itemsout", session, profile];
	URL *holdsURL = [browser.currentURL URLWithPathFormat: @"?session=%@&profile=%@&menu=account&submenu=holds", session, profile];

	// Loans
	[browser go: itemsURL];
//	[browser go: [Test fileURLFor: @"Horizon/20090816_hume_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100312_spl_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100413_vancouver_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100514_bellingham_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100715_vancouverisland_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20120112_winnipeg_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20120830_silnet_loans.html"]];

	[self parseLoans1];

	// Holds
	[browser go: holdsURL];
//	[browser go: [Test fileURLFor: @"Horizon/20120830_swap_holds.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20090609_spl_holds.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20090902_hume_holds1.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100312_spl_holds.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100410_hume_holds_felicity.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100530_vpl_holds.html"]];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
//		* Need to ignore "Due" which searching for the dueDate field.  SILNET
//		  has two columns ("Due Date" and "Due Time") so we need to search for
//		  the full string "Due Date".
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;
	
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseLoanTitleCell:",		@"Title",
		@"parseLoanTitleCell:",		@"TITLE",
		@"parseLoanTitleCell:",		@"Title/Author",
		@"parseLoanTitleCell:",		@"Title / Author",
		@"dueDate",					@"Due Date",
		@"",						@"Due",
		nil
	];

	[scanner scanPassHead];
	[scanner scanPassString: @"renewitems"];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"sortby=" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseHoldTitleCell:",		@"Requested Title",
		@"parseHoldTitleCell:",		@"Title",
		@"parseHoldTitleCell:",		@"TITLE",
		@"parseHoldTitleCell:",		@"Title/Author",
		@"parseHoldTitleCell:",		@"Title / Author",
		nil
	];

	[scanner scanPassHead];

	// Holds ready for pickup
	if ([scanner scanNextElementWithName: @"table" regexValue: @"[;&]ready_sortby=" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObjects: @";ready_sortby=sorttitle", nil] delegate: self];
		[self addHoldsReadyForPickup: rows];
	}
	
	[scanner setScanLocation: 0];
	[scanner scanPassElementWithName: @"head"];
	
	// Holds not yet available
	if ([scanner scanNextElementWithName: @"table" regexValue: @"[;&]sortby=" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObjects: @";sortby=sorttitle", nil] delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing of the loans title cell.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseLoanTitleCell: (NSString *) string
{
	NSScanner *scanner			= [NSScanner scannerWithString: string];
	HTMLElement *element		= nil;
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity: 2];
	
	NSArray *columns = [NSArray arrayWithObjects: @"title", @"author", nil];
	for (NSString *column in columns)
	{
		if ([scanner scanNextElementWithName: @"td" intoElement: &element])
		{
			if ([column length] > 0)
			{
				NSString *value = [element.value stringWithoutHTML];
				if ([column isEqualToString: @"author"]) value = [value stringByDeletingOccurrencesOfRegex: @"^(by)?\\s*"];
				[values setObject: value forKey: column];
			}
		}
	}
	
	return values;
}

// -----------------------------------------------------------------------------
//
// Special parsing of the holds "Requested Title" cell.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseHoldTitleCell: (NSString *) string
{
	NSScanner *scanner			= [NSScanner scannerWithString: string];
	HTMLElement *element		= nil;
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity: 3];
	
	NSArray *columns = [NSArray arrayWithObjects: @"title", @"author", nil];
	for (NSString *column in columns)
	{
		if ([scanner scanNextElementWithName: @"td" intoElement: &element])
		{
			if ([column length] > 0)
			{
				NSString *value = [element.value stringWithoutHTML];
				[values setObject: value forKey: column];
			}
		}
	}
	
	// Search for the pickup location
	NSString *pickupAt = [string stringByMatching: @">Pickup Location:(.*?)<" capture: 1];
	if (pickupAt) [values setObject: [pickupAt stringWithoutHTML] forKey: @"pickupAt"];
	
	return values;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	URL *accountURL = [catalogueURL URLWithPath: @"?menu=account&forcelogout=true"];
	[browser go: accountURL];
	
	return [browser linkToSubmitFormNamed: @"security" entries: self.authenticationAttributes];
}

@end