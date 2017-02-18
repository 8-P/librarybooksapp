// =============================================================================
//
// SirsiDynix Symphony
//
//		* New fancy AJAX version.
//		* Based on us.ny.NewCityLibrary.
//
// =============================================================================

#import "Symphony.h"

@implementation Symphony

- (BOOL) update
{
	NSString *basePath = [[catalogueURL absoluteString] stringByMatching: @"(/client(/.+)?)/search" capture: 1];
	[browser go: [catalogueURL URLWithPathFormat: @"%@/search/patronlogin/", basePath]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	[browser go: [catalogueURL URLWithPathFormat: @"%@/search/account", basePath]];
	
//	[browser go: [Test fileURLFor: @"Symphony/20121209_newcity_holds.html"]];
//	[browser go: [Test fileURLFor: @"Symphony/20120114_newcity_loans.html"]];
//	[browser go: [Test fileURLFor: @"Symphony/20120124_newcity_holdsready.html"]];
//	[browser go: [Test fileURLFor: @"Symphony/20130808_oshawa_holdsready.html"]];
//	[browser go: [Test fileURLFor: @"Symphony/20130901_newcity.html"]];
	
	[self parseLoans1];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleCell:", @"Title / Author",
		@"timesRenewed",	@"Times Renewed",  // ca.on.OshawaPublicLibraries
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"checkoutsList sortable" intoElement: &element recursive: YES])
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
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	// The first column is the holds ready for pickup.  A green exclamation mark
	// image is displayed for ready holds
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseReadyForPickupCell:",	@"0",
		@"parseTitleCell:",				@"Title/Author",
		nil
	];

	if ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"holdsList sortable" intoElement: &element recursive: YES])
	{
		// Manually set clock to check for the holds ready image
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObject: @"Title/Author"] delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Title and author cell parsing.
//
//		* Used for both loans and holds.
//
// Cell looks like:
//
//		<div>
//			<div class="detailPanel" id="detailPanel2">
//				<div class="t-zone" id="detailZone2"></div>
//			</div><a class="detailLink" href="#" ... title="The change-up [DVD]">The change-up [DVD]</a>
//		</div>
//		<p class="authBreak">Dobkin, David, 1969-<br />
//			<span class="checkoutsError">Renewal limit reached: This item cannot be renewed.</span></p>
//
// Sometimes it doesn't have the <a></a> link:
//
//		<div>
//			<div class="detailPanel" id="detailPanel0">
//				<div class="t-zone" id="detailZone0"></div>
//			</div>Love in a nutshell
//		</div>
//		<p class="authBreak">Evanovich, Janet.</p>
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseTitleCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
//		@"<a.*?class=\"detailLink\".*?>(.*?)</a>",		@"title",
		@"<div.*?id=\"detailZone\\d+\".*?>.*?</div>\\s*</div>(.*?)</div>",	@"title",
		@"<p.*?class=\"authBreak\">(.*)",				@"author",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	NSDictionary *result = [scanner dictionaryUsingRegexMapping: mapping];
	if ([result count] == 0)
	{
		// Fall back to using the whole string as the title
		result = [NSDictionary dictionaryWithObject: [string stringWithoutHTML] forKey: @"title"];
	}
	
	return result;
}

// -----------------------------------------------------------------------------
//
// See if a hold is ready for pickup.
//
// Ready for pickup cells look like:
//
//		<td class="holdsAlert" colspan="1" rowspan="1" sorttable_customkey="0">
//			<img alt="Ready for pickup icon" src="/client/images/account-icons/green!.png"
//			title="Ready since 1/23/12" />
//		</td>
//
// Not ready ones look like:
//
//		<td class="holdsAlert" colspan="1" rowspan="1" sorttable_customkey="2"></td>
//
// Examples in the Symphony/20120124_newcity_holdsready.html test file.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseReadyForPickupCell: (NSString *) string
{
	// Look for the green!.png image to detect if the hold is ready.  I originally
	// tried to match the text "Ready for pickup icon" but that varies between
	// libraries
	if ([string hasSubString: @"green!.png"])
	{
		return [NSDictionary dictionaryWithObject: @"yes" forKey: @"readyForPickup"];
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
//		* Makes an AJAX POST then goes to the account page.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	NSString *basePath = [[myAccountCatalogueURL absoluteString] stringByMatching: @"(/client(/.+)?)/search" capture: 1];
	[browser go: [myAccountCatalogueURL URLWithPathFormat: @"%@/search/patronlogin/", basePath]];
	
	URL *url	= [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
	url.nextURL = [myAccountCatalogueURL URLWithPathFormat: @"%@/search/account", basePath];
	
	return url;
}

@end