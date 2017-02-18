// =============================================================================
//
// Evergreen 4
//
//		* Looks more a like normal OPAC system and doesn't use AJAX.
//		* Based on C/W Mars system.
//
// =============================================================================

#import "Evergreen4.h"

@implementation Evergreen4

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/eg/opac/logout"]];
	[browser go: [catalogueURL URLWithPath: @"/eg/opac/login"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"Evergreen/20131201_margs_account.html"]];
	
	URL *loansURL				= [self linkForValue: @"Items Currently Checked out"];
	URL *holdsURL				= [self linkForValue: @"Items Currently on Hold"];
	
//	loansURL = [Test fileURLFor: @"Evergreen/20121223_mars_loans.html"];
//	holdsURL = [Test fileURLFor: @"Evergreen/20121223_mars_holds.html"];

	// Loans
	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1];
		if (loansCount == 0) [self parseLoans2];
	}
    
    // Holds
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHolds1];
		if (holdsCount == 0) [self parseHolds2];
	}

	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans format 1.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;
	HTMLElement *element2	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"acct_checked_main_header" intoElement: &element]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element2])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element2.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Loans format 2.
//
//		* New C/W Mars format.
//
// -----------------------------------------------------------------------------
- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"acct_checked_main_header" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds format 1.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;
	HTMLElement *element2	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"acct_holds_main_header" intoElement: &element]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element2])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element2.scanner tableWithColumns: columns];
		
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds format 2.
//
// -----------------------------------------------------------------------------
- (void) parseHolds2
{
	[Debug log: @"Parsing holds (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"acct_holds_main_header" intoElement: &element])
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
	[browser go: [myAccountCatalogueURL URLWithPath: @"/eg/opac/logout"]];
	[browser go: [myAccountCatalogueURL URLWithPath: @"/eg/opac/login"]];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

// -----------------------------------------------------------------------------
//
// The links on the account page look like:
//
//		Items Currently Checked out (0)		<a href="..">View All</a>
//		Items Currently on Hold (0)			<a href="..">View All</a>
//		Items ready for pickup (0)			<a href="..">View All</a>
//
//		* Each row is in a table so it is easy to parse out.  The raw HTML is:
//
//			<div class="acct_sum_row">
//				<table width="100%" cellspacing="0" cellpadding="0">
//					<tr>
//						<td>Items Currently Checked out (0)</td>
//						<td align="right"><a href="/eg/opac/myopac/circs">View All</a></td>
//					</tr>
//				</table>
//			</div>
//
// -----------------------------------------------------------------------------
- (URL *) linkForValue: (NSString *) value
{
	HTMLElement *element;
	
	if ([browser.scanner scanNextElementWithName: @"tr" regexValue: value intoElement: &element])
	{
		NSString *href = [element.scanner linkForLabel: @"View All"];
		if (href == nil) return nil;
	
		URL *url = [browser.currentURL URLWithPath: href];
		if (url == nil) return nil;
		
		return url;
	}
	
	return nil;
}

@end