#import "Aurora.h"

@implementation Aurora

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
    
	URL *loansURL		= [browser linkForLabel: @"Items on loan"];
	URL *holdsURL		= [browser linkForLabel: @"Reserves"];	
	
	// Loans
	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1];
	}
    
    // Holds
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHolds1];
	}
	
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
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"rTable_table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
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
    
	// Holds ready for pickup
	while ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"rTable_table" intoElement: &element])
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
#if 0
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary: self.authenticationAttributes];
	[attributes setObject: @"B" forKey: @"loginType"];
    
	return [browser linkToSubmitFormNamed: nil entries: attributes];
}
#endif

- (void) doPostBack: (URL *) url
{
	
}

@end
