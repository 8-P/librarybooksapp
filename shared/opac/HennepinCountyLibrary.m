// =============================================================================
//
// Hennepin County Library has a different holds format.
//
//		* Parsing is different.
//		* They have 2 tabs, one for the holds waiting and another for the ones
//		  ready for pickup
//
// =============================================================================

#import "HennepinCountyLibrary.h"

@implementation HennepinCountyLibrary

- (BOOL) update
{
	URL *accountURL = [catalogueURL URLWithPath: @"?menu=account"];
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
	[browser.scanner scanFromString: @"session=" upToString: @"&" intoString: &session];
	[browser.scanner scanFromString: @"profile=" upToString: @"&" intoString: &profile];
	
	// The URLs a quite predictable so we just formulate them.
	URL *itemsURL				= [browser.currentURL URLWithPathFormat: @"?session=%@&profile=%@&menu=account&submenu=itemsout", session, profile];
	URL *holdsURL				= [browser.currentURL URLWithPathFormat: @"?session=%@&profile=%@&menu=account&submenu=holds", session, profile];
	URL *holdsReadyForPickupURL = [browser.currentURL URLWithPathFormat: @"?session=%@&profile=%@&menu=account&submenu=subtab26", session, profile];

	// Loans
	[browser go: itemsURL];
//	[browser go: [Test fileURLFor: @"Horizon/20090913_hennepin_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100322_hennepin_loans.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20110911_hennepin_loans.html"]];
	[self parseLoans1];

	// Holds
	[browser go: holdsURL];
//	[browser go: [Test fileURLFor: @"Horizon/20090913_hennepin_holds.html"]];
//	[browser go: [Test fileURLFor: @"Horizon/20100501_hennepin_holds.html"]];
	[self parseHoldsReadyForPickup1: NO];
	
	// The holds ready for pickup is on a different page/tab
	[browser go: holdsReadyForPickupURL];
	[self parseHoldsReadyForPickup1: YES];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
//		* Modified to scanPassString "Selected Titles"
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (Hennepin format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;
	
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseLoanTitleCell:",		@"Title / Author",
		nil
	];

	[scanner scanPassHead];
	[scanner scanPassString: @"Selected Titles"];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"sortby=" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

- (void) parseHoldsReadyForPickup1: (BOOL) ready
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"titleAndAuthor",		@"Title / Author",
		@"queueDescription",	@"Status",
		@"queuePosition",		@"Position",
		nil
	];

	[scanner scanPassHead];

	// Holds ready for pickup
	if ([scanner scanNextElementWithName: @"table" regexValue: @"sortby=format" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObjects: @"sortby=", nil]];
		
		if (ready)	[self addHoldsReadyForPickup:	rows];
		else		[self addHolds:					rows];
	}
}

@end
