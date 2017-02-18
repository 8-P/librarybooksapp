// =============================================================================
//
// SIRSI6
//
//		1. Click on account page link
//		2. Get login prompt
//
// =============================================================================

#import "SIRSI6.h"

@implementation SIRSI6

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20110528_cincinnati_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20121120_jacksonville_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20121120_jacksonville_holds.html"]];
	[self parse];
	
	return YES;
}

- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return nil;
	}
	
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end