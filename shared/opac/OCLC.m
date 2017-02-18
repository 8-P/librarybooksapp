// =============================================================================
//
// OCLC PICA.
//
//		* Implementation based on Universitätsbibliothek Hildesheim.
//
// =============================================================================

#import "OCLC.h"

@implementation OCLC

- (BOOL) update
{
	[browser go: catalogueURL];
	
	// Log in
	if ([browser submitFormNamed: @"" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	URL *loansURL = [browser linkForLabel: @"loans"];
	URL *holdsURL = [browser linkForLabel: @"reservations"];
	
	// TODO: search for href with: ACT=UI_LOL
	
	// Loans
	[browser go: loansURL];
//	[browser go: [Test fileURLFor: @"OCLC/20100619_bremen_loans.html"]];
	[self parseLoans1];
	[self parseLoans2];
	
	// Holds
	[browser go: holdsURL];
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

	[NSScannerSettings sharedSettings].columnCountMustMatch = NO;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"summary" attributeValue: @"list of loans - data"
		intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse loans.
//
//		* Format from Staats- und Universitätsbibliothek Bremen.
//		* Information is stored in an embedded table.
//
// -----------------------------------------------------------------------------
- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	[NSScannerSettings sharedSettings].columnCountMustMatch = NO;
	
	[scanner scanPassHead];

	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseLoanCell2:", @"expiry date",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"summary" attributeValue: @"list of loans - data"
		intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing of the loans title cell.
//
// Cell content:
//
//		<table summary="title data" width="100%" cellpadding="0" cellspacing="0" border="0">
//		<tr valign="top">
//			<td class="plain">Lore of running / Timothy D. Noakes</td>
//		</tr>
//		<tr valign="top" style="padding-bottom:4px;" nowrap="nowrap">
//			<td class="value-small">
//				<span class="label-small">shelf mark:</span> a spo 630 f/806(4); <span class="label-small">status:</span> presently lent; <span class="label-small">expiry date:</span> 17-08-2010; <span class="label-small">reservations:</span> 0
//			</td>
//		</tr>
//		</table>
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseLoanCell2: (NSString *) string
{
	OrderedDictionary *dictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"element:td",					@"titleAndAuthor",
		@"regex:expiry date:(.*?);",	@"dueDate",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	return [scanner analyseUsingDictionary: dictionary];
}

// -----------------------------------------------------------------------------
//
// Parse holds.
//
//		* All information is in the title column.  Need to set the minColumns
//		  setting as by default the table parser wants to match atleast two
//		  columns.
//		* The header row has more columns than the data rows.  The table parser
//		  will reject the data rows because the column spec tells it to expect
//		  more columns.  The columnCountMustMatch setting disables this check.
//		* The web page is built using tables so we need to *recursively* search
//		  to the table element.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	// The holds table only has one column
	[NSScannerSettings sharedSettings].minColumns = 1;
	[NSScannerSettings sharedSettings].columnCountMustMatch = NO;

	[scanner setScanLocation: 0];
	[scanner scanPassElementWithName: @"head"];

	if ([scanner scanNextElementWithName: @"table" attributeKey: @"summary" attributeValue: @"list of reservations - data"
		intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"" entries: self.authenticationAttributes];
}

@end