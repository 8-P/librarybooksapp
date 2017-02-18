// =============================================================================
//
// State Library of Tasmania.
//
//		* It looks like they have a bespoke system.
//
// =============================================================================

#import "TALIS.h"

@implementation TALIS

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/bag/logout.aspx"]];
	[browser go: catalogueURL];
	
	// Log in
	if ([browser submitFormNamed: @"loginform" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	[browser go: [Test fileURLFor: @"TALIS/20130728_tasmania_loans.html"]];	
	
	[self parseLoans1];
	[self parseHolds1];

	return YES;
}

// -----------------------------------------------------------------------------
//
// Parse loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"div" attributeKey: @"id" attributeValue: @"patronloans"
		intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	[scanner scanPassHead];
	
	// Holds ready for pickup
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"summary" attributeValue: @"Items on hold awaiting pickup"
		intoElement: &element recursive: YES])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"parseHoldCell:", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHoldsReadyForPickup: rows];
	}
	
	// Holds waiting.
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"summary" attributeValue: @"Items on hold"
		intoElement: &element recursive: YES])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"parseHoldCell:", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The holds info is all in one table cell.
//
// Example:
//
//		<h4><a href="...">The Buddha, Geoff &amp; me</a> (...)</h4>
//		<b>Author:</b> Canfor-Dumas, Edward<br />
//		<b>Pickup location:</b> Kingston Library<br />
//		<b>Total copies:</b> 3<br />
//		<b>Queue position:</b> 5<br />
//		<b>Estimated wait:</b> 13 to 51 days<br />
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseHoldCell: (NSString *) string
{
	NSScanner *scanner			= [NSScanner scannerWithString: string];
	HTMLElement *element		= nil;
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity: 3];
	
	if ([scanner scanNextElementWithName: @"h4" intoElement: &element])
	{
		[values setObject: [element.value stringWithoutHTML] forKey: @"title"];
	}
	
	NSDictionary *mappings = [NSDictionary dictionaryWithObjectsAndKeys:
		@"author",				@"Author:(.*)$",
		@"pickupAt",			@"Pickup location:(.*)$",
		@"queuePosition",		@"Queue position:(.*)$",
		@"queueDescription",	@"Status:(.*)$",
		@"queueDescription",	@"(Estimated wait:.*)$",
		nil
	];

	NSString *line;
	while ([scanner scanUpToString: @"<br />" intoString: &line])
	{
		line = [line stringWithoutHTML];
		for (NSString *regex in mappings)
		{
			NSString *value = [line stringByMatching: regex capture: 1];
			if (value)
			{
				NSString *key = [mappings objectForKey: regex];
				[values setObject: [value stringByTrimmingWhitespace] forKey: key];
				break;
			}
		}
		
		[scanner scanPassString: @"<br />"];
	}
	
	return values;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: [myAccountCatalogueURL URLWithPath: @"/bag/logout.aspx"]];
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"loginform" entries: self.authenticationAttributes];
}

@end