// =============================================================================
//
// Calgary Public Library, AB, Canada
//
//		* Login form appears first.
//		* Custom loans parsing:
//			* The title cell needs custom parsing.
//		* NOT USED ANYMORE 2011-03-06
//
// =============================================================================

#import "CalgaryPublicLibrary.h"

@implementation CalgaryPublicLibrary

- (BOOL) update
{
	[browser go: catalogueURL];
	
	// Find the account page link
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug log: @"Can't find account page link"];
		return NO;
	}
	
	// Login
	if ([browser submitFormNamed: @"loginform" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

	// Override the title and author parsing
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleAndAuthorCell:",		@"Title/Author",
		nil
	];

//	[browser go: [Test fileURLFor: @"SIRSI/20100604_calgary_loans.html"]];
	[self parseLoans1];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// The title and author cell contains extra info we want to strip out.
//
//		* The main title/author info is inside a <label></label> tag.
//
// Example:
//
//		<label ...>
//			The life of Christopher Columbus&nbsp;&nbsp;
//			/ Saunders, Nicholas J.
//		</label>
//		<a href="...">Details</a><br />
//		<em>Juvenile Book</em> - 39065096978836 
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseTitleAndAuthorCell: (NSString *) string
{
	NSScanner *scanner = [NSScanner scannerWithString: string];
	HTMLElement *element;
	
	NSString *title		= nil;
	NSString *author	= nil;
	if ([scanner scanNextElementWithName: @"label" intoElement: &element])
	{
		[element.value splitStringOnLast: @"/" intoLeft: &title intoRight: &author];
		
		return [NSDictionary dictionaryWithObjectsAndKeys:
			[[title stringWithoutHTML] stringByTrimmingWhitespace],	@"title",
			[author stringWithoutHTML],								@"author",
			nil
		];
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: catalogueURL];

	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug log: @"Can't find account page link"];
		return NO;
	}
	
	return [browser linkToSubmitFormNamed: @"loginform" entries: self.authenticationAttributes];
}

@end