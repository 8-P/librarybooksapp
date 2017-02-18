// =============================================================================
//
// SIRSI 4
//
//		1. Get login prompt
//		2. Click on account page link
//		3. Loans and holds appear, there is NO checkouts link
//
// =============================================================================

#import "SIRSI4.h"

@implementation SIRSI4

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	// Find the account page link
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
//	[browser go: [Test fileURLFor: @"SIRSI/20110131_ocln_loans.html"]];

	[self parse];
	
	return YES;
}

- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end